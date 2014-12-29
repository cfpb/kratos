couch_utils = require('./couch_utils')
auth = require('basic-auth')
conf = require('./config')

module.exports = 
  auth_hack: (req, resp, next) ->
    if req.headers.cookie
      req.headers.cookie = req.headers.cookie.replace(/express_sess="(.*?)"/, 'express_sess=$1')
    next()
  couch: (req, resp, next) ->
    # look for admin credentials in basic auth, and if valid, login user as admin.
    credentials = auth(req);
    if credentials and credentials.name == 'admin' and credentials.pass = conf.COUCH_PWD
        req.session.user = 'admin'

    # ensure that there is a logged in user.
    if not req.session.user
      return resp.status(401).end(JSON.stringify({error: "unauthorized", msg: "You are not logged in."}))

    # add to the request a couch client tied to the logged in user
    req.couch = couch_utils.nano_user(req.session.user)
    next()