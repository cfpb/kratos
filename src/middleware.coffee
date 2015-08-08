couchUtils = require('./couch_utils')
basic_auth = require('basic-auth')
auth = require('./validation').auth
conf = require('./config')
utils = require('./utils')

middleware = require('pantheon-helpers').middleware

middleware.systemAuth = middleware.systemAuth(conf)
middleware.couch = middleware.couch(couchUtils)

middleware.authHack = (req, resp, next) ->
    if req.headers.cookie
      req.headers.cookie = req.headers.cookie.replace(/express_sess="(.*?)"/, 'express_sess=$1')
    next()

middleware.ensureActive = (req, resp, next) ->
  utils.getActor(couchUtils, req.session.user).then((user) ->
    if not auth.is_active_user(user)
      req.session.user = null
      return resp.status(401).end(JSON.stringify({error: "unauthorized", msg: "Account disabled. Ask administrator to re-enable."}))
    else
      return next()
  (err) ->
    return resp.status(401).end(JSON.stringify({error: req.session.user, msg: err}))
  )

module.exports = middleware