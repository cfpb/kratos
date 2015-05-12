fields = require('validoc').fields

class PubKeyField extends fields.RegexField
  ###
  A field that contains a valid public key.
  ###
  # currently tests for:
  #  - start with 'ssh-rsa AAAA'
  #  - body is limited to alphanumerics + "/" + "+"
  #  - the cryptokey ends with 0-3 "="
  #  - the body ends with a user label approximating an email address.
  regex: /^ssh-rsa AAAA[0-9A-Za-z+/]+[=]{0,3} [0-9A-Za-z.-]+(@[0-9A-Za-z.-]+)?$/
  errorMessage: "invalid public key"

fields.PubKeyField = PubKeyField;


user_data = (schema) ->
  pubKeyField = {
    name: 'publicKey',
    field: 'ContainerField',
    schema: [ 
      { name: 'name', field: 'CharField', maxLength: 20},
      { name: 'key', field: 'PubKeyField'},
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
      { name: 'contractor', field: 'NullBooleanField'},
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
