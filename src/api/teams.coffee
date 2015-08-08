couchUtils = require('../couch_utils')
utils = require('../utils')
_ = require('underscore')
Promise = require('pantheon-helpers').promise
validation = require('../validation')
conf = require('../config')
{prepDoc} = require('../shared')
t = {}
t.doAction = require('../doAction')

getWorker = (resource) ->
  api = require('./index')
  workers = {}

  utils.getPlugins().forEach((plugin) ->
    workers[plugin.name] = plugin.worker
  )

  worker = workers[resource]?(api, validation, couchUtils)
  return worker or {}

getActorNameFromDB = (db) ->
  return db.config.url.split(':')[1].slice(2)

processReq = (req) ->
  params = req.params
  orgDbName = 'org_' + params.orgId
  teamName = params.teamId
  if teamName && teamName.indexOf('team_') == 0
    teamName = teamName.slice(5)
  db = req.couch.use(orgDbName)
  actorName = req.session.user
  return [orgDbName, db, actorName, teamName, params]

teams = {}

# t.doAction(dbName, actor, docId, actionHash)

teams.createTeam = (dbName, actorName, teamName) ->
  t.doAction(dbName, actorName, null, {
    a: 't+',
    name: teamName,
  })

teams.handleCreateTeam = (req, resp) ->
  [orgDbName, db, actorName, teamName, params] = processReq(req)
  promise = teams.createTeam(orgDbName, actorName, teamName).catch((err) ->
    # 409 conflict -> already created, so return the existing team
    if err.statusCode == 409
      return teams.getTeam(db, teamName)
    else
      Promise.reject(err)
  )
  Promise.sendHttp(promise, resp)

teams.getTeam = (orgDb, teamName) ->
  # returns promise
  teamId = utils.formatId(teamName, 'team')
  actorName = getActorNameFromDB(orgDb)
  actorPromise = utils.getActor(couchUtils, actorName)
  teamPromise = orgDb.get(teamId, 'promise')
  Promise.all([teamPromise, actorPromise]).then(([team, actor]) ->
    preppedDoc = prepDoc(team, actor)
    Promise.resolve(preppedDoc)
  )

teams.handleGetTeam = (req, resp) ->
  [orgDbName, db, actorName, teamName, params] = processReq(req)
  promise = teams.getTeam(db, teamName)
  Promise.sendHttp(promise, resp)

teams.getTeams = (orgDb) ->
  actorName = getActorNameFromDB(orgDb)
  actorPromise = utils.getActor(couchUtils, actorName)
  teamsPromise = couchUtils.rewrite(orgDb, 'base', '/teams', 'promise')
  Promise.all([teamsPromise, actorPromise]).then(([teams, actor]) -> 
    preppedDocs = teams.map((team) -> 
      return prepDoc(team, actor)
    )
    Promise.resolve(preppedDocs)
  )


teams.handleGetTeams = (req, resp) ->
  [orgDbName, db, actorName, teamName, params] = processReq(req)
  promise = teams.getTeams(db)
  Promise.sendHttp(promise, resp)

teams.getAllTeams = () ->
  # returns a promise only
  utils.getOrgDbs().then((orgIds) ->
    allTeams = orgIds.map((orgId) ->
      orgDb = couchUtils.nano_system_user.use(orgId)
      teams.getTeams(orgDb)
    )
    Promise.all(allTeams)
  ).then((allTeams) ->
    allTeams = _.flatten(allTeams, true)
    Promise.resolve(allTeams)
  )

teams.getTeamRolesForUser = (db, userName, callback) ->
  ###
  return an array of team/role hashes to which the user belongs:
    [{team: <obj>, role: <str>}]
  ###
  db.viewWithList('base', 'by_role', 'get_team_roles', {include_docs: true, startkey: [userName], endkey: [userName, {}]}, callback)

teams.getAllTeamRolesForUser = (userName) ->
  # returns a promise only
  utils.getOrgDbs('promise').then((orgIds) ->
    teamRoles = orgIds.map((orgId) ->
      db = couchUtils.nano_system_user.use(orgId)
      teams.getTeamRolesForUser(db, userName, 'promise')
    )
    Promise.all(teamRoles)
  ).then((teamRoles) ->
    teamRoles = _.flatten(teamRoles, true)
    Promise.resolve(teamRoles)
  )

teams.addMember = (dbName, actorName, teamName, role, userId) ->
  teamId = 'team_' + teamName
  t.doAction(dbName, actorName, teamId, {
    a: 'u+',
    role: role,
    user: userId,
  })

teams.removeMember = (dbName, actorName, teamName, role, userId) ->
  teamId = 'team_' + teamName
  t.doAction(dbName, actorName, teamId, {
    a: 'u-',
    role: role,
    user: userId,
  })

teams.addAsset = (dbName, actorName, teamName, resource, assetData) ->
  # only returns a promise; no streaming/callback support
  db = couchUtils.nano_user(actorName).use(dbName)

  Promise.all([
    teams.getTeam(db, teamName, 'promise'),
    utils.getActor(couchUtils, actorName),
  ]).then(([team, actor]) ->
    isAuthorized = validation.auth.add_team_asset(actor, team, resource)
    if not isAuthorized
      return Promise.reject({statusCode: 401, error: 'unauthorized', msg: 'You are not authorized to add this asset'})

    handler = getWorker(resource).getOrCreateAsset
    if not handler
      return Promise.reject({statusCode: 404, error: "not_found", msg: 'Resource, ' + resource + ', not found.'})

    handler(assetData, team, actor).then((newAsset) ->
      if not newAsset?  # no change
        return Promise.resolve(team)
      else
        return t.doAction(dbName, actorName, team._id, {
          a: 'a+',
          resource: resource,
          asset: newAsset,
        })
    )
  ).catch((err) ->
    # TODO Add better logging here
    console.error('add_asset_error', resource, assetData, err)
    Promise.reject(err)
  )

teams.removeAsset = (dbName, actorName, teamName, resource, assetId) ->
  teamId = 'team_' + teamName
  t.doAction(dbName, actorName, teamId, {
    a: 'a-',
    resource: resource,
    asset: {id: assetId},
  })

teams.handleAddMember = (req, resp) ->
  [orgDbName, db, actorName, teamName, params] = processReq(req)
  promise = teams.addMember(orgDbName, actorName, teamName, params.role, params.userId)
  Promise.sendHttp(promise, resp)

teams.handleRemoveMember = (req, resp) ->
  [orgDbName, db, actorName, teamName, params] = processReq(req)
  promise = teams.removeMember(orgDbName, actorName, teamName, params.role, params.userId)
  Promise.sendHttp(promise, resp)

teams.handleAddAsset = (req, resp) ->
  [orgDbName, db, actorName, teamName, params] = processReq(req)
  promise = teams.addAsset(orgDbName, actorName, teamName, params.resource, req.body)
  Promise.sendHttp(promise, resp)

teams.handleRemoveAsset = (req, resp) ->
  [orgDbName, db, actorName, teamName, params] = processReq(req)
  promise = teams.removeAsset(orgDbName, actorName, teamName, params.resource, params.assetId)
  Promise.sendHttp(promise, resp)

teams.getTeamDetails = (db, teamName, actorName) ->
  Promise.all([
    teams.getTeam(db, teamName, 'promise'),
    utils.getActor(couchUtils, actorName),
  ]).then(([team, actor]) ->

    rsrcsPromises = {}
    _.forEach(team.rsrcs, (resourceData, resourceName) -> 
      detailHandler = getWorker(resourceName).getTeamAssetDetails
      if detailHandler
        assets = resourceData.assets
        rsrcsPromises[resourceName] = detailHandler(assets, team, actor).then((assetDetails) ->
          zippedAssets = _.zip(assets, assetDetails)
          _.each(zippedAssets, ([assetData, assetDetails]) ->
            assetData.details = assetDetails
          )
          return Promise.resolve(assets)
        )
      else
        rsrcsPromises[resourceName] = Promise.resolve([])
    )

    Promise.hashAll(rsrcsPromises).then((rsrcs) ->
      Promise.resolve({rsrcs: rsrcs})
    )
  )

teams.handleGetTeamDetails = (req, resp) ->
  [orgDbName, db, actorName, teamName, params] = processReq(req)
  promise = teams.getTeamDetails(db, teamName, req.session.user)
  Promise.sendHttp(promise, resp)

teams.testing = t
module.exports = teams
