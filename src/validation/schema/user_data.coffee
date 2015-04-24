fields = require('validoc').fields

user_data = (schema) ->
  pubKeyField = {
    name: 'publicKey',
    field: 'ContainerField',
    schema: [ 
      { name: 'name', field: 'CharField', maxLength: 20},
      { name: 'key', field: 'CharField', maxLength: 500},
    ]
  }

  pubKeyListField =
    name: 'publicKeys'
    field: 'ListField'
    schema: pubKeyField
    required: false

  systemSchema =
    name: 'systemFields'
    field: 'ContainerField'
    schema: [
      { name: 'username', field: 'CharField', maxLength: 40},
      pubKeyListField,
    ]

  selfSchema =
    name: 'systemFields'
    field: 'ContainerField'
    schema: [
      pubKeyListField
    ]

  schema.user_data =
    self: (opts) -> fields.genField(selfSchema, opts)
    system: (opts) -> fields.genField(systemSchema, opts)

module.exports = user_data
