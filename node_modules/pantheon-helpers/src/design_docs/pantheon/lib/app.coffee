_ = require('underscore')


dd =
  views:
    failures_by_retry_date:
      map: (doc) ->
        now = +new Date()
        nextAttemptTime = 1e+100
        for entry in (doc.audit or [])
          if entry.attempts?[0] < nextAttemptTime
            nextAttemptTime = entry.attempts?[0]
        if nextAttemptTime < 1e+100
            emit(nextAttemptTime)
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

  shows: {}

  updates: {}

if typeof(emit) == 'undefined'
  dd.emitted = []
  emit = (k, v) -> dd.emitted.push([k, v])

module.exports = dd
