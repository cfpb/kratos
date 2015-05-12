do_action = require('pantheon-helpers').design_docs.do_action
validate_doc_update = require('pantheon-helpers').design_docs.validate_doc_update.validate_doc_update

get_doc_type = (doc) -> throw new Error('Not Implemented: get_doc_type')

a = {}

a.do_actions = {}

a.validate_actions = {}

a.do_action = do_action(
                a.do_actions,
                get_doc_type,
              )

a.validate_doc_update = validate_doc_update(
                          a.validate_actions,
                          get_doc_type,
                        )

a.mixin = (dd) ->
  dd.validate_doc_update = a.validate_doc_update
  dd.updates.do_action = a.do_action

module.exports = a
