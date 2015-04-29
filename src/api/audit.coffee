couch_utils = require('../couch_utils')
conf = require('../config')
orgs = conf.ORGS
_ = require('underscore')
Promise = require('pantheon-helpers').promise

audit = {}

audit.getAudit = (startDate, endDate) ->
  # return promise only
  opts = {
    path: '/audit'
    qs: {}
  }

  if startDate? and not isNaN(startDate)
    opts.qs.startkey = startDate
  if endDate? and not isNaN(endDate)
    opts.qs.endkey = endDate
  dbs = orgs.map((org) -> couch_utils.nano_system_user.use('org_' + org))
  dbs.push(couch_utils.nano_system_user.use('_users'))

  auditPromises = dbs.map((db) ->
    couch_utils.rewrite(db, 'base', opts, 'promise')
  )

  Promise.all(auditPromises).then((resps) ->
    entries = _.flatten(resps, true)
    entries = _.sortBy(entries, (entry) -> return entry.entry.dt)    
    Promise.resolve(entries)
  )

audit.handleGetAudit = (req, resp) ->
  startDate = parseInt(req.query.start)
  endDate = parseInt(req.query.end)
  audit.getAudit(startDate, endDate).then((entries) ->
    resp.send(JSON.stringify(entries))
  (err) ->
    console.error('handle_get_audit', err)
  ) resp.status(500).send(JSON.stringify({error: 'internal error', msg: 'internal error'}))

module.exports = audit
