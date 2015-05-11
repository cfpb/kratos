couch_utils = require('../couch_utils')
utils = require('../utils')
request = require('request')
uuid = require('node-uuid')
_ = require('underscore')
Promise = require('pantheon-helpers').promise
doAction = require('pantheon-helpers').doAction
validation = require('../validation')
conf = require('../config')

resources = {
  gh: require('../workers/gh'),
  moirai: require('../workers/moirai'),
}

process_req = (req) ->
  params = req.params
  org_db_name = 'org_' + params.org_id
  team_name = params.team_id
  db = req.couch.use(org_db_name)
  return [db, team_name, params]

teams = {}

teams.create_team = (db, team_name, callback) ->
  doAction(db, 'base', null, {
    a: 't+',
    name: team_name,
  }, callback)

teams.handle_create_team = (req, resp) ->
  [db, team_name, params] = process_req(req)
  teams.create_team(db, team_name).on('response', (couch_resp) ->
    # 409 conflict -> already created, so return the existing team
    if couch_resp.statusCode == 409
      teams.get_team(db, team_name).pipe(resp)
    else
      resp.status(couch_resp.statusCode)
      couch_resp.pipe(resp)
  )

teams.get_team = (org_db, team_name, callback) ->
  return couch_utils.rewrite(org_db, 'base', '/teams/team_' + team_name, callback)

teams.handle_get_team = (req, resp) ->
  [db, team_name, params] = process_req(req)
  teams.get_team(db, team_name).pipe(resp)

teams.get_teams = (org_db, callback) ->
  return couch_utils.rewrite(org_db, 'base', '/teams', callback)

teams.handle_get_teams = (req, resp) ->
  [db] = process_req(req)
  teams.get_teams(db).pipe(resp)

teams.get_all_teams = () ->
  # returns a promise only
  utils.get_org_dbs().then((org_ids) ->
    all_teams = org_ids.map((org_id) ->
      org_db = couch_utils.nano_system_user.use(org_id)
      teams.get_teams(org_db, 'promise')
    )
    Promise.all(all_teams)
  ).then((all_teams) ->
    all_teams = _.flatten(all_teams, true)
    Promise.resolve(all_teams)
  )

teams.get_team_roles_for_user = (db, user_name, callback) ->
  ###
  return an array of team/role hashes to which the user belongs:
    [{team: <obj>, role: <str>}]
  ###
  db.viewWithList('base', 'by_role', 'get_team_roles', {include_docs: true, startkey: [user_name], endkey: [user_name, {}]}, callback)

teams.get_all_team_roles_for_user = (user_name) ->
  # returns a promise only
  utils.get_org_dbs('promise').then((org_ids) ->
    team_roles = org_ids.map((org_id) ->
      db = couch_utils.nano_system_user.use(org_id)
      teams.get_team_roles_for_user(db, user_name, 'promise')
    )
    Promise.all(team_roles)
  ).then((team_roles) ->
    team_roles = _.flatten(team_roles, true)
    Promise.resolve(team_roles)
  )

teams.add_member = (db, team_name, role, user_id, callback) ->
  team_id = 'team_' + team_name
  doAction(db, 'base', team_id, {
    a: 'u+',
    role: role,
    user: user_id,
  }, callback)

teams.remove_member = (db, team_name, role, user_id, callback) ->
  team_id = 'team_' + team_name
  doAction(db, 'base', team_id, {
    a: 'u-',
    role: role,
    user: user_id,
  }, callback)

teams.add_asset = (db, actor_name, team_name, resource, asset_data) ->
  # only returns a promise; no streaming/callback support
  users = require('./users')

  Promise.all([
    teams.get_team(db, team_name, 'promise'),
    users.get_user(actor_name, 'promise'),
  ]).then(([team, actor]) ->
    isAuthorized = validation.auth.add_team_asset(actor, team, resource)
    if not isAuthorized
      return Promise.reject({code: 401, error: 'unauthorized', msg: 'You are not authorized to add this asset'})

    handler = resources[resource]?.getOrCreateAsset
    if not handler
      return Promise.reject({code: 404, error: "not_found", msg: 'Resource, ' + resource + ', not found.'})

    handler(asset_data, team, actor).then((new_asset) ->
      if not new_asset?  # no change
        return Promise.resolve(team)
      else
        return doAction(db, 'base', team._id, {
          a: 'a+',
          resource: resource,
          asset: new_asset,
        }, 'promise')
    )
  ).catch((err) ->
    console.error('add_asset_error', resource, asset_data, err)
    Promise.reject(err)
  )

teams.remove_asset = (db, team_name, resource, asset_id, callback) ->
  team_id = 'team_' + team_name
  doAction(db, 'base', team_id, {
    a: 'a-',
    resource: resource,
    asset: {id: asset_id},
  }, callback)

teams.handle_add_member = (req, resp) ->
  [db, team_name, params] = process_req(req)
  teams.add_member(db, team_name, params.role, params.user_id).pipe(resp)

teams.handle_remove_member = (req, resp) ->
  [db, team_name, params] = process_req(req)
  teams.remove_member(db, team_name, params.role, params.user_id).pipe(resp)

teams.handle_add_asset = (req, resp) ->
  [db, team_name, params] = process_req(req)
  teams.add_asset(db, req.session.user, team_name, params.resource, req.body).then((team) ->
    resp.send(JSON.stringify(team))
  ).catch((err) ->
    if err.code
      resp.status(err.code).send(JSON.stringify(_.pick(err, 'error', 'msg')))
    else
      resp.status(500).send(JSON.stringify({error: 'server error', msg: 'something went wrong. please try again.'}))
  )

teams.handle_remove_asset = (req, resp) ->
  [db, team_name, params] = process_req(req)
  teams.remove_asset(db, team_name, params.resource, params.asset_id).pipe(resp)

teams.get_team_details = (db, team_name, actor_name) ->
  users = require('./users')
  Promise.all([
    teams.get_team(db, team_name, 'promise'),
    users.get_user(actor_name, 'promise'),
  ]).then(([team, actor]) ->

    rsrcs_promises = {}
    _.forEach(team.rsrcs, (resource_data, resource_name) -> 
      detailHandler = resources[resource_name].getTeamAssetDetails
      if detailHandler
        assets = resource_data.assets
        rsrcs_promises[resource_name] = detailHandler(assets, team, actor).then((asset_details) ->
          zipped_assets = _.zip(assets, asset_details)
          _.each(zipped_assets, ([asset_data, asset_details]) ->
            asset_data.details = asset_details
          )
          return Promise.resolve(assets)
        )
      else
        rsrcs_promises[resource_name] = Promise.resolve([])
    )

    Promise.hashAll(rsrcs_promises).then((rsrcs) ->
      Promise.resolve({rsrcs: rsrcs})
    )
  )

teams.handle_get_team_details = (req, resp) ->
  [db, team_name, params] = process_req(req)
  teams.get_team_details(db, team_name, req.session.user).then(
    (team_details) ->
      resp.send(JSON.stringify(team_details))
    (err) ->
      console.log('handle_get_team_details error', team_name, err)
      if err.statusCode
        return resp.status(err.statusCode).send(JSON.stringify(_.pick(err, 'error', 'reason')))
      else
        return resp.status(500).send(JSON.stringify({error: 'server error', msg: 'something went wrong. please try again.'}))
  )

teams.handle_proxy_action = (req, resp) ->
  [db, team_name, params] = process_req(req)  users = require('./users')

  Promise.all([
    teams.get_team(db, team_name, 'promise'),
    users.get_user(req.session.user, 'promise'),
  ]).then(([team, actor]) ->
    resource = params.resource
    assets = team.rsrcs?[resource]?.assets
    asset = _.findWhere(assets, {id: params.asset_id})
    if not asset
      resp.status(404).send({error: "not_found", msg: 'Asset, ' + resource + ' ' + params.asset_id + ', not found.'})
    try
      validation.proxy_asset_action(actor, team, resource, asset, params.path, req.method, req.body, req)
    catch e
      status = {unauthorized: 401,  invalid: 403 }[e.state]
      return resp.status(status).send(JSON.stringify({err: e.state, msg: e.err}))
    return resources[resource].doAssetAction(actor, team, resource, asset, params.path, req.method, req.body, req, resp)
  )


module.exports = teams
