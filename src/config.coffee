deepExtend = require('pantheon-helpers').utils.deepExtend
path = require('path')

try
    config_secret = require('./config_secret')
catch e
    config_secret = {}

config = 
  COUCHDB:
    HOST: 'localhost'
    PORT: 5984
    HTTPS: false
    SYSTEM_USER: 'admin'
  RESOURCES:
    GH: # default plugin npm package kratos-gh
      ORG_ID: undefined # org id (integer)
      ORG_NAME: undefined # org name (string)
      TEMPLATE_REPO: undefined # fully qualified url to git repo
      ADMIN_CREDENTIALS:
        user: undefined # github username
        pass: undefined # github password
      UNMANAGED_TEAMS: []
      UNMANAGED_REPOS: []
    MOIRAI:
        URL: 'http://localhost/moirai'
        ADMIN_CREDENTIALS:
          user: undefined # moirai admin username
          pass: undefined # moirai admin password

  SECRET_KEY: undefined # secret key for hmac
  COUCH_PWD: undefined # couchdb password
  COUCH_DESIGN_DOCS_DIR: path.join(__dirname, '/design_docs')
  ORGS: []
  LOGGERS:
    WEB:
      streams: [{
        path: '/var/log/kratos/web-error.log',
        level: "error",
      },
      {
        path: '/var/log/kratos/web.log'
        level: "info",
      }]
    WORKER:
      streams: [{
        path: '/var/log/kratos/worker-error.log',
        level: "error",
      },
      {
        path: '/var/log/kratos/worker.log',
        level: "info",
      }]

deepExtend(config, config_secret)

module.exports = config
