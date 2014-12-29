try
  _ = require('underscore')
catch err
  _ = require('lib/underscore')

v = {}

v.is_super_admin = (user) ->
  return user.name == 'admin'

v.get_new_audit_entries = (new_doc, old_doc) ->
  new_log = new_doc.audit
  old_log = if old_doc then old_doc.audit else []
  new_entries = new_log.slice(old_log.length)
  return new_entries

v.validate_audit_entry = (actions, entry, user, old_doc) ->
  if entry.u != user.name
    throw({ forbidden: 'User performing action (' + entry.u + ') does not match logged in user (' + user.name + ').' })
  if entry.a not of actions
    throw({ forbidden: 'Invalid action: ' + entry.a + '.' })

  authorized = actions[entry.a]?(entry, user, old_doc) or false

  if not authorized
    throw({ unauthorized: 'You do not have the privileges necessary to perform the action.' });

v.validate_audit_entries = (actions, new_audit_entries, user, old_doc) ->
  ###
  actions is a hash of  {action_id: permission_function(user, old_doc, key)}
  ###
  new_audit_entries.forEach((entry) -> v.validate_audit_entry(actions, entry, user, old_doc))

module.exports = v
