couch_utils = require('./couch_utils')
basic_auth = require('basic-auth')
auth = require('./validation').auth
conf = require('./config')
users = require('./api/users')

module.exports = 
  auth_hack: (req, resp, next) ->
    if req.headers.cookie
      req.headers.cookie = req.headers.cookie.replace(/express_sess="(.*?)"/, 'express_sess=$1')
    next()
  couch: (req, resp, next) ->
    # look for admin credentials in basic auth, and if valid, login user as admin.
    credentials = basic_auth(req);
    if credentials and credentials.name == 'admin' and credentials.pass = conf.COUCH_PWD
        req.session.user = 'admin'
    # add to the request a couch client tied to the logged in user
    req.couch = couch_utils.nano_user(req.session.user)

    if req.session.user == 'admin'
      return next()

    # ensure that there is a logged in user.
    if not req.session.user
      return resp.status(401).end(JSON.stringify({error: "unauthorized", msg: "You are not logged in."}))

    users.get_user(req.session.user, 'promise').then((user) ->
      if not auth.is_active_user(user)
        return resp.status(401).end(JSON.stringify({error: "unauthorized", msg: "You are not logged in."}))
      else
        return next()      
    (err) ->
      return resp.status(401).end(JSON.stringify({error: req.session.user, msg: err}))
    )
