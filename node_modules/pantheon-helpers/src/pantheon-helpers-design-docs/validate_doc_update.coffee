_ = require('underscore')

v =
  validate_doc_update: (validation_fns, get_doc_type, should_skip_validation_for_user) ->
    should_skip_validation_for_user or= () -> false
    return (new_doc, old_doc, user_ctx, sec_obj) ->
      doc_type = get_doc_type(old_doc or new_doc)
      actions = validation_fns[doc_type]
      new_audit_entries = v.get_new_audit_entries(new_doc, old_doc)

      if should_skip_validation_for_user(user_ctx) or
         not actions or
         not new_audit_entries.length
        return

      v.validate_audit_entries(actions, new_audit_entries,
                                      user_ctx, old_doc, new_doc)

  get_new_audit_entries: (new_doc, old_doc) ->
    new_log = new_doc.audit or []
    old_log = if old_doc then old_doc.audit else []
    new_entries = new_log.slice(old_log.length)
    if not new_entries.length
      return new_entries
    old_entries = new_log.slice(0, old_log.length)
    if not _.isEqual(old_log, old_entries)
      throw({ forbidden: 'Entries are immutable. original entries: ' + JSON.stringify(old_log) + '; modified entries: ' + JSON.stringify(old_entries) + '.' })
    return new_entries

  validate_audit_entries: (actions, new_audit_entries, actor, old_doc, new_doc) ->
    new_audit_entries.forEach((entry) -> v.validate_audit_entry(actions, entry, actor, old_doc, new_doc))

  validate_audit_entry: (actions, entry, actor, old_doc, new_doc) ->
    if entry.u != actor.name
      throw({ forbidden: 'User performing action (' + entry.u + ') does not match logged in user (' + actor.name + ').' })
    if entry.a not of actions
      throw({ forbidden: 'Invalid action: ' + entry.a + '.' })

    try
      authorized = actions[entry.a](entry, actor, old_doc, new_doc) or false
    catch e
      if e.state == 'unauthorized'
        throw({ unauthorized: e.err })
      else
        throw({ forbidden: e.err })      

module.exports = v
