gh = (auth) ->
  is_gh_team_admin = (actor, team) ->
    return auth._has_resource_role(actor, 'gh', 'user') and
           auth._is_team_admin(actor, team)

  auth.gh =
    add_team_asset: (actor, team) ->
      return auth.kratos._is_kratos_admin(actor) or 
                   is_gh_team_admin(actor, team)

    remove_team_asset: (actor, team) ->
      return auth.kratos._is_kratos_admin(actor) or 
                   is_gh_team_admin(actor, team)

    add_resource_role: (actor, role) ->
      return auth.is_kratos_system_user(actor)

    remove_resource_role: (actor, role) ->
      return auth.is_kratos_system_user(actor)


    _is_gh_team_admin: is_gh_team_admin

module.exports = gh
