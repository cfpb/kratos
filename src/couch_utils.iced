# copyright David Greisen 2014 - licensed under Apache License v2.0

fs = require('fs')
path = require('path')
_ = require('underscore')
conf = require('./config')
{exec} = require 'child_process'

x = {}

get_couchdb_url = (user) ->
  out = if conf.COUCHDB.HTTPS then 'https' else 'http'
  out += '://'
  out += user + ':' + conf.COUCH_PWD + '@'
  out += conf.COUCHDB.HOST + ':' + conf.COUCHDB.PORT

x.nano_user = (user) ->
  return require('nano')(get_couchdb_url(user))
x.nano_admin = nano_admin = x.nano_user('admin')
x.ensure_db = (db, method, args...) ->
  ###
  call the method against the db with the given args.
  if it doesn't exist,
  create the db and call again. return result
  ###
  callback = null
  if (_.isFunction(_.last(args)))
    callback = args.pop()
  await
    db[method].apply(db, args.concat([defer(err, resp)]))
  if err?.message == 'no_db_file'
    await nano_admin.db.create(db.config.db, defer(err, resp))
    if err
      return callback?(err, resp)
    db_name = db.config.db
    design_docs = require('./design_docs/' + db_name.split('_')[0])
    await x.sync_design_docs(db_name, design_docs, defer(err, resp))
    if err
      return callback?(err, resp)
    return db[method].apply(db, args.concat([callback]))
  else
    return callback?(err, resp)

x.force_get = (db, doc_id, callback) ->
  ###
  ensure there is a database, return an empty dict if doc doesn't exist
  ###
  await x.ensure_db(db, 'get', doc_id, defer(err, doc))
  if err?.status_code == 404
    doc = {}
    err = null
  return callback(err, doc)

x.update = (db, update_data, doc_id, callback=null) ->
  await x.force_get(db, doc_id, defer(err, doc))
  if err
    return callback?(err, doc)
  _.extend(doc, update_data)
  await db.insert(doc, doc_id, defer(err, doc))
  if err?.status_code == 409
    return x.update(db, update_data, doc_id, callback)
  return callback?(err, doc)

x.sync_all_db_design_docs = (db_type) ->
  """
  does not remove deleted design docs
  updates the design doc - does not replace
  db_type - the type of database - updates all dbs whos names start with db_type
  """
  design_docs = require('./design_docs/' + db_type)
  await nano_admin.db.list(defer(err, all_dbs))
  dbs = _.filter(all_dbs, (db) -> db.indexOf(db_type) == 0)
  errs = []
  console.log(dbs)
  await
    for db_name, i in dbs
      x.sync_design_docs(db_name, design_docs, defer(errs[i]))
  errs = _.compact(errs)
  if errs.length
    console.log("ERROR": errs)
  else
    console.log('completed without errors')

x.sync_design_docs = (db_name, design_doc_names, callback) ->
  errors = []
  await
    for name, i in design_doc_names
      url = get_couchdb_url('admin') + '/' + db_name
      cmd = 'kanso push ' + name + ' ' + url
      console.log(cmd)
      wd = path.join(path.dirname(fs.realpathSync(__filename)), './design_docs')
      cp = exec(cmd, {cwd: wd}, defer(errors[i]))
      cp.stdout.pipe(process.stdout)
      cp.stderr.pipe(process.stderr)

  errors = _.compact(errors)
  if errors.length
    return callback(errors)
  else
    return callback()

x.merge_old_and_new_docs = (old_docs, new_docs, should_update) ->
  out = []
  for old_doc, i in old_docs
    new_doc = new_docs[i]
    if !old_doc.doc?
      out.push(new_doc)
    else if not should_update? or should_update(old_doc, new_doc)
      updated_doc = _.extend(old_doc.doc, new_doc)
      out.push(updated_doc)
  return out

x.upsert = (db, new_docs, should_update, callback) ->
  # should_update: function returning true if the doc should be updated
  ids = _.pluck(new_docs, '_id')
  await x.ensure_db(db, 'fetch', {keys: ids}, defer(err, old_docs))
  if err
    return callback(err)
  bulk_data = x.merge_old_and_new_docs(old_docs.rows, new_docs, should_update)
  await db.bulk({docs: bulk_data}, defer(err, bulk_resp))
  if err
    return callback(err)
  errored = []
  conflicted = []
  for doc in bulk_resp
    if doc.error == 'conflict'
      i = ids.indexOf(doc.id)
      new_doc = new_docs[i]
      conflicted.push(new_doc)
    else if doc.error
      errored.push(doc)
  if errored.length
    return callback({bulk_errors: errored, bulk_conflicted: conflicted})
  else if conflicted.length
    return x.upsert(db, conflicted, should_update, callback)
  else
    return callback(null, bulk_resp)

x.get_uuid = (callback) ->
  await nano_admin.request({db: "_uuids"}, defer(err, resp))
  if err
    return callback(err, resp)
  return callback(null, resp.uuids[0])

x.get_uuids = (count, callback) ->
  # params is not working for some reason so hacked around it with path
  await nano_admin.request({db: "_uuids", path: '?count=' + count}, defer(err, resp))
  if err
    return callback(err, resp)
  return callback(null, resp.uuids)

x.rewrite = (db, design_doc, path, callback) ->
  db_name = db.config.db
  nano = require('nano')(db.config.url)
  return nano.request({
    db: db_name,
    path: '/_design/' + design_doc + '/_rewrite' + path,
  }, callback)

# x.add_user = (db, username, password, callback)
#   if _.isFunction(password) and not callback?
#     callback = password
#     password = null

#   id = "org.couchdb.user:" + username
#   user_doc =
#     "_id": id
#     "name": username
#     "roles": []
#     "type": "user"
#   if password
#     user_doc["password"] = password

#   await db.insert(user_doc, id, defer(err, user_doc))
#   if err
#     callback?(err)


module.exports = x