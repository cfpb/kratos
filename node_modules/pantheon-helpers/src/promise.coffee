Promise = require('promise')
_ = require('underscore')
request = require('request')
resolve = require('url').resolve
parse_links = require('parse-links')
utils = require('./utils')
timers = require('timers')
{exec} = require 'child_process'

Promise.resolveAll = (promiseArray) ->
  """
  resolve all promises in the passed array.
  unlike Promise.all(array), does not fail upon first failure.
  Instead, each promise resolves to an object:
    {state: "resolved|rejected", value|error: resp} 
  """
  resolvedPromiseArray = promiseArray.map((promise) ->
    promise.then(
      (resp) ->
        Promise.resolve({state: 'resolved', value: resp})
      (err) ->
        Promise.resolve({state: 'rejected', error: err})
    )
  )
  Promise.all(resolvedPromiseArray)

Promise.hashResolveAll = (promiseHash) ->
  """
  given a hash of promises, always resolved to a hash
  of results with a state==resolved|rejected and the value/error
  """
  keys = _.keys(promiseHash)
  promises = _.values(promiseHash)
  Promise.resolveAll(promises).then((resps) ->
    Promise.resolve(_.object(keys, resps))
  )


Promise.hashAll = (promiseHash) ->
  """
  given a hash of promises, return a hash of resolved values,
  or return the first error
  """
  keys = _.keys(promiseHash)
  promises = _.values(promiseHash)
  Promise.all(promises).then((resps) ->
    Promise.resolve(_.object(keys, resps))
  )

Promise.RestClient = (defaults) ->
  ###
  pass in opts for a request client (https://github.com/request/request)
  responses will return promises, rather than streams.
  request url will be resolved using opts.url as a base, so you don't 
  have to pass in fully qualified urls every time
  ###
  client = request.defaults(defaults)
  Client = {}
  ['get', 'put', 'post', 'del', 'head', 'patch'].forEach((method) ->
    Client[method] = Promise.denodeify((opts, callback) ->
      if typeof opts == 'string'
        opts = {url: opts}
      opts.url = resolve(defaults.url, opts.url)
      return client[method](opts, utils.process_resp(opts, callback))
    )
  )

  Client.get_all = (opts) ->
    ###
    get all results (following link headers)
    ** returns Promise **
    ###
    if typeof opts == 'string'
      opts = {url: opts}
    results = []
    handle_get = (resp) ->
      results = results.concat(resp.body)
      link_header = resp.headers.link
      links = parse_links(link_header) if link_header?
      opts.url = links?.next or null

      if opts.url
        return Client.get(opts).then(handle_get)
      else
        return Promise.resolve(results)
    return Client.get(opts).then(handle_get)

  Client.find_one = (opts, predicate) ->
    ###
    keep getting results (using link headers)until we find 
    one that matches predicate or we reach last result.
    ** returns Promise **
    ###
    if typeof opts == 'string'
      opts = {url: opts}
    handle_get = (resp) ->
      result = _.find(resp.body, predicate)
      link_header = resp.headers.link
      links = parse_links(link_header) if link_header?
      opts.url = links?.next or null

      if result or not opts.url
        return Promise.resolve(result)
      else
        return Client.get(opts).then(handle_get)
    return Client.get(opts).then(handle_get)

  return Client

Promise.setTimeout = Promise.denodeify((delay, args..., callback) ->
  timers.setTimeout.apply(null, [callback, delay].concat(args))
)

Promise.exec = Promise.denodeify(exec)

module.exports = Promise
