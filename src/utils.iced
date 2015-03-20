_ = require('underscore')
s = require('underscore.string')
couch_utils = require('./couch_utils')
Promise = require('promise')

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
  await couch_utils.nano_system_user.db.list(defer(err, dbs))
  if err then return callback(err)
  out = _.filter(dbs, (x) -> x.indexOf('org_') == 0)
  return callback(null, out)

module.exports = x