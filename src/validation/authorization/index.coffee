_ = require('underscore')

module.exports = (validation, plugins) ->
  auth = {}

  auth.is_same_user = (user1, user2) ->
    return user1.name == user2.name

  auth.is_system_user = (user) ->
    return user.name in ['admin']

  auth.is_kratos_system_user = (user) ->
    return user.name == 'admin'

  auth.is_active_user = (user) ->
    return auth.is_system_user(user) or
           'kratos|enabled' in (user.roles or [])

  auth._has_resource_role = (user, resource, role) ->
    return auth.is_active_user(user) and 
           (
             auth.is_system_user(user) or
             (resource + '|' + role) in (user.roles or [])
           )

  auth._has_team_role = (user, team, role) ->
    user_id = user.name
    return auth.is_active_user(user) and 
           (
             auth.is_system_user(user) or
             user_id in (team.roles[role]?.members or [])
           )

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

  auth.proxy_resource = (actor, team, resource, proxyAction) ->
    return auth.is_active_user(actor) and auth[resource]?.proxy?[proxyAction]?(actor, team) or false

  auth.add_user = (actor) ->
    return auth.kratos._is_kratos_admin(actor)
  auth.remove_user = (actor) ->
    return auth.kratos._is_kratos_admin(actor)

  auth.add_resource_role = (actor, resource, role) ->
    return auth.is_active_user(actor) and auth[resource]?.add_resource_role?(actor, role) or false
  auth.remove_resource_role = (actor, resource, role) ->
    return auth.is_active_user(actor) and auth[resource]?.remove_resource_role?(actor, role) or false

  auth.add_user_data = (actor, user) ->
    return auth.is_active_user(actor) and (auth.is_same_user(actor, user) or auth.is_system_user(actor))

  auth.kratos = require('./kratos')(validation)

  auth.roles =
    team: [
      'admin',
      'member',
    ],
    team_admin: [
      'admin',
    ],
    resource: {kratos: ['admin', 'disabled']}
  auth.resources = []

  plugins.forEach((plugin) ->
    auth[plugin.name] = plugin.authorization(validation)
    auth.roles.team = auth.roles.team.concat(plugin.roles.team)
    auth.roles.team_admin = auth.roles.team_admin.concat(plugin.roles.team_admin)
    auth.roles.resource[plugin.name] = plugin.roles.resource
    auth.resources.push(plugin.name)
  )

  auth.roles.team = _.uniq(auth.roles.team)
  auth.roles.team_admin = _.uniq(auth.roles.team_admin)

  return auth
