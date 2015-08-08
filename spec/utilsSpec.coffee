utils = require('../lib/utils')
conf = require('../lib/config')

describe 'getPluginImportStrings', () ->
  actualRESOURCES = conf.RESOURCES
  beforeEach () ->
    conf.RESOURCES =
      PLUGIN1: {}
      PLUGIN2: {}
      PLUGIN3: {REQUIRE_NAME: 'custom-name-3'} 

  afterEach () ->
    conf.RESOURCES = actualRESOURCES

  it 'returns a list of one `require` string for each plugin defined in config.RESOURCES', () ->
    cut = utils.getPluginImportStrings

    actual = cut()

    expect(actual).toEqual(['kratos-plugin1', 'kratos-plugin2', 'custom-name-3'])

  it 'returns the REQUIRE_NAME for each resource, when specified', () ->
    cut = utils.getPluginImportStrings

    actual = cut()

    expect(actual[2]).toEqual('custom-name-3')

  it 'returns a require name generated from the conf.RESOURCES key, if REQUIRE_NAME is not specified', () ->
    cut = utils.getPluginImportStrings

    actual = cut()

    expect(actual[0]).toEqual('kratos-plugin1')

describe 'getPlugins', () ->
  beforeEach () ->
    spyOn(utils, 'getPluginImportStrings').andReturn(['istanbul', 'coveralls'])

  it 'should call `require` for each module defined in config', () ->
    cut = utils.getPlugins

    actual = cut()

    expect(actual.length).toEqual(2)
    expect(actual[0]).toBe(require('istanbul'))
    expect(actual[1]).toBe(require('coveralls'))