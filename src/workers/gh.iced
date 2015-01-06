request = require('request')
couch_utils = require('../couch_utils')
users = require('../api/users')
conf = require('../config')
gh_conf = conf.RESOURCES.GH

git_client = request.defaults({
  auth: gh_conf.ADMIN_CREDENTIALS,
  headers: {
    'User-Agent': 'cfpb-kratos'    
  }
})
git_url = 'https://api.github.com'
user_db = couch_utils.nano_admin.use('_users')

get_gh_team_type = (user, role) ->
  is_contractor = user.data?.contractor
  if is_contractor
    return 'write'
  else
    return 'admin'

get_gh_team_id = (gh_teams, gh_team_type, callback) ->
  team_id = gh_teams[gh_team_type]
  # TODO: create team if it doesn't exist
  return callback(null, team_id)

add_remove_user = (action_name, user, role, gh_teams, callback) ->
  if 'gh|user' not in user.roles
    return callback()
  username = user.rsrcs.gh?.login
  if not username
    return callback({user: user, err: 'no username'})

  gh_team_type = get_gh_team_type(user, role)
  await get_gh_team_id(gh_teams, gh_team_type, defer(err, team_id))
  return callback(err) if err

  action = if action_name == 'u+' then git_client.put else git_client.del
  url = git_url + '/teams/' + team_id + '/memberships/' + username
  await action(url, defer(err, resp))
  if resp.statusCode >= 400
    return callback({msg: resp.body, code: resp.statusCode})
  return callback(err)


module.exports =
  handle_team_event: (event, team, callback) ->
    gh_teams = team.rsrcs.gh.data
    if event.a[0] == 'u'
      await users._get_user(event.v, defer(err, user))
      return callback(err) if err
      return add_remove_user(event.a, user, event.k, gh_teams, callback)
    else
      console.log('SKIPPING')
      return callback()
    # TODO handle adding/removing assets, teams

  handle_user_event: (event, doc, callback) ->
    # TODO

  add_resource: (data, callback) ->

  update_resource: (data, doc, callback) ->