gh = (auth) ->
  is_gh_team_admin = (user, team) ->
    return auth._has_resource_role(user, 'gh', 'user') and
           auth._is_team_admin(user, team)

  auth.gh =
    add_team_asset: (user, team) ->
      return auth.kratos._is_kratos_admin(user) or 
                   is_gh_team_admin(user, team)

    remove_team_asset: (user, team) ->
      return auth.kratos._is_kratos_admin(user) or 
                   is_gh_team_admin(user, team)

    add_resource_role: (user, role) ->
      return user.name == 'admin'

    remove_resource_role: (user, role) ->
      return user.name == 'admin'


    _is_gh_team_admin: is_gh_team_admin

if window?
  gh(window.kratos.auth)
else if exports?
  module.exports = gh
