###
These function are used throughout the library. Many provide cross-platform (server and browser)
support for frequently-used functions.
###

if exports?
  _ = require "underscore"

# this will eventually be i18n support
# _ is already taken by underscore.js
_i = (s) -> return s


interpolate = (s, args) ->
  ###
  simple string interpolation (thanks http:#djangosnippets.org/snippets/2074/)
  interpolate("%s %s", ["hello", "world"]) returns "hello world"
  ###
  i = 0
  return s.replace(
    /%(?:\(([^)]+)\))?([%diouxXeEfFgGcrs])/g,
    (match, v, t) ->
      if (t == "%") then return "%"
      return args[v || i++]
  )

ValidationError = (message, code, args...) ->
  ###
  raised by fields during validation
   * `message`:  the default error message to display
   * `code`: the code used to look up an overriding message in the `errorMessages` hash
   * `args...`: arguments used for interpolation with the error message.
  ###
  return {message: message, code: code, data: args }

strip = (str) ->
  ### remove leading and trailing white space ###
  return String(str).replace(/^\s*|\s*$/g, '')

objPop = (obj, key) ->
  out = obj[key]
  if out?
    delete obj[key]
  return out

isHash = (obj) ->
  _.isObject(obj) and not _.isArray(obj)

utils = 
  _i: _i
  interpolate: interpolate
  ValidationError: ValidationError
  strip: strip
  objPop: objPop
  isHash: isHash
if window?
  window.validoc = 
    utils: utils
else if exports?
  module.exports = utils