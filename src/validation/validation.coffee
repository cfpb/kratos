validation =
  add_team: (actor, team) ->
    return validation.auth.add_team(actor) &&
           validation.validation.add_team(team)
  remove_team: (actor, team) ->
    return validation.auth.remove_team(actor) &&
           validation.validation.remove_team(team)

  add_team_asset: (actor, team, resource, asset) ->
    return validation.auth.add_team_asset(actor, team, resource) &&
           validation.validation.add_team_asset(team, resource, asset)
  remove_team_asset: (actor,team, resource, asset) ->
    return validation.auth.remove_team_asset(actor, team, resource) &&
           validation.validation.remove_team_asset(team, resource, asset)

  add_team_member: (actor, team, user, role) ->
    return validation.auth.add_team_member(actor, team, role) &&
           validation.validation.add_team_member(team, user, role)
  remove_team_member: (actor, team, user, role) ->
    return validation.auth.remove_team_member(actor, team, role) &&
           validation.validation.remove_team_member(team, user, role)

  add_user: (actor, user) ->
    return validation.auth.add_user(actor) &&
           validation.validation.add_user(user)
  remove_user: (actor, user) ->
    return validation.auth.remove_user(actor) &&
           validation.validation.remove_user(user)

  add_resource_role: (actor, user, resource, role) ->
    return validation.auth.add_resource_role(actor, resource, role) &&
           validation.validation.add_resource_role(user, resource, role)
  remove_resource_role: (actor, user, resource, role) ->
    return validation.auth.remove_resource_role(actor, resource, role) &&
           validation.validation.remove_resource_role(user, resource, role)

validation.entries =
  teams:
    't+': (event, actor, old_team, new_team) -> 
            validation.add_team(actor, new_team)
    'a+': (event, actor, old_team, new_team) -> 
            validation.add_team_asset(actor, old_team, event.k, event.r)
    'a-': (event, actor, old_team, new_team) -> 
            validation.remove_team_asset(actor, old_team, event.k, event.r)
    'u+': (event, actor, old_team, new_team) -> 
            validation.add_team_member(actor, old_team, null, event.k)
    'u-': (event, actor, old_team, new_team) -> 
            validation.remove_team_member(actor, old_team, null, event.k)
  users:
    'r+': (event, actor, old_user, new_user) -> 
            validation.add_resource_role(actor, new_user, event.k, event.v)
    'r-': (event, actor, old_user, new_user) -> 
            validation.remove_resource_role(actor, new_user, event.k, event.v)
    'u+': (event, actor, old_user, new_user) -> 
            validation.add_user(actor, old_user)
    'u-': (event, actor, old_user, new_user) -> 
            validation.remove_user(actor, user)

if window?
  window.kratos = {validation: validation}
else
  require('./auth/auth')(validation)
  require('./validation/validation')(validation)
  module.exports = validation
