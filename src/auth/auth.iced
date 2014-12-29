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

auth.roles = 
  team: [
    'admin',
    'member',
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
