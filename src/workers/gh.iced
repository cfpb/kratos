_ = require('underscore')
request = require('request')
couch_utils = require('../couch_utils')
users = require('../api/users')
teams = require('../api/teams')
utils = require('../utils')
{exec} = require 'child_process'
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

get_authenticated_repo_url = (repo_url) ->
  repo_parts = repo_url.split('//')
  repo_parts[1] = gh_conf.ADMIN_CREDENTIALS.pass + ':x-oauth-basic@' + repo_parts[1]
  authed_repo_url = repo_parts.join('//')
  return authed_repo_url

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


add_remove_user = (user, role, action_name, team, callback) ->
  console.log('add_remove_user', user.username, role, action_name, team.name)
  # we don't add them as a gh user if they aren't a gh|user
  # but we will happily remove them as a gh user if they aren't a gh|user
  if action_name == 'a+' and 'gh|user' not in user.roles
    return callback()
  console.log('past first hurdle')
  gh_teams = team.rsrcs.gh.data

  gh_username = user.rsrcs.gh?.username
  if not gh_username
    return callback({user: user, err: 'no github username'})

  gh_team_type = get_gh_team_type(user, role)
  await get_gh_team_id(gh_teams, gh_team_type, defer(err, gh_team_id))
  return callback(err) if err
  console.log('gh_team_id', gh_team_id)

  action = if action_name == 'u+' then git_client.put else git_client.del
  url = git_url + '/teams/' + gh_team_id + '/memberships/' + gh_username
  await action(url, utils.process_resp(defer(err, resp, body)))
  console.log(err, body)
  return callback(err)


add_user = (user, role, team, callback) ->
  return add_remove_user(user, role, 'a+', team, callback)


remove_user = (user, role, team, callback) ->
  return add_remove_user(user, role, 'a-', team, callback)


handle_add_remove_user = (event, team, callback) ->
  action_name = event.a
  user_id = event.v
  role = event.k

  await users.get_user(user_id, defer(err, user))
  return callback(err) if err

  return add_remove_user(user, role, action_name, team, callback)


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
    template_dir = './template_repo/'
    await exec('git init', {cwd: template_dir}, defer(err, stdout, stderr))
    if err then return callback(err)

    await exec('git pull "' + gh_conf.TEMPLATE_REPO + '"', {cwd: template_dir}, defer(err, stdout, stderr))
    if err then return callback(err)

    push_repo_url = get_authenticated_repo_url(body.clone_url)
    await exec('git push "' + push_repo_url + '" master', {cwd: template_dir}, defer(err, stdout, stderr))
    if err then return callback(err)

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
    await
      for team_name, team_id of (team.rsrcs.gh?.data or {})
        url = git_url + '/teams/' + team_id + '/repos/' + new_repo.full_name
        git_client.put(url, utils.process_resp(defer(errs[team_id])))
    errs = utils.compact_hash(errs)
    if errs
      return callback(errs)
    else
      return callback(null, new_repo)


remove_repo = (repo_full_name, team, callback) ->
  errs = {}
  await
    for team_name, team_id of (team.rsrcs.gh?.data or {})
      url = git_url + '/teams/' + team_id + '/repos/' + repo_full_name
      git_client.del(url, utils.process_resp(defer(errs[team_id])))
  errs = utils.compact_hash(errs)
  return callback(errs)


handle_remove_repo_event = (event, team, callback) ->
  repo_full_name = event.r.full_name
  return remove_repo(repo_full_name, team, callback)

output = {}
create_team = (team_name, callback) ->

  errs = {}
  bods = {}
  url = git_url + '/organizations/' + gh_conf.ORG_ID + '/teams'
  await
    for perm, gh_perm of {write: 'push', admin: 'admin'}
      gh_team = {
        "name": team_name + ' team ' + perm
        "permission": gh_perm,
        "repo_names": []
      }
      git_client.post({url: url, json:gh_team}, utils.process_resp(defer(errs[perm], resp, bods[perm])))
  out_errs = {}
  out = {}
  output.bods = bods
  output.errs = errs
  for perm, err of errs
    bod = bods[perm]
    if err?.code == 422 # the team already exists
      continue
    if err
      out_errs[perm] = err
      continue
    out[perm] = bod.id

  if _.isEmpty(out_errs)
    return callback(null, out)
  else
    return callback(out_errs)

handle_create_team = (event, team, callback) ->
  team_name = team.name
  return create_team(team_name, callback)

handle_add_remove_gh_rsrc_role = (event, user, callback) ->
  await teams.get_all_teams(defer(err, all_teams))
  if err then return callback(err)

  action_name = {'r+': 'u+', 'r-': 'u-'}[event.a]

  team_roles = []

  for team in all_teams
    for role, role_data of team.roles
      if role_data.members and user.name in role_data.members
        team_roles.push({team: team, role: role})

  errs = []
  resps = []
  await
    for team_role, i in team_roles
      add_remove_user(user, team_role.role, action_name, team_role.team, defer(errs[i], resps[i]))
  errs = _.compact(errs)
  if errs.length then return callback(errs)

  # merge all responses
  out = {}
  for resp in resps
    if resp
      _.extend(out, resp)
  return callback(null, out)

module.exports =
  handlers:
    team:
      'u+': handle_add_remove_user
      'u-': handle_add_remove_user
      't+': handle_create_team
      't-': null
      self:
        'a+': null
        'a-': handle_remove_repo_event
      other:
        'a+': null
        'a-': null
    user:
      self:
        'r+': handle_add_remove_gh_rsrc_role
        'r-': handle_add_remove_gh_rsrc_role
      other:
        'r+': null
        'r-': null
      'u+': null
      'u-': null
  add_asset: add_asset
  handle_user_event: (event, doc, callback) ->
    # TODO

