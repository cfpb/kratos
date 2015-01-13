utils = require('../lib/utils')

describe 'process_resp', () ->
  it 'returns a standardized error message when there is a http error code', (done) ->
    callback = (err) ->
      expect(err).toEqual({err: null, msg: 'body', code: 404})
      done()

    utils.process_resp(callback)(null, {statusCode:404}, 'body')

  it 'returns a standardized error message when there is a connection error', (done) ->
    callback = (err) ->
      expect(err).toEqual({err: 'ENOENT', msg: null, code: undefined})
      done()

    utils.process_resp(callback)('ENOENT', null, null)

  it 'returns the original resp/body when there is an error', (done) ->
    callback = (err, resp, body) ->
      expect(resp).toEqual({statusCode:404})
      expect(body).toEqual('body')
      done()

    utils.process_resp(callback)(null, {statusCode:404}, 'body')

  it 'returns the original resp/body when there is no error', (done) ->
    callback = (err, resp, body) ->
      expect(err).toEqual(null)
      expect(resp).toEqual({statusCode:200})
      expect(body).toEqual('body')
      done()

    utils.process_resp(callback)(null, {statusCode:200}, 'body')

describe 'compact_hash', () ->
  it 'returns an object with only the truthy values', () ->
    initial_obj = {
      a: '',
      b: false,
      c: null,
      d: 'hello',
      e: 0,
      f: 4,
      g: undefined,
      h: true,
      i: [],
    }

    actual = utils.compact_hash(initial_obj)
    expect(actual).toEqual({
      d: 'hello',
      f: 4,
      h: true,
      i: [],
    })

  it 'returns a new object', () ->
    initial_obj = {
      a: '',
      b: false,
      c: null,
      d: 'hello',
      e: 0,
      f: 4,
      g: undefined,
      h: true,
      i: [],
    }

    actual = utils.compact_hash(initial_obj)
    expect(actual).not.toBe(initial_obj)
    expect(initial_obj.b).toBe(false)

  it 'returns undefined if there are no values', () ->
    initial_obj = {
      a: '',
      b: undefined,
    }

    actual = utils.compact_hash(initial_obj)
    expect(actual).toBe(undefined)
