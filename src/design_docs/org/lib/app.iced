_ = require('./underscore')
h = require('./helpers')
validation = require('./validation/validate')
actions = require('./actions')
audit = require('./shared/audit')

dd =
  views: {}

  lists:
    get_teams: (header, req) ->
      out = []
      while(row = getRow())
        doc = row.doc
        continue if not validation._is_team(doc)
        team = h.add_team_perms(doc, req.userCtx)
        out.push(team)
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
