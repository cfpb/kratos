h = {}

h.sanitize_user = (user) ->
  _ = require('lib/underscore')
  sanitized_user = _.clone(user)
  delete sanitized_user.password_scheme
  delete sanitized_user.iterations
  delete sanitized_user.derived_key
  delete sanitized_user.salt
  return sanitized_user

h.mk_objs = (obj, path_array, val={}) ->
  ###
  make a set of nested object.

  obj = {'x': 1}
  mk_objs(obj, ['a', 'b'], ['1'])
  # returns []
  # obj now equals {'x': 1, 'a': {'b': ['1']}}

  return the val
  ###
  path_part = path_array.shift()
  if path_part == undefined
    return obj
  if not obj[path_part]
    if path_array.length
      obj[path_part] = {}
    else
      obj[path_part] = val
      
  return h.mk_objs(obj[path_part], path_array, val)

module.exports = h
