auth =
  # pull out just the needed methods from validation/auth.
  is_system_user: (user) ->
    return user.name in ['admin']

  is_active_user: (user) ->
    return auth.is_system_user(user) or
           'kratos|enabled' in (user.roles or [])

  _is_user: (doc) ->
    return doc._id.indexOf('org.couchdb.user:') == 0

module.exports = auth
