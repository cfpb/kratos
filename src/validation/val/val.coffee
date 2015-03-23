validation = (validation) ->
  auth = validation.auth
  validation.validation =
    add_team: (team) ->
      return true
    remove_team: (team) ->
      return true

    add_team_asset: (team, resource, asset) ->
      return validation.validation[resource]?.add_team_asset?(team, asset) or false
    remove_team_asset: (team, resource, asset) ->
      return validation.validation[resource]?.remove_team_asset?(team, asset) or false

    add_team_member: (team, user, role) ->
      if role in auth.roles.team_admin or
         role in auth.roles.team
        return true
      else
        return false
    remove_team_member: (team, user, role) ->
      return true

    add_user: (user) ->
      return true
    remove_user: (user) ->
      return true

    add_resource_role: (user, resource, role) ->
      return auth.is_active_user(user) and
             role in (auth.roles.resource[resource] or [])
    remove_resource_role: (user, resource, role) ->
      return true

  if not window?
    require('./gh')(validation.validation)

if window?
  validation(window.kratos.validation)
else
  module.exports = validation
