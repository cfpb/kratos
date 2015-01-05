kratos = (auth) ->
  is_kratos_admin = (user) ->
    return auth._is_resource_admin(user, 'kratos')

  auth.kratos =
    add_team: (user) ->
      return is_kratos_admin(user)

    remove_team: (user) ->
      return is_kratos_admin(user)

    add_team_member: (user, team, role) ->
      if role in auth.roles.team_admin
        return is_kratos_admin(user)
      else if role in auth.roles.team
        return is_kratos_admin(user) or auth._is_team_admin(user, team)
      else
        return false

    remove_team_member: (user, team, role) ->
      if role in auth.roles.team_admin
        return is_kratos_admin(user)
      else if role in auth.roles.team
        return is_kratos_admin(user) or auth._is_team_admin(user, team)
      else
        return false

    add_resource_role: (user, role) ->
      return user.name == 'admin'

    remove_resource_role: (user, role) ->
      return user.name == 'admin'

    _is_kratos_admin: is_kratos_admin

if window?
  kratos(window.kratos.auth)
else if exports?
  module.exports = kratos
