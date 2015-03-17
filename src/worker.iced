worker = require('pantheon-helpers/lib/worker')
_ = require('underscore')
follow = require('follow')
couch_utils = require('./couch_utils')
conf = require('./config')
validate = require('./validation/validate')

orgs = conf.ORGS

handlers = {
  gh: require('./workers/gh').handlers,
}

get_handler_data_path = (doc_type, rsrc) ->
  return {
    'user': ['rsrcs', rsrc],
    'team': ['rsrcs', rsrc, 'data'],
  }[doc_type]

# org workers
for org in orgs
  db = couch_utils.nano_admin.use('org_' + org)
  worker.start_worker(db,
                      handlers,
                      get_handler_data_path,
                      validate._get_doc_type
                     )


# _users worker
db = couch_utils.nano_admin.use('_users')
worker.start_worker(db,
                    handlers,
                    get_handler_data_path,
                    validate._get_doc_type
                   )
