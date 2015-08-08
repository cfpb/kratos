_ = require('underscore')
shared = require('./shared')
helpers = require('pantheon-helpers').design_docs.helpers(shared)

dd =
  views:
    by_role:
      map: (doc) ->
        auth = require('views/lib/auth')
        if not auth._is_team(doc)
          return
        team_id = doc._id.slice(5)
        for role_name, role_data of doc.roles
          for user_id in (role_data.members or [])
            emit([user_id, role_name, team_id])
  lists:
    get_teams: (header, req) ->
      helpers.lists.get_prepped_of_type(getRow, start, send, 'team', header, req)

    get_team_roles: (header, req) ->
      rowTransform = (row) -> {team: row.doc, role: row.key[1]}
      helpers.sendNakedList(getRow, start, send, rowTransform)

  shows: {}

  rewrites: [
    {
      from: "/teams",
      to: "/_list/get_teams/_all_docs",
      method: 'GET',
      query: {include_docs: 'true'},
    },
  ]

module.exports = dd
