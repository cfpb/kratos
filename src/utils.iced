x = {}

x.mk_objs = (obj, path_array, val={}) ->
  ###
  make a set of nested object.

  obj = {'x': 1}
  mk_objs(obj, ['a', 'b'], ['1'])
  # returns []
  # obj now equals {'x': 1, 'a': {'b': ['1']}}

  return the val
  ###
  last_key = path_array.pop()
  for key in path_array
    if not obj[key]?
      obj[key] = {}
    obj = obj[key]
  if not obj[last_key]
    obj[last_key] = val
  return obj[last_key]

# x.deep_merge = (obj1, obj2) ->

module.exports = x