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

v.validate_audit_entry = (actions, entry, actor, old_doc, new_doc) ->
  if entry.u != actor.name
    throw({ forbidden: 'User performing action (' + entry.u + ') does not match logged in user (' + actor.name + ').' })
  if entry.a not of actions
    throw({ forbidden: 'Invalid action: ' + entry.a + '.' })

  authorized = actions[entry.a]?(entry, actor, old_doc, new_doc) or false

  if not authorized
    throw({ unauthorized: 'You do not have the privileges necessary to perform the action.' });

v.validate_audit_entries = (actions, new_audit_entries, actor, old_doc, new_doc) ->
  ###
  actions is a hash of  {action_id: permission_function(actor, old_doc, key)}
  ###
  new_audit_entries.forEach((entry) -> v.validate_audit_entry(actions, entry, actor, old_doc, new_doc))

module.exports = v
