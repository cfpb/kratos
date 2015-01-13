_ = require('underscore')
follow = require('follow')
couch_utils = require('./couch_utils')
conf = require('./config')
team_validation = require('./design_docs/org/lib/validation')
utils = require('./utils')
wh = require('./worker_helpers')

orgs = conf.ORGS

resources = {
  gh: require('./workers/gh').handlers,
}

get_unsynced_audit_entries = (doc) ->
  return _.filter(doc, (entry) -> return not entry.synced)

update_audit_entry = (old_entry, new_synced_state) ->
  if old_entry.synced
    return false
  if old_entry.synced == new_synced_state
    return false
  old_entry.synced = new_synced_state
  return true

get_new_synced_state = (old_entry, new_synced_state) ->
  if old_entry.synced
    return old_entry.synced

update_audit_entries = (db, team_id, sync_status, resource_updates, callback) ->
  await db.get(team_id, defer(err, team))
  return callback(err) if err

  dirty = false
  for entry_id, new_synced of sync_status
    entry = _.findWhere(team.audit, {id: entry_id})
    old_synced = entry.synced
    final_synced = old_synced or new_synced
    if final_synced != old_synced
      dirty = true
      entry.synced = final_synced

  for entry_id, updates of resource_updates
    for resource, update of updates
      if update
        dirty = true
        old_data = utils.mk_objs(team, ['rsrcs', resource, 'data'], {})
        _.extend(old_data, update)

  if dirty
    await db.insert(team, defer(err, resp))
    if err?.status_code == 409
      return update_audit_entries(db, team_id, entries, errs, callback)
    else
      return callback(err)
  return callback()


for org in orgs
  db = couch_utils.nano_admin.use('org_' + org)
  opts = 
    db: db.config.url + '/' + db.config.db
    include_docs: true

  feed = new follow.Feed(opts);

  feed.filter = (doc, req) ->
    if not team_validation.is_team(doc)
      return false
    else
      return true

  feed.on 'change', (change) ->
    console.log('handling change')
    doc = change.doc
    unsynced_audit_entries = get_unsynced_audit_entries(doc.audit)
    errs = {}
    resource_updates = {}
    await
      for entry in unsynced_audit_entries
        errs[entry.id] = {}
        resource_updates[entry.id] = {}
        handlers = wh.get_handlers(entry, resources)
        for resource, handler of handlers
          handler(entry, doc, defer(errs[entry.id][resource], resource_updates[entry.id][resource]))            

    sync_status = {}
    _.each(errs, (rsrc_errs, entry_id) ->
      success = not Boolean(_.find(rsrc_errs, (err) -> return err))
      console.log('ENTRY ERROR:', errs) if not success
      sync_status[entry_id] = success
    )
    await update_audit_entries(db, doc._id, sync_status, resource_updates, defer(err))
    if err then console.log(err)
    # TODO handle err

  feed.on 'error', (err) ->
    console.log(err)

  feed.follow()

