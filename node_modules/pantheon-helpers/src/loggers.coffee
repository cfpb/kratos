bunyan = require('bunyan')
utils = require('./utils')

loggers =
  makeLogger: (defaultConfig, customConfig, logger=bunyan) ->

    config = utils.deepExtend(defaultConfig, customConfig)
    return logger.createLogger(config)

  makeLoggers: (conf) ->
    loggerConf = conf.LOGGERS or {}
    return {
      worker: loggers.makeLogger(loggers.getWorkerConfig(), loggerConf.WORKER)
      web: loggers.makeLogger(loggers.getWebConfig(), loggerConf.WEB)
    }
  getWorkerConfig: () ->
    return {name: "worker"}
  getWebConfig: () ->
    return {name: "web"}

module.exports = loggers
