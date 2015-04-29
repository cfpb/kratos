_ = require('underscore')
h = require('./helpers')
validate = require('./validation/index')
actions = require('./actions')
audit = require('pantheon-helpers').design_docs.audit

auth = validate.auth

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
      out = []
      while(row = getRow())
        doc = row.doc
        continue if not validate._is_team(doc)
        team = h.add_team_perms(doc, req.userCtx)
        out.push(team)
      return JSON.stringify(out)
    get_team_roles: (header, req) ->
      out = []
      while(row = getRow())
        team = row.doc
        role = row.key[1]
        out.push({team: team, role: role})
      return JSON.stringify(out)
  shows:
    get_team: (doc, req) ->
      team = h.add_team_perms(doc, req.userCtx)
      return {body: JSON.stringify(team), "headers" : {"Content-Type" : "application/json"}}

  validate_doc_update: actions.validate_doc_update

  updates:
    do_action: actions.do_action

  rewrites: [
    {
      from: "/teams",
      to: "/_list/get_teams/_all_docs",
      method: 'GET',
      query: {include_docs: 'true'},
    },
    {
      from: "/teams/:team_id",
      to: "/_show/get_team/:team_id",
      query: {},
    }
  ]

audit.mixin(dd)

module.exports = dd
