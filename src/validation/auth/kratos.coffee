kratos = (auth) ->
  auth.kratos =
    add_resource_role: (actor, role) ->
      return actor.name == 'admin'

    remove_resource_role: (actor, role) ->
      return actor.name == 'admin'

    _is_kratos_admin: (actor) ->
      return auth._is_resource_admin(actor, 'kratos')


if window?
  kratos(window.kratos.validation.auth)
else if exports?
  module.exports = kratos
