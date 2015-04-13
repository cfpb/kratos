users = require('./users')

user = {}

user.handle_get_user = (req, resp) ->
  users.get_user(req.session.user).pipe(resp)

module.exports = user
