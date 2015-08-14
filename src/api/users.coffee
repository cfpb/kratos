_ = require('underscore')
utils = require('../utils')
couch_utils = require('../couch_utils')
uuid = require('node-uuid')
conf = require('../config')
Promise = require('pantheon-helpers').promise
doAction = require('../doAction').doAction
validation = require('../validation')

users = {}

processReq = (req) ->
  params = req.params
  userName = params.userId
  actor = req.session.user
  if userName.indexOf('org.couchdb.user:') == 0
    userName = userName.slice(17)
  return [actor, userName, params]

isInt = (s) ->
  return String(parseInt(s)) == s

users.getUsers = (client, opts, callback) ->
  ###
  opts:
    enabled - true (default): return only enabled; false: return only disabled
    names - return only those active users with the names specified in the list
  
  names will override disabled
  ###
  if _.isFunction(opts) or opts == 'promise'
    callback = opts
  opts or= {}
  params = {include_docs: 'true'}
  if opts.names
    params.keys = opts.names.map((name) -> [true, name])
  else
    enabled = if (opts.enabled == false) then false else true
    _.extend(params, {
      startkey: [enabled],
      endkey: [enabled, {}],
    })
  return client.use('_users').viewWithList('base', 'by_name', 'get_users', params, callback)

users.handleGetUsers = (req, resp) ->
  resource = null
  for rsrc, rsrcId of req.query
    if rsrc in validation.auth.resources
      resource = rsrc
      break

  if resource
    if isInt(rsrcId)
      rsrcId = parseInt(rsrcId)
    users.getUserByResourceId(req.couch, resource, rsrcId).pipe(resp)
  else
    req.query.enabled = req.query.enabled != 'false'
    users.getUsers(req.couch, req.query).pipe(resp)

users.getUserByResourceId = (client, resource, resourceId, callback) ->
  return client.use('_users')
    .viewWithList('base', 'by_resource_id', 'get_user', 
                  {include_docs: true, key: [resource, resourceId]},
                  callback
                 )


users.getUser = (client, userName, callback) ->
  ### will return system user if callback or promise, but not if stream ###
  systemUserName = conf.COUCHDB.SYSTEM_USER
  systemUser = {name: systemUserName, roles: []}
  isSystemUser = conf.COUCHDB.SYSTEM_USER == userName
  if isSystemUser and _.isFunction(callback)
    return callback(null, systemUser)
  else if isSystemUser and callback == 'promise'
    return Promise.resolve(systemUser)
  else
    return couch_utils.rewrite(client.use('_users'), 'base', '/users/org.couchdb.user:' + userName, callback)

users.handleGetUser = (req, resp) ->
  [actor, userName, params] = processReq(req)
  users.getUser(req.couch, userName).pipe(resp)  

users.addRole = (actor, userName, resource, role) ->
  # returns promise
  userId = 'org.couchdb.user:' + userName
  return doAction('_users', actor, userId, {
    a: 'r+',
    resource: resource
    role: role,
  })

users.removeRole = (actor, userName, resource, role) ->
  # returns promise
  userId = 'org.couchdb.user:' + userName
  return doAction('_users', actor, userId, {
    a: 'r-',
    resource: resource
    role: role,
  })

users.handleAddRole = (req, resp) ->
  [actor, userName, params] = processReq(req)
  promise = users.addRole(actor, userName, params.resource, params.role)
  Promise.sendHttp(promise, resp)

users.handleRemoveRole = (req, resp) ->
  [actor, userName, params] = processReq(req)
  promise = users.removeRole(actor, userName, params.resource, params.role)
  Promise.sendHttp(promise, resp)

users.addData = (actor, userName, path, data) ->
  userId = 'org.couchdb.user:' + userName
  return doAction('_users', actor, userId, {
    a: 'd+',
    path: path
    data: data
  })


users.handleAddData = (req, resp) ->
  [actor, userName, params] = processReq(req)
  pathString = params.path or ''
  path = _.compact(pathString.split('/'))
  data = req.body

  # TODO: move into actionHandler
  if _.isArray(data) or not _.isObject(data)
    return resp.status(400).end(JSON.stringify({'error': 'bad_request ', 'msg': 'data must be an object - {}'}))

  promise = users.addData(actor, userName, path, data)
  Promise.sendHttp(promise, resp)

users.reactivateUser = (actor, userName) ->
  userId = 'org.couchdb.user:' + userName
  return doAction('_users', actor, userId, {
    a: 'u+',
  })

users.handleReactivateUser = (req, resp) ->
  [actor, userName, params] = processReq(req)
  promise users.reactivateUser(actor, userName)
  Promise.sendHttp(promise, resp)

users.deactivateUser = (actor, userName) ->
  userId = 'org.couchdb.user:' + userName
  doAction('_users', actor, userId, {
    a: 'u-',
  })

users.handleDeactivateUser = (req, resp) ->
  [actor, userName, params] = processReq(req)
  return users.deactivateUser(actor, userName)
  Promise.sendHttp(promise, resp)

users.createUser = (actor, userData) ->
  userData.password = conf.COUCH_PWD
  return doAction('_users', actor, null, {
    a: 'u+',
    record: userData
  })

users.handleCreateUser = (req, resp) ->
  ###
  body must be a hash ({}).
  body must include the following data:
  {
    data: {
      username: <str>,
      <optional additional data>...
    }
  }
  body may include the following data:
  {
    roles: <array>
    rsrcs: {
      <rsrc str>: <hash>
    }

  }
  ###
  promise = users.createUser(actor, req.body)
  Promise.sendHttp(promise, resp)

module.exports = users
