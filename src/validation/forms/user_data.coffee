fields = require('../doccontrol/index').fields

user_data = (forms) ->
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

  forms.user_data = 
    self: fields.genField(selfSchema)
    system: fields.genField(systemSchema)

module.exports = user_data
