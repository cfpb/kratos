_ = require('underscore')
uuid = require('node-uuid')

module.exports = (dbClient, designDocName, docId, action, callback) ->
  ###
  perform an action defined in a design doc on a document in a database
  dbClient - a nano or nano-pramise client bound to a database
  designDocName - the name of the designDoc that defines the action
  doc - docId of the document on which to perform the action. `null` if new document
  action - a hash defining the action. must contain `{a: 'actionId'}`; may contain uuid, `id`.
  ###
  _.defaults(action, {id: uuid.v4()})
  return dbClient.atomic(designDocName, 'do_action', docId, action, callback)
