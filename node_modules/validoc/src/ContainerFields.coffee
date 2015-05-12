if exports?
  utils = require "./utils"
  _ = require "underscore"
  fields = require "./Fields"
else if window?
  utils = window.validoc.utils
  fields = window.validoc.fields
  _ = window._

###
ValiDoc allows you to create arbitrarily nested forms, to validate arbitrary data structures.
You do this by using ContainerFields. create a nested form by creating a containerField
then adding childFields to the schema. See example in README.md.
###

class BaseContainerField extends fields.Field
  ###
    _fields.BaseContainerField_ is the baseclass for all container-type fields.
    ValiDoc allows you to create, validate and display arbitrarily complex
    nested data structures. container-type fields contain other fields. There
    are currently two types. A `ContainerField`, analogous to a hash of childFields,
    and a `ListField`, analogous to a list of childFields. container-type fields
    act in most ways like a regular field. You can set them, and all their childFields
    with `setValue`, you can get their, and all their childFields', data with
    `getClean` or `toJSON`.

    When a childField is invalid, the containing field will also be invalid.

    You specify a container's childFields in the `schema` attribute. Each container type
    accepts a different format for the `schema`.

    ValiDoc schemas are fully recursive - that is, containers can contain containers,
    allowing you to model and validate highly nested datastructures like you might find
    in a document database.
  ###
  # The schema used to generate the field and all its childFields
  schema: undefined
  # all childFields
  _fields: undefined
  errorMessages:
    required: utils._i('There must be at least one %s.')
    invalidChild: utils._i('Please fix the errors indicated below.')

  constructor: (schema, opts, parent) ->
    super(schema, opts, parent)
    @_createChildFields()

  validate: (value) ->
    valid = true
    _.forEach @getFields(), (field) =>
      if not field.isValid()
        valid = false
    if not valid
      throw utils.ValidationError(@errorMessages.invalidChild, 'invalidChild')
    return value

  _querychildFields: (fn, args...) ->
    ### get data from each childField `fn` and put it into the appropriate data structure ###
    return _.map(@getFields(), (x) -> x[fn].apply(x, args))

  getFields: () ->
    return @_fields

  getField: (path) ->
    ###
    return an arbitrarily deep childField given a path. Path can be an array
    of indexes/names, or it can be a dot-delimited string
    ###
    if not path or path.length == 0 then return this
    if typeof path == "string" then path = path.split "."
    childField = @_getField(path.shift())
    if not childField? then return undefined
    return childField.getField(path)

  getValue: (path) ->
    if path?.length
      return @_applyTochildField("getValue", path)
    else
      return @_value

  getClean: (path) ->
    if path?.length 
      return @_applyTochildField("getClean", path)
    else
      @_throwErrorIfInvalid()
      return @_clean

  toJSON: (path) ->
    if path?.length
      return @_applyTochildField("toJSON", path)
    else
      @_throwErrorIfInvalid()
      return @_querychildFields("toJSON")

  getErrors: (path) ->
    if path?.length
      return @_applyTochildField("getErrors", path)
    else
    @isValid()
    if @_errors.length
      return @_querychildFields("getErrors")
    else
      return []

  _createChildFields: () ->
    throw(new Error(('not implemented')))

  _addField: (schema, value) -> # TODO
    schema = _.clone(schema)
    schema._parent = this
    if value? then schema.value = value
    # child pushes itself onto parent
    field = fields.genField(schema, this, value)
    return field
  _applyTochildField: (fn, path, args...) ->
    childField =  @getField(path)
    if not childField then throw Error "Field does not exist: " + String(path)
    return childField[fn].apply(childField, args)


class ContainerField extends BaseContainerField
  ###
    A ContainerField contains a number of heterogeneous
    childFields. When data is extracted from it using `toJSON`, or `getClean`, the
    returned data is in a hash object where the key is the name of the childField
    and the value is the value of the childField.

    the schema for a ContainerField is an Array of kind definition objects such as
    `[{kind: "CharField", maxLength: 50 }, {kind:IntegerField }`.
    The ContainerField will contain the specified array of heterogenious fields.
  ###
  widget: "widgets.ContainerWidget"
  default: {}
  errorMessages:
    invalid: utils._i('%s must be a hash')
    undescribed: utils._i('%s is not allowed')

  _createChildFields: () ->
    value = @getValue()
    value = if _.isObject(value) and not _.isArray(value) then value else {}
    initialValue = @getInitialValue()
    initialValue = if _.isObject(initialValue) and not _.isArray(initialValue) then initialValue else {}

    @_fields = _.map(@schema, (childSchema) =>
      opts = _.clone(@opts)
      opts.value = value[childSchema.name]
      opts.initialValue = initialValue[childSchema.name]
      fields.genField(childSchema, opts, this)
    )

  validate: (value, initialValue, opts) ->
    if not utils.isHash(value)
      throw utils.ValidationError(@errorMessages.invalid, "invalid", JSON.stringify(value))
    else if opts.fullyDescribed
      for k of value
        if k not of @schema
          throw utils.ValidationError(@errorMessages.undescribed, "undescribed", k)
    else
      return super(value)

  _getField: (name) ->
    # get an immediate childField by name
    for field in @getFields()
      if field.name == name then return field

  _querychildFields: (fn, args...) ->
    out = {}
    _.forEach(@getFields(), (x) -> out[x.name] = x[fn].apply(x, args))
    return out

  getPath: (childField) ->
    end = []
    if childField
      end.push(childField.name)
    # if no parent, then the path is siply the empty list
    if @_parent
      return @_parent.getPath(this).concat(end)
    else
      return end

  getValueForCleaning: () ->
    value = {}
    for field in @_fields
      value[field.name] = field.getValueForCleaning()
    return value


class HashField extends ContainerField
  ###
      A HashField contains an arbitrary number of identical childFields in a hash
      (javascript object). When data is extracted from it using `toJSON`, or 
      `getClean`, the returned data is in an object where each value is the value 
      of the childField at the corresponding key.

      A HashField's `schema` consists of a single field definition, such as
      `{ kind: "email" }`.

      This doesn't really seem to have a use case for a widget, just for arbitrary
      json validation. so no widget is provided
  ###
  widget: null
  default: {}
  errorMessages:
    invalid: utils._i('%s must be a hash')

  _createChildFields: () ->
    value = @getValue()
    value = if _.isObject(value) and not _.isArray(value) then value else {}
    initialValue = @getInitialValue()
    initialValue = if _.isObject(initialValue) and not _.isArray(initialValue) then initialValue else {}

    keys = _.union(_.keys(value), _.keys(initialValue))
    @_fields = _.map(keys, (key) =>
      schema = _.clone(@schema)
      schema.name = key
      opts = _.clone(@opts)
      opts.value = value[key]
      opts.initialValue = initialValue[key]
      fields.genField(schema, opts, this)
    )

  validate: (value) ->
    if _.isEmpty(value) && @required
      itemName = @schema.name || (_.isString(@schema.field) && @schema.field.slice(0,-5)) || "item"
      throw utils.ValidationError(@errorMessages.required, 'required', @schema.name || (_.isString(@schema.field) && @schema.field.slice(0,-5)) || "item")
    else
      return super(value)


class ListField extends BaseContainerField
  ###
      A ListField contains an arbitrary number of identical childFields in a
      list. When data is extracted from it using `toJSON`, or `getClean`, the
      returned data is in a list where each value is the value of the childField at
      the corresponding index.

      A ListField's `schema` consists of a single field definition, such as
      `{ kind: "email" }`.
  ###
  widget: "widgets.ListWidget",
  default: []
  errorMessages:
    invalid: utils._i('%s must be an array')


  _createChildFields: () ->
    value = @getValue()
    value = if _.isArray(value) then value else []
    initialValue = @getInitialValue()
    initialValue = if _.isArray(initialValue) then initialValue else {}

    @_fields = _.map(value, (childValue, i) =>
      childInitialValue = initialValue[i]
      opts = _.clone(@opts)
      opts.value = childValue
      opts.initialValue = childInitialValue
      fields.genField(@schema, opts, this)
    )

  validate: (value) ->
    if _.isEmpty(value) && @required
      itemName = @schema.name || (_.isString(@schema.field) && @schema.field.slice(0,-5)) || "item"
      throw utils.ValidationError(@errorMessages.required, 'required', @schema.name || (_.isString(@schema.field) && @schema.field.slice(0,-5)) || "item")
    else if not _.isArray(value)
      throw utils.ValidationError(@errorMessages.invalid, "invalid", JSON.stringify(value))
    else
      return super(value)

  _getField: (index) ->
    ### get an immediate childField by index ###
    return @getFields()[index]

  getPath: (childField) ->
    end = []
    if childField
      end.push(@getFields().indexOf(childField))
    # if no parent, then the path is siply the empty list
    if @_parent
      return @_parent.getPath(this).concat(end)
    else
      return end

  getValueForCleaning: () ->
    @_fields.map((field) -> field.getValueForCleaning())


fields.BaseContainerField = BaseContainerField
fields.ContainerField = ContainerField
fields.HashField = HashField
fields.ListField = ListField

if exports?
  module.exports = fields