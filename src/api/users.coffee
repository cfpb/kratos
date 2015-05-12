_ = require('underscore')
utils = require('../utils')
couch_utils = require('../couch_utils')
user_db = couch_utils.nano_system_user.use('_users')
uuid = require('node-uuid')
conf = require('../config')
Promise = require('pantheon-helpers').promise
doAction = require('pantheon-helpers').doAction
validate = require('../validation')

users = {}

process_req = (req) ->
  params = req.params
  user_name = params.user_id
  return [user_name, params]

isInt = (s) ->
  return String(parseInt(s)) == s

users.get_users = (opts, callback) ->
  ###
  opts:
    all - return all users including deactivated users 
          (default: false - return only active users)
    names - return only those active users with the names specified in the list
  
  names will override all    
  ###
  if typeof(opts) == 'function' or opts == 'promise'
    callback = opts
  opts or= {}
  params = {include_docs: 'true'}
  if opts.names
    params.keys = opts.names.map((name) -> [true, name])
  else if opts.all not in ['true', true]
    _.extend(params, {
      startkey: [true],
      endkey: [true, {}],
    })
  return user_db.viewWithList('base', 'by_name', 'get_users', params, callback)

users.handle_get_users = (req, resp) ->
  resource = null
  for rsrc, rsrc_id of req.query
    if rsrc in validate.auth.resources
      resource = rsrc
      break

  if resource
    if isInt(rsrc_id)
      rsrc_id = parseInt(rsrc_id)
    user_db
      .viewWithList('base', 'by_resource_id', 'get_user', 
                    {include_docs: true, key: [resource, rsrc_id]})
      .pipe(resp)
  else
    users.get_users(req.query).pipe(resp)

users.get_user = (user_name, callback) ->
  ### will return system user if callback or promise, but not if stream ###
  system_user_name = conf.COUCHDB.SYSTEM_USER
  system_user = {name: system_user_name, roles: []}
  is_system_user = conf.COUCHDB.SYSTEM_USER == user_name
  if is_system_user and _.isFunction(callback)
    return callback(null, system_user)
  else if is_system_user and callback == 'promise'
    return user_promise = Promise.resolve(system_user)
  else
    return couch_utils.rewrite(user_db, 'base', '/users/org.couchdb.user:' + user_name, callback)

users.handle_get_user = (req, resp) ->
  [user_name, params] = process_req(req)
  users.get_user(user_name).pipe(resp)  

users.add_role = (client, user_name, resource, role, callback) ->
  user_id = 'org.couchdb.user:' + user_name
  return doAction(client.use('_users'), 'base', user_id, {
    a: 'r+',
    resource: resource
    role: role,
  }, callback)

users.remove_role = (client, user_name, resource, role, callback) ->
  user_id = 'org.couchdb.user:' + user_name
  return doAction(client.use('_users'), 'base', user_id, {
    a: 'r-',
    resource: resource
    role: role,
  }, callback)

users.handle_add_role = (req, resp) ->
  [user_name, params] = process_req(req)
  users.add_role(req.couch, user_name, params.resource, params.role).pipe(resp)

users.handle_remove_role = (req, resp) ->
  [user_name, params] = process_req(req)
  users.remove_role(req.couch, user_name, params.resource, params.role).pipe(resp)

users.add_data = (client, user_name, path, data, callback) ->
  user_id = 'org.couchdb.user:' + user_name
  return doAction(client.use('_users'), 'base', user_id, {
    a: 'd+',
    path: path
    data: data
  }, callback)


users.handle_add_data = (req, resp) ->
  [user_name, params] = process_req(req)
  path_string = params.path or ''
  path = _.compact(path_string.split('/'))
  data = req.body

  # TODO: move into couch
  if _.isArray(data) or not _.isObject(data)
    return resp.status(400).end(JSON.stringify({'error': 'bad_request ', 'msg': 'data must be an object - {}'}))

  users.add_data(req.couch, user_name, path, data).pipe(resp)

users.reactivate_user = (client, user_name, callback) ->
  user_id = 'org.couchdb.user:' + user_name
  doAction(client.use('_users'), 'base', user_id, {
    a: 'u+',
  }, callback)

users.handle_reactivate_user = (req, resp) ->
  [user_name, params] = process_req(req)
  return users.reactivate_user(req.couch, user_name).pipe(resp)

users.deactivate_user = (client, user_name, callback) ->
  user_id = 'org.couchdb.user:' + user_name
  doAction(client.use('_users'), 'base', user_id, {
    a: 'u-',
  }, callback)

users.handle_deactivate_user = (req, resp) ->
  [user_name, params] = process_req(req)
  return users.deactivate_user(req.couch, user_name).pipe(resp)

users.create_user = (client, user_data, callback) ->
  user_data.password = conf.COUCH_PWD
  doAction(client.use('_users'), 'base', null, {
    a: 'u+',
    record: user_data
  }, callback)

users.handle_create_user = (req, resp) ->
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
  users.create_user(req.couch, req.body).pipe(resp)

module.exports = users
