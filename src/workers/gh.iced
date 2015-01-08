_ = require('underscore')
request = require('request')
couch_utils = require('../couch_utils')
users = require('../api/users')
conf = require('../config')
gh_conf = conf.RESOURCES.GH

git_client = request.defaults({
  auth: gh_conf.ADMIN_CREDENTIALS,
  headers: {
    'User-Agent': 'cfpb-kratos',
  },
  json: true,
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

add_remove_user = (event, team, callback) ->
  action_name = event.a
  user_id = event.v
  role = event.k
  gh_teams = team.rsrcs.gh.data

  await users._get_user(user_id, defer(err, user))
  return callback(err) if err

  if 'gh|user' not in user.roles
    return callback()

  username = user.rsrcs.gh?.username
  if not username
    return callback({user: user, err: 'no username'})

  gh_team_type = get_gh_team_type(user, role)
  await get_gh_team_id(gh_teams, gh_team_type, defer(err, team_id))
  return callback(err) if err

  action = if action_name == 'u+' then git_client.put else git_client.del
  url = git_url + '/teams/' + team_id + '/memberships/' + username
  await action(url, defer(err, resp, body))
  if resp?.statusCode >= 400
    return callback({msg: body, code: resp.statusCode})
  return callback(err)

_get_or_create_repo = (repo_name, callback) ->
  url = git_url + '/organizations/' + gh_conf.ORG_ID + '/repos'
  await git_client.post({
    url: url,
    json: { 
      name: repo_name,
      description: "",
      homepage: "https://github.com",
      private: false,
      has_issues: true,
      has_wiki: true,
      has_downloads: true
    }
  }, defer(err, resp, body))
  if err
    return callback(err)
  else if resp.statusCode == 422 # the repo already exists
    url = git_url + '/repos/' + gh_conf.ORG_NAME + '/' + repo_name
    await git_client.get(url, defer(err, resp, body))
    if err
      return callback(err)
    else if resp.statusCode >= 400
      return callback({msg: body, code: resp.statusCode})
    else
      return callback(null, body)
  else if resp.statusCode >= 400
    return callback({msg: body, code: resp.statusCode})
  else
    # TODO add template
    return callback(null, body)

add_asset = (repo_name, team, callback) ->
  # first look through and make sure the repo hasn't already been added
  existing_repo = _.findWhere(team.rsrcs.gh?.assets, {'name': repo_name})
  if existing_repo
    return callback(null)
  await _get_or_create_repo(repo_name, defer(err, new_repo_data))
  if err
    return callback(err)
  else
    new_repo = {
      gh_id: new_repo_data.id,
      name: new_repo_data.name,
      full_name: new_repo_data.full_name,
    }
    errs = {}
    resps = {}
    bods = {}
    await
      for team_name, team_id of (team.rsrcs.gh?.data or {})
        url = git_url + '/teams/' + team_id + '/repos/' + new_repo.full_name
        git_client.put(url, defer(errs[team_id], resps[team_id], bods[team_id]))

    errors = {}
    for k in _.keys(errs)
      if errs[k] or resps[k].statusCode >= 400
        errors[k] = {err: errs[k], msg: bods[k], code: resps[k].statusCode}
    if _.isEmpty(errors)
      return callback(null, new_repo)
    else
      return callback(errors)

remove_repo = (repo_full_name, team, callback) ->
  errs = {}
  resps = {}
  bods = {}
  await
    for team_name, team_id of (team.rsrcs.gh?.data or {})
      url = git_url + '/teams/' + team_id + '/repos/' + repo_full_name
      git_client.del(url, defer(errs[team_id], resps[team_id], bods[team_id]))

  errors = {}
  for k in _.keys(errs)
    if errs[k] or resps[k].statusCode >= 400
      errors[k] = {err: errs[k], msg: bods[k], code: resps[k].statusCode}
  if _.isEmpty(errors)
    return callback()
  else
    return callback(errors)

handle_remove_repo_event = (event, team, callback) ->

create_team = (team_name, team) ->

handle_create_team = (event, team, callback) ->

module.exports =
  handlers:
    team:
      'u+': add_remove_user
      'u-': add_remove_user
      't+': null
      't-': null
      self:
        'a+': null
        'a-': handle_remove_repo_event
      other:
        'a+': null
        'a-': null
    user:
      'r+': null
      'r-': null
      'u+': null
      'u-': null
  add_asset: add_asset
  remove_repo: remove_repo
  handle_user_event: (event, doc, callback) ->
    # TODO

