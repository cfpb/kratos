if exports?
  validoc = require('../lib/validoc')
  _ = require('underscore')

fields = validoc.fields
utils = validoc.utils

describe "class inheritence", ->
  it "should preserve errorMessages of superclass when none are added", ->
    field = new fields.CharField()
    expect(field.errorMessages).toEqual(required: utils._i('This field is required.'))

  it "should add class error messages to superclass messages", ->
    field = new fields.IntegerField()
    expect(field.errorMessages).toEqual({required: utils._i('This field is required.'), invalid: utils._i('Enter a whole number.')})

  it "should properly update attributes defined by either superclass or class from passed options", ->
    field = new fields.CharField({required: false, minLength: 5})
    expect(field.required).toBe(false)
    expect(field.minLength).toBe(5)

  it "should override superclass error messages with subclass messages", ->
    field = new fields.ListField()
    expect(field.errorMessages).toEqual({required: utils._i('There must be at least one %s.'), invalidChild: utils._i('Please fix the errors indicated below.'), invalid: utils._i('%s must be an array')})




describe "validation", ->
  it "defaults to required", ->
    field = new fields.Field({name:"test"})
    expect(field.required).toBe(true)

  it "should not validate if required and no value", ->
    field = new fields.Field({name:"test"})
    expect(field._value).toBe(undefined)
    expect(field.isValid()).toBe(false)
    expect(field.getErrors()).toEqual(['This field is required.'])

    field = new fields.Field({name:"test"}, {value: ""})
    expect(field.isValid()).toBe(false)

    field = new fields.Field({name:"test"}, {value: null})
    expect(field.isValid()).toBe(false)

  it "should validate if required and value", ->
    field = new fields.Field({name:"test"}, {value: 0})
    expect(field.getValue()).toBe(0)
    expect(field.isValid()).toBe(true)
    expect(field.getErrors()).toEqual([])

  it "should validate if not required and no value", ->
    field = new fields.Field({name:"test", required: false}, {value: 0})
    expect(field.isValid()).toBe(true)

  it "should throw an error when getClean is called and it is not valid", ->
    field = new fields.Field({name:"test"})
    expect(=> field.getClean()).toThrow()

describe "genField() - field creation", ->
  it "should create a field from a schema", ->
    schema = {field: "CharField", name: "test", minLength: 5}
    field = fields.genField(schema, undefined, undefined)
    expect(field instanceof fields.CharField).toBe(true)

describe "field", ->
  it "should return list of all errors", ->
    field = new fields.IntegerField({name:"test", minValue: 0}, {value: -4})
    expect(field.getErrors()).toEqual(['Ensure this value is greater than or equal to 0.'])

  it "should allow passing in error messages through the schema", ->
    field = new fields.IntegerField({name:"test", errorMessages: {invalid: "Invalid"}, minValue: 0})
    expect(field.errorMessages).toEqual(required: 'This field is required.', invalid: "Invalid")

  it "should set both initialValue and value to value if only value is provided", ->
    field = new fields.IntegerField({name:"test", minValue: 0}, {value: 5})
    expect(field.getInitialValue()).toBe(5)
    expect(field.getValue()).toBe(5)

  it "should set initialValue to initialValue, value to undefined, if only initial is provided", ->
    field = new fields.IntegerField({name:"test", minValue: 0}, {initialValue: 5})
    expect(field.getInitialValue()).toBe(5)
    expect(field.getValue()).toBe(undefined)

  it "should set initialValue and value to their respective values if both are provided", ->
    field = new fields.IntegerField({name:"test", minValue: 0}, {value: 10, initialValue: 5})
    expect(field.getInitialValue()).toBe(5)
    expect(field.getValue()).toBe(10)
    
  it "should set initialValue to undefined and value to default, if neither is defined", ->
    field = new fields.IntegerField({name:"test", minValue: 0, default: 10})
    expect(field.getInitialValue()).toBe(undefined)
    expect(field.getValue()).toBe(10)
    