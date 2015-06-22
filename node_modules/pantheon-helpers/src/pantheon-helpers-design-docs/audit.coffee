_ = require('underscore')

a =
  views:
    audit_by_timestamp:
      map: (doc) ->
        for entry in doc.audit
          typ = if (doc._id.indexOf('team_') == 0) then 'team' else 'user'
          out = {_id: doc._id, name: doc.name, entry: entry, type: typ}
          emit(entry.dt, out)

  lists:
    get_values: (header, req) ->
      out = []
      while(row = getRow())
        val = row.value
        out.push(val)
      return JSON.stringify(out)

  rewrites: [
    {
      from: "/audit",
      to: "/_list/get_values/audit_by_timestamp",
      query: {},
    }
  ]


  mixin: (dd) ->
    _.extend(dd.views, a.views)
    _.extend(dd.lists, a.lists)
    dd.rewrites = dd.rewrites.concat(a.rewrites)
    return dd

module.exports = a
