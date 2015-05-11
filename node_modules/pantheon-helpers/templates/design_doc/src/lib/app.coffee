_ = require('underscore')
actions = require('./actions')
audit = require('pantheon-helpers').design_docs.audit

dd =
  views: {}

  lists: {}

  shows: {}

  updates: {}

  rewrites: []

audit.mixin(dd)
actions.mixin(dd)

module.exports = dd
