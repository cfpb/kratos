validation = require('./validation/validate')
vh = require('./validation_helpers')

v = {}

v.is_team = (doc) ->
  return doc._id.indexOf('team_') == 0

v.validate_doc_update = (new_doc, old_doc, user_ctx, sec_obj) ->
  if not v.is_team(new_doc) or vh.is_super_admin(user_ctx)
    return

  new_audit_entries = vh.get_new_audit_entries(new_doc, old_doc)
  if not new_audit_entries.length
    return

  actions = validation.entries.teams

  vh.validate_audit_entries(actions, new_audit_entries,
                            user_ctx, old_doc, new_doc)

module.exports = v
