try
  _ = require('underscore')
catch err
  _ = require('lib/underscore')

auth = require('./auth/auth')
v = {}

v.is_team = (doc) ->
  return doc._id.indexOf('team_') == 0

v.is_super_admin = (user) ->
  return user.name == 'admin'

v.get_new_audit_entries = (new_doc, old_doc) ->
  new_log = new_doc.audit
  old_log = if old_doc then old_doc.audit else []
  new_entries = new_log.slice(old_log.length)
  return new_entries

v.validate_audit_entry = (entry, user, team) ->
  if entry.u != user.name
    throw({ forbidden: 'User performing action (' + entry.u + ') does not match logged in user (' + user.username + ').' })
  if entry.a == 't+'
    authorized = auth.kratos.add_team(user)
  else if entry.a == 'u+'
    authorized = auth.kratos.add_team_member(user, team, entry.k)
  else if entry.a == 'u-'
    authorized = auth.kratos.remove_team_member(user, team, entry.k)
  else if entry.a == 'a+'
    authorized = auth[entry.k]?.add_team_asset(user, team) or false
  else if entry.a == 'a-'
    authorized = auth[entry.k]?.remove_team_asset(user, team) or false
  else
    throw({ forbidden: 'Invalid action: ' + entry.a + '.' })

  if not authorized
    throw({ unauthorized: 'You do not have the privileges necessary to perform the action.' });

v.validate_audit_entries = (new_audit_entries, user, team) ->
  new_audit_entries.forEach((entry) -> v.validate_audit_entry(entry, user, team))

v.validate_doc_update = (new_doc, old_doc, user_ctx, sec_obj) ->
  if not v.is_team(new_doc) or v.is_super_admin(user_ctx)
    return

  if not old_doc
    # need to validate doc creation
    return 
  if new_doc._deleted
    # need to validate doc deletion
    return

  new_audit_entries = v.get_new_audit_entries(new_doc, old_doc)
  if not new_audit_entries.length
    return

  v.validate_audit_entries(new_audit_entries, user_ctx, old_doc)

module.exports = v
