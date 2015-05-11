_ = require('underscore')
follow = require('follow')
utils = require('./utils')
Promise = require('promise')

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


x.get_unsynced_audit_entries = (doc) ->
  return _.filter(doc.audit, (entry) -> return not entry.synced)


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


x.on_change = (db, handlers, get_doc_type, get_handlers) ->
  return (change) ->
    doc = change.doc
    doc_type = get_doc_type(doc)
    unsynced_audit_entries = x.get_unsynced_audit_entries(doc)

    entry_promises = {}
    _.each(unsynced_audit_entries, (entry) ->
      entry_handlers = get_handlers(handlers, entry, doc_type)
      handler_promises = {}
      _.each(entry_handlers, (handler, rsrc) ->
        handler_promises[rsrc] = handler(clone(entry), clone(doc))
      )
      entry_promises[entry.id] = Promise.hashResolveAll(handler_promises)
    )
    Promise.hashAll(entry_promises).then((results) ->
      # results is a hash of type:
      # {entry_id: {resource: {state: "resolved|rejected", value|error: "result"}}}
      x.update_audit_entries(db, doc._id, results)
      if _.find(results, (result) -> _.findWhere(result, {state: 'rejected'}))
        console.log('ERR', change.doc, unsynced_audit_entries, results)
    ).catch((err) ->
      console.log('ERR', err)
    )


x.start_worker = (db, handlers, get_doc_type, get_handlers=x.get_handlers) ->
  ###
  start a worker that watches a db for changes and calls the appropriate handlers.
  db: the nano database to watch
  handlers: a hash of handlers. Each handler should handle a different action.
  get_handler_data_path: a function that return a path array into the document where data returned by the handler should be stored.
  get_doc_type: a function that returns the document type. this can be used to look up the appropriate handler.
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

  feed.on 'change', x.on_change(db, handlers, get_doc_type, get_handlers)

  feed.on 'error', (err) ->
    console.log(err)

  feed.follow()
  return feed


module.exports = x
