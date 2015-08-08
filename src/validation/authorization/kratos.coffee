module.exports = (validation) ->
  return {
    add_resource_role: (actor, role) ->
      return validation.auth.is_kratos_system_user(actor)

    remove_resource_role: (actor, role) ->
      return validation.auth.is_kratos_system_user(actor)

    _is_kratos_admin: (actor) ->
      return validation.auth._is_resource_admin(actor, 'kratos')
  }
