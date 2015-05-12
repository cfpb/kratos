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

_.extend(config, config_secret)

module.exports = config
