worker = require('pantheon-helpers').worker
_ = require('underscore')
follow = require('follow')
couchUtils = require('./couch_utils')
conf = require('./config')
validation = require('./validation')
logger = require('./loggers').worker
api = require('./api')

{getPlugins} = require('../utils')
plugins = getPlugins()
handlers = plugins.map((plugin) ->
  return {
    name: plugin.name,
    workers: plugin.workers(api, validation, couchUtils)
  }
)


orgs = conf.ORGS

# org workers
for org in orgs
  db = couchUtils.nano_system_user.use('org_' + org)
  worker.start_worker(logger,
                      db,
                      handlers,
                      validation._get_doc_type,
                      worker.getPluginHandlers,
                     )


# _users worker
db = couchUtils.nano_system_user.use('_users')
worker.start_worker(logger,
                    db,
                    handlers,
                    validation._get_doc_type,
                    worker.getPluginHandlers,
                   )
