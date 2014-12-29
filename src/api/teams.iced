couch_utils = require('../couch_utils')
request = require('request')
uuid = require('node-uuid')

teams = {}

teams.create_team = (req, resp) ->
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
    if couch_resp.statusCode < 400
      org_db.get(team_id).pipe(resp)
    else
      couch_resp.pipe(resp)
  )

teams._get_team = (org_db, team_id, callback) ->
  return couch_utils.rewrite(org_db, 'base', '/teams/team_' + team_id, callback)

teams.get_team = (req, resp) ->
  org = 'org_' + req.params.org_id
  org_db = req.couch.use(org)
  teams._get_team(org_db, req.params.team_id).pipe(resp)

teams._get_teams = (org_db, callback) ->
  return couch_utils.rewrite(org_db, 'base', '/teams', callback)

teams.get_teams = (req, resp) ->
  org = 'org_' + req.params.org_id
  org_db = req.couch.use(org)
  teams._get_teams(org_db).pipe(resp)

teams.add_remove_member_asset = (action_type) ->
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

teams.add_asset = (req, resp) ->
  new_val = req.body.new
  if not new_val
    return resp.status(400).end(JSON.stringify({'status': 'error', 'msg': 'new value must be present'}))
  req.params.value = {id: uuid.v4(), 'new': new_val}
  console.log(req.body, req.params.value)
  return teams.add_remove_member_asset('a+')(req, resp)

module.exports = teams
