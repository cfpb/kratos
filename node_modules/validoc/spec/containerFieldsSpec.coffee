if exports?
  validoc = require('../lib/validoc')
  _ = require('underscore')

fields = validoc.fields
utils = validoc.utils

describe "ListField", ->
  beforeEach ->
    @subSchema = {field: "CharField", name: "sub", minLength: 5}
    @vals = ["hello", "world"]
    @field = new fields.ListField({name:"test", schema: @subSchema}, {value: @vals})

  it "should store its schema in @schema", ->
    expect(@field.schema).toEqual(@subSchema)

  it "should create as many subfields as there are vals in the values array; subfield should have proper value and parent should be ListField", ->
    expect(@field.getFields().length).toBe(2)
    expect(@field.getFields()[0].getValue()).toEqual("hello")
    expect(@field.getFields()[1].getValue()).toEqual("world")
    expect(@field.getFields()[0]._parent).toBe(@field)

  it "should generate path for subfield from index", ->
    expect(@field.getFields()[0].getPath()).toEqual([0])
    expect(@field.getFields()[1].getPath()).toEqual([1])

  it "should return getValue() as a list of subfield values", ->
    expect(@field.getValue()).toEqual(["hello", "world"])

  xit "should throw an error if setValue called with anything other than an Array of values", ->
    expect(=> @field.setValue('hello')).toThrow()
    expect(=> @field.setValue(a: 'hello')).toThrow()

  it "should be able to get immediate child by index", ->
    expect(@field._getField(0).getValue()).toBe("hello")

  it "should getValue of listField when path is empty", ->
    expect(@field.getValue("")).toEqual(@field.getValue())
    expect(@field.getValue([])).toEqual(@field.getValue())
    expect(@field.getValue()).toEqual(@field.getValue())

  xit "should return an empty list if value passed is undefined; it should return null if value passed is null", ->
    @field = new fields.ListField(name:"test", schema: @subSchema)
    expect(@field.getValue()).toEqual([])
    @field = new fields.ListField(name:"test", schema: @subSchema, value: null)
    expect(@field.getValue()).toEqual(null)


describe "ContainerField", ->
  beforeEach ->
    @subSchema = [{field: "CharField", name: "sub", minLength: 5}, {field: "IntegerField", name: "sub2", minValue: 0}]
    @vals = {sub: "hello world", sub2: 5}
    @field = new fields.ContainerField({name:"test", schema: @subSchema}, {value: @vals})

  it "should create subfields from schema with field as parent, and appropriate value", ->
    expect(@field.schema).toEqual(@subSchema)
    expect(@field.getFields()[0] instanceof fields.CharField).toBe(true)
    expect(@field.getFields()[1] instanceof fields.IntegerField).toBe(true)
    expect(@field.getFields()[0].getValue()).toEqual("hello world")
    expect(@field.getFields()[1].getValue()).toEqual(5)
    expect(@field.getFields()[0]._parent).toBe(@field)

  it "should generate path for subfield from name", ->
    expect(@field.getFields()[0].getPath()).toEqual(["sub"])
    expect(@field.getFields()[1].getPath()).toEqual(["sub2"])

  it "should return getValue() as a hash of subfield values", ->
    expect(@field.getValue()).toEqual(sub:"hello world", sub2: 5)

  it "should be able to get immediate child by name", ->
    expect(@field._getField("sub").getValue()).toBe("hello world")

  it "should throw an error if setValue called with anything other than a hash of values", ->
    expect(=> @field.setValue('hello')).toThrow()
    expect(=> @field.setValue(['hello'])).toThrow()

  it "should getValue of Containerfield when path is empty", ->
    expect(@field.getValue("")).toEqual(@field.getValue())
    expect(@field.getValue([])).toEqual(@field.getValue())
    expect(@field.getValue()).toEqual(@field.getValue())

  it "should create a child with an undefined value, if the child field has no corresponding value", ->
    field = new fields.ContainerField({name:"test", schema: @subSchema})
    expect(field.getFields()[0].getValue()).toBe(undefined)
    expect(field.getFields()[1].getValue()).toBe(undefined)

  it "should allow key/values not described by its schema, by default", ->
    @vals.extraField = true
    field = new fields.ContainerField({name:"test", schema: @subSchema}, {value: @vals})
    actual = field.isValid()
    expect(actual).toBe(true)

  it "should only allow key/values described by its schema, when fullyDescribed is true", ->
    @vals.extraField = true
    field = new fields.ContainerField({name:"test", schema: @subSchema}, {value: @vals, fullyDescribed: true})
    actual = field.isValid()
    expect(actual).toBe(false)

  it "should return only data that has been cleaned by the schema, even when fullyDescribed == false", ->
    @vals.extraField = true
    field = new fields.ContainerField({name:"test", schema: @subSchema}, {value: @vals})
    actual = field.getClean()
    expect(actual).toEqual({sub: "hello world", sub2: 5})



describe "HashField", ->
  beforeEach ->
    @subSchema = {field: "CharField", name: "sub", minLength: 5}
    @vals = hello: "world", goodnight: "moon"
    @field = new fields.HashField({name:"test", schema: @subSchema}, {value: @vals})

  it "should store its schema in @schema", ->
    expect(@field.schema).toEqual(@subSchema)

  it "should create as many subfields as there are vals in the values object; subfield should have proper value and parent should be HashField", ->
    expect(@field.getFields()[0].getValue()).toEqual("world")
    expect(@field.getFields()[1].getValue()).toEqual("moon")    
    expect(@field.getFields()[0]._parent).toBe(@field)

  it "should generate path for subfield from key", ->
    expect(@field.getFields()[0].getPath()).toEqual(["hello"])
    expect(@field.getFields()[1].getPath()).toEqual(["goodnight"])

  it "should return getValue() as a hash of subfield values", ->
    expect(@field.getValue()).toEqual({hello: "world", goodnight: "moon"})

  it "should throw an error if setValue called with anything other than a hash of values", ->
    expect(=> @field.setValue('hello')).toThrow()
    expect(=> @field.setValue(['hello'])).toThrow()

  it "should be able to get immediate child by index", ->
    expect(@field._getField("hello").getValue()).toBe("world")

  it "should return the value when getValue() called", ->
    expect(@field.getValue()).toEqual({hello: "world", goodnight: "moon"})

  xit "should return an empty list if value passed is undefined; it should return null if value passed is null", ->
    @field = new fields.HashField(name:"test", schema: @subSchema)
    expect(@field.getValue()).toEqual({})
    @field = new fields.HashField(name:"test", schema: @subSchema, value: null)
    expect(@field.getValue()).toEqual(null)


describe "ListField Validation", ->
  beforeEach ->
    @subSchema = {field: "CharField", name: "sub", minLength: 5}


  it "should be valid only if children are valid", ->
    field = new fields.ListField({name:"test", schema: @subSchema}, {value: ['hello', 'moon']})
    expect(field.isValid()).toBe(false)
    field = new fields.ListField({name:"test", schema: @subSchema}, {value: ['hello', 'world']})
    expect(field.isValid()).toBe(true)

  xit "should not be valid if no children and required", ->
  xit "should be valid if no children but not required", ->

describe "ContainerField Validation", ->
  beforeEach ->
    @subSchema = [{field: "CharField", name: "sub", minLength: 5}, {field: "IntegerField", name: "sub2", minValue: 0}]

  it "should be valid only if children are valid", ->
    field = new fields.ContainerField({name:"test", schema: @subSchema}, {value: {sub: "hello world", sub2: -5}})
    expect(field.getFields()[1].isValid()).toBe(false)
    expect(field.isValid()).toBe(false)

    field = new fields.ContainerField({name:"test", schema: @subSchema}, {value: {sub: "hello world", sub2: 5}})
    expect(field.isValid()).toBe(true)

describe "field traversal", ->
  beforeEach -> 
    @schema = [{
      field: "ListField",
      name: "firstList",
      schema: {
        field: "ContainerField",
        name: "secondContainer",
        schema: [{
          field: "ListField",
          name: "secondList",
          schema: {
            field: "CharField",
            name: "text",
            minLength: 5
          }
        }]
      }
    }]
    @vals = {firstList: [{secondList:["hello", "moon"]}]}
    @passingVals = {firstList: [{secondList:["hello", "world"]}]}
    @field = new fields.ContainerField({name:"firstContainer", schema: @schema}, {value: @vals})

  it "should recursively input values and create subfield", ->
    expect(@field.getValue()).toEqual({ firstList : [ { secondList : [ 'hello', 'moon' ] } ] })

  it "should return itself if no path given, or path is null/undefined", ->
    expect(@field.getField()).toBe(@field)
    expect(@field.getField("")).toBe(@field)

  it "should return a subfield given a string path", ->
    expect(@field.getField("firstList.0.secondList.1").getValue()).toBe("moon")

  it "should return a subfield given an array path", ->
    expect(@field.getField(["firstList", 0, "secondList", 1]).getValue()).toBe("moon")

  it "should return undefined if getField is passed an invalid path", ->
    expect(@field.getField("noField")).toBe(undefined)
    expect(@field.getField("firstList.22")).toBe(undefined)

  it "should get isValid for specific field if passed path", ->
    expect(@field.isValid("firstList.0.secondList.1")).toBe(false)

  it "should getValue and json for specific field if passed path", ->
    @field = new fields.ContainerField({name:"firstContainer", schema: @schema}, {value: @passingVals})
    expect(@field.getValue("firstList.0.secondList")).toEqual(["hello", "world"])
    expect(@field.toJSON("firstList.0.secondList")).toEqual(["hello", "world"])
    expect(@field.getClean("firstList.0.secondList")).toEqual(["hello", "world"])

  it "should get errors for specific field if passed path", ->
    expect(@field.getErrors("firstList.0.secondList.1")).toEqual(['Ensure this value has at least 5 characters (it has 4).'])

  it "should convert string path to array path", ->
    expect(@field.getValue(["firstList",0,"secondList"])).toEqual(["hello", "moon"])