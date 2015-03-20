_ = require('underscore')
utils = require('../utils')
couch_utils = require('../couch_utils')
user_db = couch_utils.nano_system_user.use('_users')
uuid = require('node-uuid')
conf = require('../config')

users = {}

isInt = (s) ->
  return String(parseInt(s)) == s

users.get_users = (callback) ->
  return couch_utils.rewrite(user_db, 'base', '/users', callback)

users.handle_get_users = (req, resp) ->
  for resource, rsrcs_id of req.query
    break

  if resource
    if isInt(rsrcs_id)
      rsrcs_id = parseInt(rsrcs_id)
    user_db
      .viewWithList('base', 'by_resource_id', 'get_user', 
                    {include_docs: true, key: [resource, rsrcs_id]})
      .pipe(resp)
  else
    users.get_users().pipe(resp)

users.get_user = (user_id, callback) ->
  return couch_utils.rewrite(user_db, 'base', '/users/org.couchdb.user:' + user_id, callback)

users.handle_get_user = (req, resp) ->
  users.get_user(req.params.user_id).pipe(resp)  

add_remove_role = (client, action_type, user, resource, role, callback) ->
  action = {
    action: action_type
    key: resource
    value: role
    uuid: uuid.v4()
  }
  return client.use('_users').atomic('base', 'do_action', user, action, callback)

users.add_role = (client, user, resource, role, callback) ->
  return add_remove_role(client, 'a+', user, resource, role, callback)

users.remove_role = (client, user, resource, role, callback) ->
  return add_remove_role(client, 'a-', user, resource, role, callback)

users.handle_add_remove_role = (action_type) ->
  (req, resp) ->
    user = 'org.couchdb.user:' + req.params.user_id
    resource = req.params.resource
    role = req.params.role

    return add_remove_role(req.couch, action_type, user, resource, role).pipe(resp)

users.handle_add_data = (req, resp) ->
  user = 'org.couchdb.user:' + req.params.user_id
  path_string = req.params.path or ''
  key = _.compact(path_string.split('/'))
  value = req.body
  if _.isArray(value) or not _.isObject(value)
    return resp.status(400).end(JSON.stringify({'error': 'bad_request ', 'msg': 'data must be an object - {}'}))

  action = {
    action: 'd+'
    key: key
    value: value
    uuid: uuid.v4()
  }
  req.couch.use('_users').atomic('base', 'do_action', user, action).pipe(resp)

users.reactivate_user = (client, user, callback) ->
  action = {
    action: 'u+'
    uuid: uuid.v4()
  }
  return client.use('_users').atomic('base', 'do_action', user, action, callback)


users.handle_reactivate_user = (req, resp) ->
  user = 'org.couchdb.user:' + req.params.user_id
  return users.reactivate_user(req.couch, user).pipe(resp)

users.deactivate_user = (client, user, callback) ->
  action = {
    action: 'u-'
    uuid: uuid.v4()
  }
  return client.use('_users').atomic('base', 'do_action', user, action, callback)

users.handle_deactivate_user = (req, resp) ->
  user = 'org.couchdb.user:' + req.params.user_id
  return users.deactivate_user(req.couch, user).pipe(resp)

users.handle_add_user = (req, resp) ->
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
  now = +new Date()
  user = _.extend({roles: []}, req.body)
  await couch_utils.get_uuid(defer(err, name))
  _.extend(user, {
    _id: "org.couchdb.user:" + name,
    type: "user",
    name: name,
    password: conf.COUCH_PWD,
    audit: [{u: req.session.user, dt: now, a: 'u+', id: uuid.v4(), r:req.body}],
  })
  await req = req.couch.use('_users').insert(user, defer(err, user_resp))
  if err
    return resp.status(err.statusCode).send(JSON.stringify(error: err.error, msg: err.reason))
  else
    return users.get_user(name).pipe(resp)  


utils.denodeify_api(users)
module.exports = users
