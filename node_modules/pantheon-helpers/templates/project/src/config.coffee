_ = require('underscore')
config_secret = require('./config_secret')

config = 
  COUCHDB:
    HOST: 'localhost'
    PORT: 5984
    HTTPS: false
    SYSTEM_USER: 'the username used by your microservice to access CouchDB'
  APP:
    PORT: 5000
  LOGGERS:
    WEB:
      streams: [{
        stream: process.stderr,
        level: "error"
      },
      {
        stream: process.stdout,
        level: "info"
      }]
    WORKER:
      streams: [{
        stream: process.stderr,
        level: "error"
      },
      {
        stream: process.stdout,
        level: "info"
      }]

_.extend(config, config_secret)

module.exports = config
