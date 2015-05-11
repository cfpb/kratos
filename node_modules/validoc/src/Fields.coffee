###
the base Field class and most of the core fields.
###

if exports?
  utils = require "./utils"
  validators = require "./Validators"
  _ = require "underscore"
else if window?
  utils = window.validoc.utils
  validators = window.validoc.validators
  _ = window._

ValidationError = utils.ValidationError

class Field
  ###
  Baseclass for all fields. Fields are defined by a schema. 
  You can override attributes and methods within the schema. 
  For example:

      var simpleSchema = { name: "firstField"
                         , field: "Field"
                         , required: false
                         };

  will create a basic field that is not required.
  This is not particularly useful.
  But we can create useful fields using subclasses of Field:

      var pwSchema = { name: "badPasswordField"
                     , field: "CharField"
                     , maxLength: 8
                     , minLength: 4
                     , widget: "Widgets.PasswordWidget"
                     };

  Now we have created a very insecure password field schema.
  We have overridden the Charfield's default widget with a password widget.

  We create a Field instance from a schema by calling:

      simpleField = validoc.genField(simpleSchema, opts);

  `opts` is an optional hash explained later.

  Your schema is a JavaScript object,
  so it can define both attributes and methods for the resulting Field.
  While in Django you would have to create a custom Field subclass for a one-off field with custom validation,
  in ValiDoc, you can simply override the clean() method.
  You can then optionally turn that schema into its own reusable field if you need to use it again later Any defaults can be overridden by subclasses
  The following attributes can be specified in the schema.
    
    * `field`: the field type (e.g. CharField, ContainerField) (required)
    * `name`: the name/identifier for this field (required)
    * `widget`: widget constructor hash or string name
       (e.g. { widget: "widget.Widget"}, or simply "widget.Widget")
       (default: depends on Field type)
    * `required`: whether the current field is required (default: true)
    * `default`: the default value of the field.
      If the value is undefined, the value will be set to the default value.

  The following attributes can also technically be specified in the schema,
  but in practice, the should only have to be modified by subclasses:

    * `errorMessages`: hash of error message codes and keys.
      You can override any error message by setting a new message for the code.
    * `validators`: array of validators;
      If overriding a parent class, you must include all ancestor validators

  Just like with django forms, you can create a bound or unbound field.
  A bound field has been bound to data that needs to be validated.
  An unbound field has no data to validate, 
  and is usually used to generate a user interface.
  In ValiDoc, you bind a field to data by passing a `value` in the opts.
  One of the major shortcomings of Django forms is that you cannot validate
  data transitions, only data states. ValiDoc solves this by letting you pass
  an `initialValue`, in addition to `value`. Your `clean` method 

    * `value`: the current value of the field
    * `initialValue`: the initial value of the field (useful for custom validation)
    * `fullyDescribed`: whether the schema must fully describe the value. (default: false)

  You are probably doing something wrong if you access an attribute
  that starts with an underscore. You should **never** directly modify
  any attribute that starts with an underscore.
  ###

  name: undefined
  # whether the current field is required
  required: true
  # kind definition for widget to display (eg { kind: "widget.Widget"}, or simply the string name of the widget kind)
  defaultWidget: "TextInput",
  # the default value of the field. if the set value is undefined, the value will changed to the default value
  default: undefined

  # list of validators; If overriding a parent class, you must include all parent class validators
  validators: [],
  # hash of error messages; If overriding a parent class, you must include all parent class errorMessages
  errorMessages:
    required: utils._i('This field is required.')

  # the cleaned value accessed via `getClean()`;
  # this will be a javascript value (such as a DateTime) 
  # that should be used for any calculations, etc.
  # Use the toJSON() method to get a version appropriate for serialization.
  _clean: undefined,
  # a list of errors for this field.
  _errors: [],
  # parent field, set by parent
  _parent: undefined
  # the name/identifier for this field
  _value: undefined
  # the initial value of the field (for validation)
  _initialValue: undefined

  constructor: (schema, opts, parent) ->
    if parent?
      @_parent = parent

    schema ?= {}
    opts ?= {}
    @_rawSchema = _.clone(schema)
    @_rawOpts = _.clone(opts)

    schemaErrorMessages = utils.objPop(schema, 'errorMessages') or {}
    @errorMessages = @_walkProto("errorMessages")
    _.extend(@errorMessages, schemaErrorMessages)

    schemaValidators = utils.objPop(schema, 'validators') or []
    @validators = @_walkProto("validators")
    @validators = @validators.concat(schemaValidators)

    # otherwise all fields would share the same errors lists
    @_errors = []

    @setSchema(schema)

    @setOpts(opts)

  _walkProto: (attr) ->
    ### walks the prototype chain collecting all the values off attr and combining them in one. ###
    sup = @constructor.__super__
    if sup?
      if _.isArray(@[attr])
        return @[attr].concat(sup._walkProto(attr))
      else
        return _.extend(sup._walkProto(attr), @[attr])
    else
      return _.clone(this[attr])

  getErrors: () ->
    ### get the errors for this field. ###
    @isValid()
    if @_errors.length
      return @_errors 
    else
      return []

  toJavascript: (value) ->
    ###
    First function called in validation process.<br />
    this function converts the raw value to javascript. `value` is the raw value from
    `@getValue()`. The function returns the value in the proper javascript format,<br />
    this function should be able to convert from any type that a widget might supply to the type needed for validation
    ###
    return value

  validate: (value, initialValue, opts) ->
    ###
    Second function called in validation process.<br />
    Any custom validation logic should be placed here. receives the input, `value`, from `toJavascript`'s output.
    return the value with any modifications. When validation fails, throw a utils.ValidationError. with a 
    default error message, a unique error code, and any attributes for string interpolation of the error message
    be sure to call `@super <br />
    default action is to check if the field is required
    ###
    if (validators.isEmpty(value) && @required)
      throw ValidationError(@errorMessages.required, "required")
    return value

  runValidators: (value, initialValue, opts) ->
    ###
    Third function called in validation process.<br />
    You should not have to override this function. simply add validators to @validators.
    ###
    if (validators.isEmpty(value)) then return
    for v in @validators
      @_catchErrors(v, value, opts)
    return value;

  isValid: () ->
    ### primary validation function<br />
    calls all other validation subfunctions.
    returns `true` or `false`
    ###
    if @_valid? then return @_valid
    # call the various validators
    value = @getValueForCleaning()
    initialValue = @getInitialValue()
    value = @_catchErrors(@toJavascript, value, initialValue, @opts)
    value = @_catchErrors(@validate, value, initialValue, @opts) if (!@_errors.length)
    value = @runValidators(value, initialValue, @opts) if (!@_errors.length)
    valid = !@_errors.length
    @_clean = if valid then value else undefined
    @_valid = valid
    return valid

  _catchErrors: (fn, value, initialValue, opts) ->
    ### helper function for running an arbitrary function, capturing errors and placing in error array ###
    try
      if _.isFunction(fn)
        value = fn.call(this, value, initialValue, opts)
      else
        value = fn.validate(value, initialValue, opts)
    catch e
      message = if @errorMessages[e.code]? then @errorMessages[e.code] else e.message
      message = utils.interpolate(message, e.params) if e.params?
      @_errors.push(message)
    return value

  getClean: () ->
    ###
    return the field's cleaned data if there are no errors.
    throws an error if there are validation errors.
    you should not need to override this in Field subclasses
    ###
    @_throwErrorIfInvalid()
    return @_clean

  toJSON: () ->
    ###
    return the field's cleaned data in serializable form if there are no errors.
    throws an error if there are validation errors.
    you might have to override this in Field subclasses.
    ###
    return @getClean()

  setOpts: (opts) ->
    @_initialValue = utils.objPop(opts, 'initialValue') or opts.value
    @_value = utils.objPop(opts, 'value')
    @_value ?= _.clone(@default)
    @opts = _.clone(opts)

  setSchema: (schema) ->
    _.extend(@, schema)

  getValue: () ->
    ### You should not have to override this in Field subclasses ###
    return @_value

  getValueForCleaning: () ->
    ### Should only need to be overridden by container subclasses ###
    return @getValue()

  getInitialValue: () ->
    return @_initialValue

  getPath: () ->
    ###
    Get an array of the unique path to the field.
    A ListField's subfields are denoted by an integer representing the index of the subfield.
    A ContainerField's subfields are denoted by a string or integer representing the key of the subfield.
    Example:
    {parent: {child1: hello, child2: [the, quick, brown, fox]}}
    ["parent", "child2", 1] points to "quick"
    [] points to {parent: {child1: hello, child2: [the, quick, brown, fox]}}
    ###
    # if no parent, then the path is siply the empty list
    if @_parent
      return @_parent.getPath(this)
    else
      return []

  getField: (path) ->
    ### get a field given a path ###
    return if path.length > 0 then undefined else this      

  _throwErrorIfInvalid: () ->
    if not @isValid() then throw @_errors


class CharField extends Field
  ###
  a field that contains a string.  
  Attributes:

   * `maxLength`: The maximum length of the string (optional)
   * `minLength`: The minimum length of the string (optional)

  Default widget: TextInput
  ###
  # The maximum length of the string (optional)
  maxLength: undefined
  ### The minimum length of the string (optional) ###
  minLength: undefined
  constructor: (schema, opts, parent) ->
    super(schema, opts, parent)
    if @maxLength?
      @validators.push(new validators.MaxLengthValidator(@maxLength))
    if @minLength?
      @validators.push(new validators.MinLengthValidator(@minLength))
  toJavascript: (value) ->
    value = if validators.isEmpty(value) then "" else value
    return value




class IntegerField extends Field
  ###
  a field that contains a whole number.  
  Attributes:  

   * `maxValue`: Maximum value of integer
   * `minValue`: Minimum value of integer

  Default widget: TextInput
  ###
  # Maximum value of integer
  maxValue: undefined
  # Minimum value of integer
  minValue: undefined
  errorMessages: {
    invalid: utils._i('Enter a whole number.')
  },
  constructor: (schema, opts, parent) ->
    super(schema, opts, parent)
    if @maxValue?
      @validators.push(new validators.MaxValueValidator(@maxValue))
    if @minValue?
      @validators.push(new validators.MinValueValidator(@minValue))
  parseFn: parseInt
  regex: /^-?\d*$/
  toJavascript: (value) ->
    if typeof(value) == "string" and not value.match(@regex)
      throw ValidationError(@errorMessages.invalid, "invalid")
    value = if validators.isEmpty(value) then undefined else @parseFn(value, 10)
    if value? and isNaN(value)
      throw ValidationError(@errorMessages.invalid, "invalid")
    return value


class FloatField extends IntegerField
  ###
  A field that contains a floating point number.  
  Attributes:

    * `maxDecimals`: Maximum number of digits after the decimal point
    * `minDecimals`: Minimum number of digits after the decimal point
    * `maxDigits`: Maximum number of total digits before and after the decimal point
  
  Default widget: TextInput
  ###
  # Maximum number of digits after the decimal point
  maxDecimals: undefined,
  # Minimum number of digits after the decimal point
  minDecimals: undefined,
  # Maximum number of total digits before and after the decimal point
  maxDigits: undefined
  # @protected
  errorMessages:
    invalid: utils._i('Enter a number.')
  constructor: (schema, opts, parent) ->
    super(schema, opts, parent)
    if @maxDecimals?
      @validators.push(new validators.MaxDecimalPlacesValidator(@maxDecimals))
    if @minDecimals?
      @validators.push(new validators.MinDecimalPlacesValidator(@minDecimals))
    if @maxDigits?
      @validators.push(new validators.MaxDigitsValidator(@maxDigits))
  parseFn: parseFloat
  regex: /^\d*\.?\d*$/

# a basic Regex Field for subclassing.
class RegexField extends Field
  ###
  A baseclass for subclassing.
  Attributes:

    * `regex`: the compiled regex to test against
    * `errorMessage`: the error message to display when the regex fails
  
  Default widget: TextInput
  ###
  # the compiled regex to test against.
  regex: undefined,
  # the error message to display when the regex fails
  errorMessage: undefined
  # @protected
  constructor: (schema, opts, parent) ->
    super(schema, opts, parent)
    @validators.push(new validators.RegexValidator(@regex))
    if @errorMessage
      @errorMessages.invalid = @errorMessage



class EmailField extends RegexField
  ###
  A field that contains a valid email.  
  Attributes:

    * None
  
  Default widget: EmailInput
  ###
  widget: "EmailInput"
  validators: [new validators.EmailValidator()]

class BooleanField extends Field
  ###
  A field that contains a Boolean value. Must be true or false.
  if you want to be able to store null us `NullBooleanField`
  Attributes:

    * none
  
  Default widget: CheckboxInput
  ###
  widget: "CheckboxInput"
  # @protected
  toJavascript: (value) ->
    if typeof(value) == "string" and value.toLowerCase() in ["false", "0"]
      value = false
    else
      value = Boolean(value)
    if not value and @required
      throw ValidationError(@errorMessages.required, "required")
    return value

class NullBooleanField extends BooleanField
  ###
  A field that contains a Boolean value. The value can be 
  true, false, or null.  
  Attributes:

    * none
  
  Default widget: CheckboxInput
  ###
  toJavascript: (value) ->
    if value in [true, "True", "1"]
      value =  true
    else if value in [false, "False", "0"]
      value = false
    else 
      value = null
    return value
  validate: (value) ->
    return value


class ChoiceField extends Field
  ###
  A field that contains value from a list of values.  
  Attributes:

    * `choices`: Array of 2-arrays specifying valid choices. if 2-arrays, first value is value, second is display. create optgroups by setting display If display value to a 2-array. MUST USE `setChoices`.
  
  Default widget: Select
  ###
  widget: "Select"
  # Array of 2-arrays specifying valid choices. if 2-arrays, first value is value, second is display. create optgroups by setting display If display value to a 2-array. MUST USE SETTER.
  choices: []
  errorMessages:
    invalidChoice: utils._i('Select a valid choice. %(value)s is not one of the available choices.')
  constructor: (schema, opts, parent) ->
    if opts.choices then @choices = opts.choices
    @setChoices(_.clone(@choices))
    super(schema, opts, parent)

  setChoices: (val) ->
    choices = {};
    iterChoices = (x) ->
      if (x[1] instanceof Array) then _.forEach(x[1], iterChoices)
      else choices[x[0]] = x[1];
    _.forEach(@choices, iterChoices)
    @choicesIndex = choices
  toJavascript: (value) ->
    value = if validators.isEmpty(value) then "" else value
    return value
  validate: (value) ->
    value = super(value)
    if value and not @validValue(value)
      throw ValidationError(@errorMessages.invalidChoice, "invalidChoice", value)
    return value
  validValue: (val) ->
    return val of @choicesIndex
  getDisplay: () ->
    return @choices[@getClean()]

fields =
  Field: Field
  CharField: CharField
  IntegerField: IntegerField
  FloatField: FloatField
  RegexField: RegexField
  EmailField: EmailField
  BooleanField: BooleanField
  NullBooleanField: NullBooleanField
  ChoiceField: ChoiceField
  # get a variable from the global variable, identified by a dot-delimited string
  getField: (path) ->
    path = path.split(".")
    out = this
    for part in path
      out = out[part]
    return out
  # generate a field from its schema
  genField: (schema, opts, parent) ->
    schema = _.clone(schema)
    field = @getField(schema.field)
    if not field then throw Error("Unknown field: "+ schema.field)
    return new field(schema, opts, parent)


if window?
  window.validoc.fields = fields
else if exports?
  module.exports = fields
