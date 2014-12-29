couch_utils = require('../couch_utils')

user = {}

user_db = couch_utils.nano_admin.use('_users')

user.get_user = (req, resp) ->
  couch_utils.rewrite(user_db, 'base', '/users/org.couchdb.user:' + req.session.user).pipe(resp)

module.exports = user
