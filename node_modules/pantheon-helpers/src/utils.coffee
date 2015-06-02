_ = require('underscore')

u =
  mk_objs: (obj, path_array, val={}) ->
    ###
    make a set of nested object.

    obj = {'x': 1}
    mk_objs(obj, ['a', 'b'], ['1'])
    # returns []
    # obj now equals {'x': 1, 'a': {'b': ['1']}}

    return the val
    ###
    if not path_array.length
      return obj
    path_part = path_array.shift()
    if not obj[path_part]
      if path_array.length
        obj[path_part] = {}
      else
        obj[path_part] = val
    else if path_array.length and _.isArray(obj[path_part])
      throw new Error('item at "' + path_part + '" must be an Object, but it is an Array.')
    else if path_array.length and not _.isObject(obj[path_part])
      throw new Error('item at "' + path_part + '" must be an Object, but it is a ' + typeof(obj[path_part]) + '.')
    return u.mk_objs(obj[path_part], path_array, val)

u.process_resp = (opts, callback) ->
  ###
  process a request HTTP response. return a standardized
  error regardless of whether there was a transport error or a server error
  opts is a hash with an optional:
    ignore_codes - array of error codes to ignore, or if 'all' will ignore all http error codes
    body_only - boolean whether to return the body or the full response
  ###
  if typeof opts == 'function'
    callback = opts
    opts = {}
  ignore_codes = opts.ignore_codes or []

  is_http_err = (resp) ->
    if ignore_codes == 'all' or
       resp.statusCode < 400 or 
       resp.statusCode in (ignore_codes or [])
      return false
    else
      return true

  (err, resp, body) ->
    if err or is_http_err(resp)
      req = resp?.req or {}
      req = _.pick(req, '_headers', 'path', 'method')
      err = {err: err, msg: body, code: resp?.statusCode, req: req}
    if opts.body_only
      return callback(err, body)
    else
      return callback(err, resp, body)

u.deepExtend = (target, source) ->
  ###
  recursively extend an object.
  does not recurse into arrays
  ###
  for k, sv of source
    tv = target[k]
    if tv instanceof Array
      target[k] = sv
    else if typeof(tv) == 'object' and typeof(sv) == 'object'
      target[k] = u.deepExtend(tv, sv)
    else
      target[k] = sv
  return target

module.exports = u
