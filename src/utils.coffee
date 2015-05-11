_ = require('underscore')
s = require('underscore.string')
couch_utils = require('./couch_utils')
Promise = require('pantheon-helpers').promise

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

x.get_org_dbs = () ->
  ###
  return promise only
  return all organization databases
  ###
  couch_utils.nano_system_user.db.list('promise').then((dbs) ->
    out = _.filter(dbs, (x) -> x.indexOf('org_') == 0)
    Promise.resolve(out)
  )

module.exports = x