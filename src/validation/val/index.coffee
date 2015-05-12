_deepExtend = (target, source) ->
  ###
  recursively extend an object.
  does not recurse into arrays
  ###
  for k, sv of source
    tv = target[k]
    if tv instanceof Array
      target[k] = sv
    else if typeof(tv) == 'object' and typeof(sv) == 'object'
      target[k] = _deepExtend(tv, sv)
    else
      target[k] = sv
  return target

validation = (validation) ->
  auth = validation.auth
  validation.validation =
    _deepExtend: _deepExtend
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

    proxy_asset_action: (actor, team, resource, asset, path, method, body, req) ->
      if not validation.validation[resource]?.proxy_asset_action?
        throw('resource, ' + resource + ', does not support this action')
      validation.validation[resource]?.proxy_asset_action?.apply(this, arguments) or false    


    add_user_data: (actor, old_user, new_user) ->
      old_data = old_user.data
      new_data = new_user.data
      if auth.is_system_user(actor)
        form_type = 'system'
      else if auth.is_same_user(actor, old_user)
        form_type = 'self'
      else
        throw "invalid authorization"
      form = validation.schema.user_data[form_type]({value: new_data})
      # validation_data returns the cleaned data, excluding any data that is not explicitly allowed by the schema
      # in a standardized format that is not necessarily the same as the data as it was initially provided
      validated_data = form.getClean()
      # so we merge the validated data into the old data and the new data and then ensure they are equal.
      # if data that was not allowed to be modified is modified, then they won't be the same, and there will be an error.
      # if the getClean function modified some data, then the modified data will be merged into both old and new and there won't be an error.
      merged_validated_old_data = _deepExtend(old_data, validated_data)
      merged_validated_new_data = _deepExtend(new_data, validated_data)
      if JSON.stringify(merged_validated_new_data) != JSON.stringify(merged_validated_old_data)
        throw('Modifications not allowed by schema')

  require('./gh')(validation.validation)
  require('./moirai')(validation.validation)

module.exports = validation
