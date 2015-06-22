_ = require('underscore')

module.exports = (action_handlers, get_doc_type, prep_doc) ->
  (doc, req) ->
    action = JSON.parse(req.body)
    action_name = action.a
    actor = req.userCtx
    if doc
      doc_type = get_doc_type(doc)
    else
      doc_type = 'create'
    action_handler = action_handlers[doc_type]?[action_name]

    if not action_handler
      error_msg = 'invalid action "' + action_name + '" for doc type "' + doc_type + '".'
      return [null, {code: 403, body: JSON.stringify({"status": "error", "msg": error_msg})}]

    doc or= {_id: req.uuid, audit: []}
    old_doc = JSON.parse(JSON.stringify(doc)) # clone original to check if change

    try
      action_handler(doc, action, actor)
    catch e
      return [null, {code: 500, body: JSON.stringify({"status": "error", "msg": e})}]

    if _.isEqual(old_doc, doc)
      write_doc = null
    else
      _.extend(action, {
        u: actor.name,
        dt: +new Date(),
      })
      doc.audit.push(action)
      write_doc = doc
    if prep_doc
      out_doc = JSON.parse(JSON.stringify(doc))
      out_doc = prep_doc(out_doc, actor)
    else
      out_doc = doc

    return [write_doc, JSON.stringify(out_doc)]
