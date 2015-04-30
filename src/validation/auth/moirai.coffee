moirai = (auth) ->
  is_moirai_team_admin = (actor, team) ->
    return auth._has_resource_role(actor, 'moirai', 'user') and
           auth._is_team_admin(actor, team)

  auth.moirai =
    add_team_asset: (actor, team) ->
      return auth.kratos._is_kratos_admin(actor) or 
                   is_moirai_team_admin(actor, team)

    remove_team_asset: (actor, team) ->
      return auth.kratos._is_kratos_admin(actor) or 
                   is_moirai_team_admin(actor, team)

    add_resource_role: (actor, role) ->
      return auth.is_kratos_system_user(actor)

    remove_resource_role: (actor, role) ->
      return auth.is_kratos_system_user(actor)


    _is_moirai_team_admin: is_moirai_team_admin

module.exports = moirai
