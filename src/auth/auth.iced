auth = {}
auth._has_resource_role = (user, resource, role) ->
  return (resource + '|' + role) in user.roles
auth._has_team_role = (user, team, role) ->
  user_id = user.name
  return user_id in (team.roles[role]?.members or [])
auth._is_resource_admin = (user, resource) ->
  return auth._has_resource_role(user, resource, 'admin')
auth._is_team_admin = (user, team) ->
  return auth._has_team_role(user, team, 'admin')

auth.add_team_asset = (user, team, resource) ->
  return auth[resource]?.add_team_asset(user, team) or false

auth.remove_team_asset = (user, team, resource) ->
  return auth[resource]?.remove_team_asset(user, team) or false

auth.add_resource_role = (user, resource, role) ->
  if role in (auth.roles.resource[resource] or [])
    return auth[resource].add_resource_role(user, role)
  else
    return false

auth.remove_resource_role = (user, resource, role) ->
  if role in (auth.roles.resource[resource] or [])
    return auth[resource].remove_resource_role(user, role)
  else
    return false

auth.roles = 
  team: [
    'admin',
    'member',
  ],
  team_admin: [
    'admin',
  ],
  resource: {
    kratos: ['admin'],
    gh: ['user'],
  }
auth.resources = [
  'gh'
]

if window?
  window.kratos = {auth: auth}
else if exports?
  require('./kratos')(auth)
  require('./gh')(auth)
  module.exports = auth
