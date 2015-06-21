_ = require('underscore')
follow = require('follow')
utils = require('./utils')
Promise = require('promise')
logger = require('./loggers').worker
x = {}

clone = (obj) ->
  newClone = JSON.parse(JSON.stringify(obj))
  return newClone

x.get_handlers = (handlers, entry, doc_type) ->
  ###
  return a hash of {null: handler}, where handler is the handler
  for the entry/doc type combo.

  you can subclass this function to return an arbitrary 
  number of key/handler names. (see, e.g., get_resource_handlers)
  ###
  handler = handlers[doc_type]?[entry.a]
  if handler
    return {null: handler}
  else
    return {}

x.get_plugin_handlers = (handlers, entry, doc_type) ->
  ###
  return a hash of {resource: handler} for each resource that
  has specified a handler for this entry's action.
  ###
  filtered_handlers = {}
  for plugin, plugin_handlers of handlers
    handler = plugin_handlers[doc_type]?[entry.a]
    if not handler
      entry_plugin = entry.plugin or entry.resource
      if entry_plugin == plugin
        handler = plugin_handlers[doc_type]?.self?[entry.a]
      else
        handler = plugin_handlers[doc_type]?.other?[entry.a]
    if handler
      filtered_handlers[plugin] = handler
  return filtered_handlers

x.get_audit_entries_to_sync = (doc) ->
  now = +new Date()
  return _.filter(doc.audit, (entry) ->
    return not entry.synced and (
      (not entry.attempts?.length) or
      entry.attempts[0] < now
    )
  )

x.get_next_attempt_time = (now, attempts) ->
  nextInMinutes = Math.pow(2, attempts.length)
  nextInMilliseconds = nextInMinutes * 60 * 1000
  return now + nextInMilliseconds

x.update_document_with_worker_result = (doc) ->
  (result) ->
    # result.value or result.error must be a hash of {data: 'data to update', path: ['data', 'path']}
    data_path = result.value?.path or result.error?.path
    new_data = result.value?.data or result.error?.data

    if new_data and data_path
      existing_data = utils.mk_objs(doc, data_path, {})
      _.extend(existing_data, new_data)

x.update_audit_entry = (doc) ->
  (entry_results, entry_id) ->
    entry = _.findWhere(doc.audit, {id: entry_id})
    synced = _.all(entry_results, (result) -> result.state == 'resolved')
    entry.synced = entry.synced or synced
    if entry.synced
      delete entry.attempts
    else
      entry.attempts = entry.attempts or []
      entry.attempts.unshift(x.get_next_attempt_time(+new Date, entry.attempts))

    _.each(entry_results, x.update_document_with_worker_result(doc))


x.update_audit_entries = (db, doc_id, results) ->
  get_doc = Promise.denodeify(db.get).bind(db)
  insert_doc = Promise.denodeify(db.insert).bind(db)
  get_doc(doc_id).then((doc) ->
    old_doc = clone(doc)
    _.each(results, x.update_audit_entry(doc))

    if _.isEqual(old_doc, doc)
      return Promise.resolve()
    else
      insert_doc(doc).catch((err) ->
        if err.status_code == 409
          return x.update_audit_entries(db, doc_id, doc_type, results)
        else
          Promise.reject(err)
      )
  )


x.on_change = (logger, db, handlers, get_doc_type, get_handlers) ->
  return (change) ->
    doc = change.doc
    doc_type = get_doc_type(doc)
    unsynced_audit_entries = x.get_audit_entries_to_sync(doc)
    
    docLog = logger.child({docId: doc._id, rev: doc._rev})
    if not unsynced_audit_entries.length
      docLog.info({unsyncedActions: unsynced_audit_entries}, 'skip handling actions')
      return
    docLog.info({unsyncedActions: unsynced_audit_entries}, 'start handling actions')

    entry_promises = {}
    _.each(unsynced_audit_entries, (entry) ->
      entry_handlers = get_handlers(handlers, entry, doc_type)
      handler_promises = {}

      actionLog = docLog.child({actionId: entry.id, actionType: entry.a})
      actionLog.info({
        event: 'onChange',
        handlers: _.keys(entry_handlers)
      }, 'start running action handlers')

      _.each(entry_handlers, (handler, handlerName) ->
        handlerLog = actionLog.child({handlerName: handlerName})
        handler_promises[handlerName] = handler(clone(entry),
                                         clone(doc),
                                         handlerLog
                                        )
      )
      entry_promises[entry.id] = Promise.hashResolveAll(handler_promises)
    )
    Promise.hashAll(entry_promises).then((results) ->
      # results is a hash of type:
      # {entry_id: {resource: {state: "resolved|rejected", value|error: "result"}}}
      x.update_audit_entries(db, doc._id, results).then(() ->
        failed = 0
        succeeded = 0
        _.each(results, (actionResults, actionId) ->
          [resolved, rejected] = sortErrorResults(actionResults)
          actionLog = docLog.child({actionId: actionId})
          if _.isEmpty(rejected)
            actionLog.info({succeeded: resolved}, 'finish running handlers')
            succeeded++
          else
            actionLog.error({failed: rejected, succeeded: resolved}, 'finish running handlers')
            failed++
        )
        if failed
          docLog.error({succeeded: succeeded, failed: failed}, 'finish handling actions')
        else
          docLog.info({succeeded: succeeded}, 'finish handling actions')
      )
    ).catch((err) ->
      docLog.error({error: err}, 'finish handling actions')
    ).then(() ->
      Promise.resolve()
    )

x.setInterval = setInterval
x.processFailures = (db, onChange) ->
  () ->
    db.view(
      'pantheon', 'failures_by_retry_date',
      {endkey:+new Date(), include_docs: true},
      'promise'
    ).then((resp) ->
      Promise.all(resp.rows.map(onChange))
    )

x.watchForFailures = (db, onChange, period) ->
  interval = x.setInterval(x.processFailures(db, onChange), period)
  return interval

x.start_worker = (logger, db, handlers, get_doc_type, get_handlers=x.get_handlers) ->
  ###
  start a worker that watches a db for changes and calls the appropriate handlers.
  it also looks in the database every two minutes for failed syncs that are ready for a retry.
  db: the nano database to watch
  handlers: a hash of handlers. Each handler should handle a different action.
  get_doc_type: a function that returns the document type. this can be used to look up the appropriate handler.
  get_handlers: a function that returns the worker handlers to handle an unhandled event.
  ###
  opts = 
    db: db.config.url + '/' + db.config.db
    include_docs: true

  feed = new follow.Feed(opts);

  feed.filter = (doc, req) ->
    if doc._deleted
      return false
    else
      return true

  onChange = x.on_change(logger, db, handlers, get_doc_type, get_handlers)
  feed.on('change', onChange)

  feed.on('error', (err) ->
    console.log(err)
  )
  logger.info('worker started')
  feed.follow()

  MINUTES = 60 * 1000
  interval = x.watchForFailures(db, onChange, 2 * MINUTES)
  return {feed: feed, interval: interval}

sortErrorResults = (actionResults) ->
  resolved = {}
  rejected = {}
  _.each(actionResults, (resourceResult, resourceName) ->
    if resourceResult.state == 'resolved'
      resolved[resourceName] = resourceResult.value or null
    else
      rejected[resourceName] = resourceResult.error or null
  )
  return [resolved, rejected]

module.exports = x
