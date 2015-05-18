_deepExtend = (target, source) ->
  ###
  recursively extend an object.
  does not recurse into arrays
  ###
  for k, sv of source
    tv = target[k]
    if tv instanceof Array
      target[k] = sv
    else if typeof(tv) == 'object' and typeof(sv) == 'object'
      target[k] = _deepExtend(tv, sv)
    else
      target[k] = sv
  return target

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
    GH:
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
  ORGS: []


_deepExtend(config, config_secret)

module.exports = config
