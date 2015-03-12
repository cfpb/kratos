couch_utils = require('../couch_utils')
utils = require('../utils')
request = require('request')
uuid = require('node-uuid')
utils = require('../utils')
_ = require('underscore')

resources = {
  gh: require('../workers/gh'),
}

teams = {}

teams.handle_create_team = (req, resp) ->
  now = +new Date()
  user = req.session.user
  org = 'org_' + req.params.org_id
  team_name = req.params.team_id
  team_id = 'team_' + team_name
  team_doc = {
    _id: team_id,
    name: team_name,
    rsrcs: {},
    roles: {},
    audit: [{u: user, dt: now, a: 't+', id: uuid.v4()}]
    enforce: []
  }
  org_db = req.couch.use(org)
  org_db.insert(team_doc).on('response', (couch_resp) ->
    # 409 conflict -> already created, so return the existing team
    if (couch_resp.statusCode < 400) or (couch_resp.statusCode == 409)
      teams.get_team(org_db, team_name).pipe(resp)
    else
      resp.status(couch_resp.statusCode)
      couch_resp.pipe(resp)
  )

teams.get_team = (org_db, team_id, callback) ->
  return couch_utils.rewrite(org_db, 'base', '/teams/team_' + team_id, callback)

teams.handle_get_team = (req, resp) ->
  org = 'org_' + req.params.org_id
  org_db = req.couch.use(org)
  teams.get_team(org_db, req.params.team_id).pipe(resp)

teams.get_teams = (org_db, callback) ->
  return couch_utils.rewrite(org_db, 'base', '/teams', callback)

teams.get_all_teams = (callback) ->
  await utils.get_org_dbs(defer(err, org_ids))
  if err then return callback(err)
  errs = []
  resps = []
  await
    for org_id, i in org_ids
      org_db = couch_utils.nano_admin.use(org_id)
      teams.get_teams(org_db, defer(errs[i], resps[i]))
  errs = _.compact(errs)
  if errs.length then return callback(errs)
  out = _.flatten(resps, true)
  return callback(null, out)

teams.getTeamRolesForUser = (user, callback) ->
  ###
  return an array of team/role hashes to which the user belongs:
    [{team: <obj>, role: <str>}]
  ###
  await teams.get_all_teams(defer(err, all_teams))
  if err then return callback(err)

  team_roles = []

  for team in all_teams
    for role, role_data of team.roles
      if user.name in (role_data.members or [])
        team_roles.push({team: team, role: role})

  return callback(null, team_roles)

teams.handle_get_teams = (req, resp) ->
  org = 'org_' + req.params.org_id
  org_db = req.couch.use(org)
  teams.get_teams(org_db).pipe(resp)

teams.handle_add_remove_member_asset = (action_type) ->
  (req, resp) ->
    org = 'org_' + req.params.org_id
    team = 'team_' + req.params.team_id

    db = req.couch.use(org)
    action = {
      action: action_type
      key: req.params.key
      value: req.params.value
      uuid: uuid.v4()
    }
    db.atomic('base', 'do_action', team, action).pipe(resp)

teams.handle_add_asset = (req, resp) ->
  org = 'org_' + req.params.org_id
  team_id = 'team_' + req.params.team_id
  await team_req = req.couch.use(org).get(team_id, defer(err, team))
  if err
    return team_req.pipe(resp)

  new_val = req.body.new
  if not new_val
    return resp.status(400).end(JSON.stringify({'error': 'bad_request ', 'msg': '"new" value must be present'}))

  handler = resources[req.params.key]?.add_asset
  if not handler
    return resp.status(404).send(JSON.stringify({error: "not_found", msg: 'Resource, ' + req.params.key + ', not found.'}))

  await handler(new_val, team).nodeify(defer(err, new_asset))
  if err
    console.log(err)
    return resp.status(500).send(JSON.stringify({error: "internal_error", msg: 'Something went wrong'}))
  if not new_asset?  # no change
    return resp.send(JSON.stringify(team))

  new_asset.id = uuid.v4()
  req.params.value = new_asset
  console.log(req.body, req.params.value)
  return teams.handle_add_remove_member_asset('a+')(req, resp)

utils.denodeify_api(teams)
module.exports = teams
