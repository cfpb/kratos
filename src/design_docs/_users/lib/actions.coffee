validate = require('./validation/index')
do_action = require('pantheon-helpers').design_docs.do_action
validate_doc_update = require('pantheon-helpers').design_docs.validate_doc_update.validate_doc_update
h = require('./helpers')
_ = require('underscore')

a = {}
a.do_actions =
  user:
    'r+': (user, action, actor) ->
      role = action.resource + '|' + action.role
      h.insert_in_place(user.roles, role)
    'r-': (user, action, actor) ->
      role = action.resource + '|' + action.role
      h.remove_in_place(user.roles, role)
    'u+': (user, action, actor) ->
      h.insert_in_place(user.roles, 'kratos|enabled')
    'u-': (user, action, actor) ->
      user.roles = []
    'd+': (user, action, actor) ->
      path = ['data'].concat(action.path)
      value = action.data
      if not _.isObject(value) or _.isArray(value)
        throw new Error('value must be an object')
      merge_target = h.mk_objs(user, path, {})
      _.extend(merge_target, value)
  create:
    'u+': (user, action, actor) ->
      _.extend(user, action.record, {
        _id: 'org.couchdb.user:' + user._id,
        type: 'user',
        name: user._id,
      })

a.validate_actions =
  user:
    'r+': (event, actor, old_user, new_user) -> 
      validate.add_resource_role(actor, new_user, event.resource, event.role)
    'r-': (event, actor, old_user, new_user) -> 
      validate.remove_resource_role(actor, new_user, event.resource, event.role)
    'u+': (event, actor, old_user, new_user) -> 
      validate.add_user(actor, old_user or new_user)
    'u-': (event, actor, old_user, new_user) -> 
      validate.remove_user(actor, old_user)
    'd+': (event, actor, old_user, new_user) ->
      validate.add_user_data(actor, old_user, new_user)

a.do_action = do_action(a.do_actions,
               validate._get_doc_type,
               h.sanitize_user
              )

a.validate_doc_update = validate_doc_update(
                          a.validate_actions,
                          validate._get_doc_type,
                        )

module.exports = a