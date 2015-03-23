validation =
  _is_team: (doc) ->
    return doc._id.indexOf('team_') == 0
  _is_user: (doc) ->
    return doc._id.indexOf('org.couchdb.user:') == 0
  _get_doc_type: (doc) ->
    if validation._is_team(doc)
      return 'team'
    else if validation._is_user(doc)
      return 'user'
    else
      return

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

if window?
  window.kratos = {validation: validation}
else
  require('./auth/auth')(validation)
  require('./val/val')(validation)
  module.exports = validation
