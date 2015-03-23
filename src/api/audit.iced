couch_utils = require('../couch_utils')
conf = require('../config')
orgs = conf.ORGS
_ = require('underscore')

audit = {}

audit.get_audit = (start_date, end_date, callback) ->
  opts = {
    path: '/audit'
    qs: {}
  }

  if start_date? and not isNaN(start_date)
    opts.qs.startkey = start_date
  if end_date? and not isNaN(end_date)
    opts.qs.endkey = end_date
  dbs = orgs.map((org) -> couch_utils.nano_admin.use('org_' + org))
  dbs.push(couch_utils.nano_admin.use('_users'))
  errs = []
  resps = []
  await
    for db, i in dbs
      couch_utils.rewrite(db, 'base', opts, defer(errs[i], resps[i]))
  errs = _.compact(errs)
  if errs.length
    return callback(errs)

  entries = _.flatten(resps, true)
  entries = _.sortBy(entries, (entry) -> return entry.entry.dt) 
  return callback(null, entries)

audit.handle_get_audit = (req, resp) ->
  start_date = parseInt(req.query.start)
  end_date = parseInt(req.query.end)
  await audit.get_audit(start_date, end_date, defer(err, entries))
  if err
    console.log('handle_get_audit', err)
    return resp.status(500).send(JSON.stringify({error: 'internal error', msg: 'internal error'}))
  return resp.send(JSON.stringify(entries))

module.exports = audit
