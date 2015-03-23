validate = require('./validation/validate')
do_action = require('./shared/do_action')
validate_doc_update = require('./shared/validate_doc_update').validate_doc_update
h = require('./helpers')
_ = require('./underscore')

a = {}
a.do_actions =
  user:
    'r+': (user, action, actor) ->
      role = action.k + '|' + action.v
      h.insert_in_place(user.roles, role)
    'r-': (user, action, actor) ->
      role = action.k + '|' + action.v
      h.remove_in_place(user.roles, role)
    'u+': (user, action, actor) ->
      h.insert_in_place(user.roles, 'kratos|enabled')
    'u-': (user, action, actor) ->
      user.roles = []
    'd+': (user, action, actor) ->
      path = ['data'].concat(action.k)
      value = action.v
      if not _.isObject(value) or _.isArray(value)
        throw new Error('value must be an object')
      merge_target = h.mk_objs(user, path, {})
      _.extend(merge_target, value)
a.validate_actions =
  user:
    'r+': (event, actor, old_user, new_user) -> 
            validate.add_resource_role(actor, new_user, event.k, event.v)
    'r-': (event, actor, old_user, new_user) -> 
            validate.remove_resource_role(actor, new_user, event.k, event.v)
    'u+': (event, actor, old_user, new_user) -> 
            validate.add_user(actor, old_user)
    'u-': (event, actor, old_user, new_user) -> 
            validate.remove_user(actor, user)

a.do_action = do_action(a.do_actions,
               validate._get_doc_type,
               h.sanitize_user
              )

a.validate_doc_update = validate_doc_update(
                          a.validate_actions,
                          validate._get_doc_type,
                          validate.auth.is_system_user
                        )

module.exports = a