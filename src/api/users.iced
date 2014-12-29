couch_utils = require('../couch_utils')
users = {}
user_db = couch_utils.nano_admin.use('_users')
uuid = require('node-uuid')

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

users.add_remove_role = (action_type) ->
  (req, resp) ->
    user = 'org.couchdb.user:' + req.params.user_id
    resource = req.params.resource
    role = req.params.role

    action = {
      action: action_type
      key: resource
      value: role
      uuid: uuid.v4()
    }
    user_db.atomic('base', 'do_action', user, action).pipe(resp)


module.exports = users