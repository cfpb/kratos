basic_auth = require('basic-auth')


module.exports = 

  auth: (conf) ->
    SYSTEM_USER = conf.COUCHDB.SYSTEM_USER
    (req, resp, next) ->
      # look for admin credentials in basic auth, and if valid, login user as admin.
      credentials = basic_auth(req)
      if conf.DEV or
         (
          credentials and
          credentials.name == SYSTEM_USER and
          credentials.pass == conf.COUCH_PWD
         )
        req.session or= {}
        req.session.user = SYSTEM_USER
        return next()
      else
        return resp.status(401).end(JSON.stringify({error: "unauthorized", msg: "You are not authorized."}))

  couch: (couch_utils) ->
    (req, resp, next) ->
      # add to the request a couch client tied to the logged in user
      req.couch = couch_utils.nano_user(req.session.user)
      return next()
