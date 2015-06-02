worker = require('pantheon-helpers').worker
_ = require('underscore')
follow = require('follow')
couch_utils = require('./couch_utils')
logger = require('./loggers').worker
handlers = {
}

get_doc_type = (doc) ->
  throw new Error('not implemented')

# _users worker
db = couch_utils.nano_system_user.use('db_name')
worker.start_worker(logger,
                    db,
                    handlers,
                    get_doc_type,
                   )
