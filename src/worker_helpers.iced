
x = {}

x.get_handlers = (entry, db_type, resources) ->
  ###
  return a hash of only the handlers that should be called for this entry
  and db_type
  ###
  filtered_handlers = {}
  for resource, handlers of resources
    handler = handlers[db_type]?[entry.a]
    if not handler
      if entry.k == resource
        handler = handlers[db_type]?.self?[entry.a]
      else
        handler = handlers[db_type]?.other?[entry.a]
    if handler
      filtered_handlers[resource] = handler
  return filtered_handlers

module.exports = x