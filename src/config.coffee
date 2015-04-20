_ = require('underscore')
config_secret = require('./config_secret')

config = 
  COUCHDB:
    HOST: 'localhost'
    PORT: 5984
    HTTPS: false
    SYSTEM_USER: 'admin'


_.extend(config, config_secret)

module.exports = config
