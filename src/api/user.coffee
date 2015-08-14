users = require('./users')

user = {}

user.handleGetUser = (req, resp) ->
  users.getUser(req.couch, req.session.user).pipe(resp)

module.exports = user
