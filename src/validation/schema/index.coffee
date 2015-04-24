schema = (validation) ->
  validation.schema = {}

  require('./user_data')(validation.schema)

module.exports = schema
