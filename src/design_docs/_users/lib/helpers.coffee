h = require('pantheon-helpers').design_docs.helpers

h.sanitize_user = (user) ->
  _ = require('underscore')
  sanitized_user = _.clone(user)
  delete sanitized_user.password_scheme
  delete sanitized_user.iterations
  delete sanitized_user.derived_key
  delete sanitized_user.salt
  return sanitized_user

module.exports = h
