_ = require('underscore')
s = require('underscore.string')
couch_utils = require('./couch_utils')
Promise = require('promise')
resolve = require('url').resolve
parse_links = require('parse-links')

x = {}

x.denodeify_all = (obj) ->
  out = {}
  for k, v of obj
    if _.isFunction(v)
      out[k] = Promise.denodeify(v)
    else if _.isObject(v) and not _.isArray(v)
      out[k] = x.denodeify_all(v)

x.denodeify_api = (obj) ->
  for k, v of obj
    if _.isFunction(v) and not s.startsWith(k, 'handle')
      pName = 'p' + s.capitalize(k)
      obj[pName] = Promise.denodeify(v)
    else if _.isObject(v) and not _.isArray(v)
      x.denodeify_api(v)

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


x.process_resp = (opts, callback) ->
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
      err = {err: err, msg: body, code: resp?.statusCode}
    if opts.body_only
      return callback(err, body)
    else
      return callback(err, resp, body)


x.PromiseClient = (client, url_base) ->
  Client = {}
  ['get', 'put', 'post', 'del', 'head', 'patch'].forEach((method) ->
    Client[method] = Promise.denodeify((opts, callback) ->
      if typeof opts == 'string'
        opts = {url: opts}
      opts.url = resolve(url_base, opts.url)
      return client[method](opts, x.process_resp(opts, callback))
    )
  )

  Client.get_all = (opts) ->
    if typeof opts == 'string'
      opts = {url: opts}
    results = []
    handle_get = (resp) ->
      results = results.concat(resp.body)
      link_header = resp.headers.link
      links = parse_links(link_header) if link_header?
      opts.url = links?.next or null

      if opts.url
        return Client.get(opts).then(handle_get)
      else
        return Promise.resolve(results)
    return Client.get(opts).then(handle_get)

  Client.find_one = (opts, predicate) ->
    ###
    keep getting results until we find one that matches predicate
    or we reach last result.
    ###
    if typeof opts == 'string'
      opts = {url: opts}
    handle_get = (resp) ->
      result = _.find(resp.body, predicate)
      link_header = resp.headers.link
      links = parse_links(link_header) if link_header?
      opts.url = links?.next or null

      if result or not opts.url
        return Promise.resolve(result)
      else
        return Client.get(opts).then(handle_get)
    return Client.get(opts).then(handle_get)

  return Client

x.compact_hash = (hash) ->
  ###
  given a hash return a new hash with only non-falsy values. 
  if the hash will be empty, return undefined
  ###
  out = _.pick(hash, _.identity)
  if _.isEmpty(out)
    return undefined
  else
    return out

x.get_org_dbs = (callback) ->
  ###
  return all organization databases
  ###
  await couch_utils.nano_admin.db.list(defer(err, dbs))
  if err then return callback(err)
  out = _.filter(dbs, (x) -> x.indexOf('org_') == 0)
  return callback(null, out)

module.exports = x