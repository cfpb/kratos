_ = require('underscore')
users = require('../api/users')
auth = require('../validation').auth
git = require('./gh_client')
Promise = require('pantheon-helpers').promise

gh = {}

emptyResolve = () ->
  Promise.resolve()

get_gh_username = (user) ->
  gh_username = user.rsrcs.gh?.username
  if gh_username
    return Promise.resolve(gh_username)
  else
    return Promise.reject({user: user, err: 'no github username'})

get_gh_role = (user, role) ->
  is_contractor = user.data?.contractor
  if is_contractor
    return 'push'
  else
    return 'admin'

get_gh_team_id = (team, user, role) ->
  # given a user and a role, return the gh team id
  # corresponding to the role.
  gh_teams = team.rsrcs.gh.data
  gh_role = get_gh_role(user, role)
  gh_team_id = gh_teams[gh_role]
  return gh_team_id

has_gh_team_membership_through_other_role = (team, user, role) ->
  gh_team_id = get_gh_team_id(team, user, role)
  for other_role, role_data of team.roles
    if (other_role != role and 
        user.name in role_data.members and
        get_gh_team_id(team, user, other_role) == gh_team_id)
      return true
  return false

gh.add_user = (user, role, team) ->
  if not auth._has_resource_role(user, 'gh', 'user')
    return Promise.resolve()
  get_gh_username(user).then((gh_username) ->
    gh_team_id = get_gh_team_id(team, user, role)
    git.team.user.add(gh_team_id, gh_username)
  )

gh.remove_user = (user, role, team) ->
  if has_gh_team_membership_through_other_role(team, user, role)
    return Promise.resolve()

  get_gh_username(user).then((gh_username) ->
    gh_team_id = get_gh_team_id(team, user, role)
    git.team.user.remove(gh_team_id, gh_username)
  )

handle_add_user = (event, team) ->
  user_id = event.user
  role = event.role

  users.get_user(user_id, 'promise').then((user) ->
    gh.add_user(user, role, team)
  ).then(emptyResolve)

handle_remove_user = (event, team) ->
  user_id = event.user
  role = event.role

  users.get_user(user_id, 'promise').then((user) ->
    gh.remove_user(user, role, team)
  ).then(emptyResolve)

gh.remove_repo = (repo_full_name, team) ->
  team_ids = _.values(team.rsrcs.gh?.data or {})
  git.teams.repo.remove(team_ids, repo_full_name)

handle_remove_repo = (event, team) ->
  repo_full_name = event.asset.full_name
  return gh.remove_repo(repo_full_name, team).then(emptyResolve)

gh.add_repo = (repo_full_name, team) ->
  team_ids = _.values(team.rsrcs.gh?.data or {})
  git.teams.repo.add(team_ids, repo_full_name)

handle_add_repo = (event, team) ->
  repo_full_name = event.asset.full_name
  return gh.add_repo(repo_full_name, team).then(emptyResolve)


gh.create_team = (team_name) ->
  opts = [
    { name: team_name, permission: 'admin'},
    { name: team_name, permission: 'push'},
  ]
  git.teams.create(opts).then((teams) ->
    out = {admin: teams[0].id, push: teams[1].id}
    Promise.resolve(out)
  )

handle_create_team = (event, team) ->
  return gh.create_team(team.name).then((data) ->
    Promise.resolve({data: data, path: ['rsrcs', 'gh', 'data']})
  )

get_gh_team_ids = (user) ->
  teams_api = require('../api/teams')
  teams_api.get_all_team_roles_for_user(user.name).then((team_roles) ->
    gh_team_ids = team_roles.map((team_role) ->
      return get_gh_team_id(team_role.team, user, team_role.role)
    )
    Promise.resolve(gh_team_ids)
  )

handle_add_gh_rsrc_role = (event, user) ->
  get_gh_username(user).then((gh_username) ->
    get_gh_team_ids(user).then((gh_team_ids) ->
      git.teams.user.add(gh_team_ids, gh_username)
    )
  ).then(emptyResolve)

handle_remove_gh_rsrc_role = (event, user) ->
  get_gh_username(user).then((gh_username) ->
    get_gh_team_ids(user).then((gh_team_ids) ->
      git.teams.user.remove(gh_team_ids, gh_username)
    )
  ).then(emptyResolve)

handle_deactivate_user = (event, user) ->
  get_gh_username(user).then(
    (gh_username) ->
      git.user.delete(gh_username)
    () ->
      Promise.resolve()
  ).then(emptyResolve)

get_or_create_asset = (asset_data, team, actor) ->
  repo_name = asset_data.new
  # first look through and make sure the repo hasn't already been added
  existing_repo = _.findWhere(team.rsrcs.gh?.assets, {'name': repo_name})
  if existing_repo
    return Promise.resolve()

  git.repo.createPush({name: repo_name}).then((new_repo_data) ->
    new_repo = {
      gh_id: new_repo_data.id,
      name: new_repo_data.name,
      full_name: new_repo_data.full_name,
    }
    Promise.resolve(new_repo)
  )

module.exports =
  handlers:
    team:
      'u+': handle_add_user
      'u-': handle_remove_user
      't+': handle_create_team
      't-': null
      self:
        'a+': handle_add_repo
        'a-': handle_remove_repo
      other:
        'a+': null
        'a-': null
    user:
      self:
        'r+': handle_add_gh_rsrc_role
        'r-': handle_remove_gh_rsrc_role
      other:
        'r+': null
        'r-': null
      'u+': null
      'u-': handle_deactivate_user
  getOrCreateAsset: get_or_create_asset
  testing: gh
