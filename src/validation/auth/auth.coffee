auth = (validation) ->
  validation.auth = auth = {}

  auth.is_active_user = (user) ->
    return 'kratos|disabled' not in (user.roles or [])

  auth._has_resource_role = (user, resource, role) ->
    return auth.is_active_user(user) and (resource + '|' + role) in (user.roles or [])

  auth._has_team_role = (user, team, role) ->
    user_id = user.name
    return auth.is_active_user(user) and user_id in (team.roles[role]?.members or [])

  auth._is_resource_admin = (user, resource) ->
    return auth._has_resource_role(user, resource, 'admin')

  auth._is_team_admin = (user, team) ->
    return auth._has_team_role(user, team, 'admin')

  auth.add_team = (actor) ->
    return auth.kratos._is_kratos_admin(actor)
  auth.remove_team = (actor) ->
    return auth.kratos._is_kratos_admin(actor)

  auth.add_team_asset = (actor, team, resource) ->
    return auth.is_active_user(actor) and auth[resource]?.add_team_asset?(actor, team) or false
  auth.remove_team_asset = (actor, team, resource) ->
    return auth.is_active_user(actor) and auth[resource]?.remove_team_asset?(actor, team) or false

  auth.add_team_member = (actor, team, role) ->
    if role in auth.roles.team_admin
      return auth.kratos._is_kratos_admin(actor)
    else if role in auth.roles.team
      return auth.kratos._is_kratos_admin(actor) or auth._is_team_admin(actor, team)
    else
      return false
  auth.remove_team_member = (actor, team, role) ->
    if role in auth.roles.team_admin
      return auth.kratos._is_kratos_admin(actor)
    else
      return auth.kratos._is_kratos_admin(actor) or auth._is_team_admin(actor, team)

  auth.add_user = (actor) ->
    return auth.kratos._is_kratos_admin(actor)
  auth.remove_user = (actor) ->
    return auth.kratos._is_kratos_admin(actor)

  auth.add_resource_role = (actor, resource, role) ->
    return auth.is_active_user(actor) and auth[resource]?.add_resource_role?(actor, role) or false
  auth.remove_resource_role = (actor, resource, role) ->
    return auth.is_active_user(actor) and auth[resource]?.remove_resource_role?(actor, role) or false

  auth.roles =
    team: [
      'admin',
      'member',
    ],
    team_admin: [
      'admin',
    ],
    resource: {
      kratos: ['admin', 'disabled'],
      gh: ['user'],
    }
  auth.resources = [
    'gh'
  ]

  if not window?
    require('./kratos')(auth)
    require('./gh')(auth)

if window?
  auth(window.kratos.validation)
else
  module.exports = auth