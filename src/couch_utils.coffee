conf = require('./config')
couch_utils = require('pantheon-helpers').couch_utils(conf)
Promise = require('pantheon-helpers').promise
_ = require('underscore')

couch_utils.map = (db, fn) ->
  db.list({include_docs: true}, 'promise').then((docs) ->
    old_docs = JSON.parse(JSON.stringify(docs.rows))

    new_docs = docs.rows.map((row) -> 
      if row.doc._id.indexOf('_design') == 0
        return row.doc
      else
        return fn(row.doc))
    docs_to_save = []
    for old_doc, i in old_docs
      new_doc = new_docs[i]
      if not _.isEqual(old_doc, new_doc)
        docs_to_save.push(new_doc)
    if docs_to_save.length
      return db.bulk({docs: docs_to_save}, 'promise')
    else
      return Promise.resolve('Nothing to Do')
  )
couch_utils.delete_all = (db) ->
  couch_utils.map(db, (doc) -> 
    doc._deleted = true
    return doc
  )

module.exports = couch_utils
