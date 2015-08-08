{getPlugins} = require('../utils')
plugins = getPlugins()

validation = {
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

  _validate: (fn_name, auth_args, val_args) ->
    authorized = validation.auth[fn_name].apply(null, auth_args)
    if not authorized
      throw({state: 'unauthorized', err: 'You do not have the privileges necessary to perform the action.'})

    try
      validation.validation[fn_name].apply(null, val_args)
    catch e
      if typeof e != 'string'
        e = JSON.stringify(e)
      throw({state: 'invalid', err: e})

  add_team: (actor, team) ->
    validation._validate('add_team', [actor], [team])

  remove_team: (actor, team) ->
    validation._validate('remove_team', [actor], [team])

  add_team_asset: (actor, team, resource, asset) ->
    validation._validate('add_team_asset', [actor, team, resource], [team, resource, asset])

  remove_team_asset: (actor,team, resource, asset) ->
    validation._validate('remove_team_asset', [actor, team, resource], [team, resource, asset])

  add_team_member: (actor, team, user, role) ->
    validation._validate('add_team_member', [actor, team, role], [team, user, role])

  remove_team_member: (actor, team, user, role) ->
    validation._validate('remove_team_member', [actor, team, role], [team, user, role])

  proxy_asset_action: (actor, team, resource, asset, path, method, body, req) ->
    validation._validate('proxy_asset_action', arguments, arguments)

  proxy_resource: (actor, team, resource, proxyAction, asset) ->
    # asset is optional for proxy actions that are not performed on an asset
    validation._validate('proxy_resource', [actor, team, resource, proxyAction], [actor, team, resource, proxyAction, asset])


  add_user: (actor, user) ->
    validation._validate('add_user', [actor], [user])

  remove_user: (actor, user) ->
    validation._validate('remove_user', [actor], [user])

  add_resource_role: (actor, user, resource, role) ->
    validation._validate('add_resource_role', [actor, resource, role], [user, resource, role])

  remove_resource_role: (actor, user, resource, role) ->
    validation._validate('remove_resource_role', [actor, resource, role], [user, resource, role])

  add_user_data: (actor, old_user, new_user) ->
    validation._validate('add_user_data', [actor, old_user], [actor, old_user, new_user])

  actions:
    team:
      't+': (event, actor, old_team, new_team) ->
        validation.add_team(actor, new_team)
      'a+': (event, actor, old_team, new_team) ->
        validation.add_team_asset(actor, old_team, event.resource, event.asset)
      'a-': (event, actor, old_team, new_team) ->
        validation.remove_team_asset(actor, old_team, event.resource, event.asset)
      'u+': (event, actor, old_team, new_team) ->
        validation.add_team_member(actor, old_team, null, event.role)
      'u-': (event, actor, old_team, new_team) ->
        validation.remove_team_member(actor, old_team, null, event.role)
    user:
      'r+': (event, actor, old_user, new_user) ->
        validation.add_resource_role(actor, new_user, event.resource, event.role)
      'r-': (event, actor, old_user, new_user) ->
        validation.remove_resource_role(actor, new_user, event.resource, event.role)
      'u+': (event, actor, old_user, new_user) ->
        validation.add_user(actor, old_user or new_user)
      'u-': (event, actor, old_user, new_user) ->
        validation.remove_user(actor, old_user)
      'd+': (event, actor, old_user, new_user) ->
        validation.add_user_data(actor, old_user, new_user)

}

validation.auth = require('./authorization')(validation, plugins)
validation.validation = require('./validation')(validation, plugins)

require('./schema/index')(validation)


module.exports = validation
