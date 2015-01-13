_ = require('underscore')
couch_utils = require('../couch_utils')
users = {}
user_db = couch_utils.nano_admin.use('_users')
uuid = require('node-uuid')
conf = require('../config')

isInt = (s) ->
  return String(parseInt(s)) == s

users._get_users = (callback) ->
  return couch_utils.rewrite(user_db, 'base', '/users', callback)

users.get_users = (req, resp) ->
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
    users._get_users().pipe(resp)

users._get_user = (user_id, callback) ->
  return couch_utils.rewrite(user_db, 'base', '/users/org.couchdb.user:' + user_id, callback)

users.get_user = (req, resp) ->
  users._get_user(req.params.user_id).pipe(resp)  

_add_remove_role = (client, action_type, user, resource, role, callback) ->
  action = {
    action: action_type
    key: resource
    value: role
    uuid: uuid.v4()
  }
  return client.use('_users').atomic('base', 'do_action', user, action, callback)

users._add_role = (client, user, resource, role, callback) ->
  return _add_remove_role(client, 'a+', user, resource, role, callback)

users._remove_role = (client, user, resource, role, callback) ->
  return _add_remove_role(client, 'a-', user, resource, role, callback)

users.add_remove_role = (action_type) ->
  (req, resp) ->
    user = 'org.couchdb.user:' + req.params.user_id
    resource = req.params.resource
    role = req.params.role

    return _add_remove_role(req.couch, action_type, user, resource, role).pipe(resp)

users.add_data = (req, resp) ->
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

users.add_user = (req, resp) ->
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
    return users._get_user(name).pipe(resp)  



module.exports = users
