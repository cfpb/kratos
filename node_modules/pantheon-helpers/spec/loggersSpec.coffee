loggers = require('../lib/loggers')

describe 'makeLogger', () ->
  beforeEach () ->
    this.loggerGenerator = jasmine.createSpyObj('loggerGenerator', ['createLogger'])

  it 'should merge customConfig into the defaultConfig, and pass merged config to the logger generator', () ->
    cut = loggers.makeLogger

    cut({x: false, y: false}, {y: true, z: true}, this.loggerGenerator)

    expect(this.loggerGenerator.createLogger).toHaveBeenCalledWith({x: false, y: true, z: true})

describe 'makeLoggers', () ->
  beforeEach () ->
    spyOn(loggers, 'getWorkerConfig').andReturn({name:'worker'})
    spyOn(loggers, 'getWebConfig').andReturn({name: 'web'})
    spyOn(loggers, 'makeLogger').andReturn('logger')

  it 'should return a worker and a web logger', () ->
    cut = loggers.makeLoggers

    result = cut({}, this.loggerGenerator)
    expect(result).toEqual({web: 'logger', worker: 'logger'})

  it 'should use the base config from getWorkerConfig and getWebConfig', () ->
    cut = loggers.makeLoggers

    result = cut({}, this.loggerGenerator)
    expect(loggers.makeLogger.calls[0].args[0]).toEqual({name: 'worker'})
    expect(loggers.makeLogger.calls[1].args[0]).toEqual({name: 'web'})

  it 'should use the custom config from conf.LOGGERS', () ->
    conf = {LOGGERS: {WEB: {x: 'web'}, WORKER: {x: 'worker'}}}

    cut = loggers.makeLoggers

    result = cut(conf, this.loggerGenerator)
    expect(loggers.makeLogger.calls[0].args[1]).toEqual({x: 'worker'})
    expect(loggers.makeLogger.calls[1].args[1]).toEqual({x: 'web'})
