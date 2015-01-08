
x = {}

x.get_handlers = (entry, resources) ->
  ###
  return a hash of only the handlers that should be called for this entry
  ###
  filtered_handlers = {}
  for resource, handlers of resources
    handler = handlers.team[entry.a]
    if not handler
      if entry.k == resource
        handler = handlers.team.self?[entry.a]
      else
        handler = handlers.team.other?[entry.a]
    if handler
      filtered_handlers[resource] = handler
  return filtered_handlers

module.exports = x