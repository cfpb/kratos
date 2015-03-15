try
  _ = require('underscore')
catch err
  _ = require('lib/underscore')

s = {
  views: {},
  lists: {},
  shows: {},
  rewrites: {},
}
s.views.audit_by_date = 
  map: (doc) ->
    for entry in doc.audit
      dt = new Date(entry.dt)
      typ = if (doc._id.indexOf('team_') == 0) then 'team' else 'user'
      out = {_id: doc._id, name: doc.name, entry: entry, type: typ}
      emit([dt.getYear() + 1900, dt.getMonth() + 1, dt.getDate(), dt.getHours(), dt.getMinutes(), dt.getSeconds(), dt.getMilliseconds()], out)

s.views.audit_by_timestamp = 
  map: (doc) ->
    for entry in doc.audit
      typ = if (doc._id.indexOf('team_') == 0) then 'team' else 'user'
      out = {_id: doc._id, name: doc.name, entry: entry, type: typ}
      emit(entry.dt, out)

s.lists.get_values = (header, req) ->
  out = []
  while(row = getRow())
    val = row.value
    out.push(val)
  return JSON.stringify(out)

s.rewrites.audit = {
  from: "/audit",
  to: "/_list/get_values/audit_by_timestamp",
  query: {},
}

module.exports = s
