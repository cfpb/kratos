auth =
  # pull out just the needed methods from validation/auth.
  _is_team: (doc) ->
    return doc._id.indexOf('team_') == 0

module.exports = auth
