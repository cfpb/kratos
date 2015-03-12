_ = require('underscore')
follow = require('follow')
couch_utils = require('./couch_utils')
conf = require('./config')
validation = {
  team: require('./design_docs/org/lib/validation')
  user: require('./design_docs/_users/lib/validation')
}
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

update_audit_entries = (db, doc_id, sync_status, resource_updates, callback) ->
  await db.get(doc_id, defer(err, doc))
  return callback(err) if err

  dirty = false
  for entry_id, new_synced of sync_status
    entry = _.findWhere(doc.audit, {id: entry_id})
    old_synced = entry.synced
    final_synced = old_synced or new_synced
    if final_synced != old_synced
      dirty = true
      entry.synced = final_synced

  for entry_id, updates of resource_updates
    for resource, update of updates
      if update
        dirty = true
        if validation.team.is_team(doc)
          old_data = utils.mk_objs(doc, ['rsrcs', resource, 'data'], {})
        else if validation.user.is_user(doc)
          old_data = utils.mk_objs(doc, ['rsrcs', resource], {})
        else
          old_data = {}
        _.extend(old_data, update)

  if dirty
    await db.insert(doc, defer(err, resp))
    if err?.status_code == 409
      return update_audit_entries(db, doc_id, entries, errs, callback)
    else
      return callback(err)
  return callback()


start_worker = (db, db_type) ->
  opts = 
    db: db.config.url + '/' + db.config.db
    include_docs: true

  feed = new follow.Feed(opts);

  feed.filter = (doc, req) ->
    if doc._deleted
      return false
    # if not a user/team document, skip
    else if not validation[db_type]['is_' + db_type](doc)
      return false
    else
      return true

  feed.on 'change', (change) ->
    console.log('handling ' + db_type + ' change')
    doc = change.doc
    unsynced_audit_entries = get_unsynced_audit_entries(doc.audit)
    errs = {}
    resource_updates = {}
    await
      for entry in unsynced_audit_entries
        errs[entry.id] = {}
        resource_updates[entry.id] = {}
        handlers = wh.get_handlers(entry, db_type, resources)
        for resource, handler of handlers
          handler(entry, doc).nodeify(defer(errs[entry.id][resource], resource_updates[entry.id][resource]))

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


# org workers
for org in orgs
  db = couch_utils.nano_admin.use('org_' + org)
  start_worker(db, 'team')

# _users worker
db = couch_utils.nano_admin.use('_users')
start_worker(db, 'user')
