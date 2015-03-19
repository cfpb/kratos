validation = (validation) ->
  auth = validation.auth
  validation.validation =
    add_team: (team) ->
    remove_team: (team) ->

    add_team_asset: (team, resource, asset) ->
      if not validation.validation[resource]?.add_team_asset?
        throw('resource, ' + resource + ', does not support adding assets')
      return validation.validation[resource].add_team_asset(team, asset)
    remove_team_asset: (team, resource, asset) ->
      if not validation.validation[resource]?.remove_team_asset?
        throw('resource, ' + resource + ', does not support removing assets')
      return validation.validation[resource].remove_team_asset(team, asset)

    add_team_member: (team, user, role) ->
      if role not in auth.roles.team_admin and
         role not in auth.roles.team
        throw('invalid role: ' + role)
    remove_team_member: (team, user, role) ->

    add_user: (user) ->
    remove_user: (user) ->

    add_resource_role: (user, resource, role) ->
      if not auth.is_active_user(user)
        throw('invalid user: ' + user.name)
      if role not in (auth.roles.resource[resource] or [])
        throw('invalid role: ' + role)
    remove_resource_role: (user, resource, role) ->

  if not window?
    require('./gh')(validation.validation)

if window?
  validation(window.kratos.validation)
else
  module.exports = validation
