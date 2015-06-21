utils = require('../lib').utils

describe 'mk_objs', () ->
  it 'traverses existing objects to return object at path', () ->
    obj = {a: {b: {c: 'd'}}}
    actual = utils.mk_objs(obj, ['a', 'b', 'c'])
    expect(actual).toEqual('d')

  it 'sets the item at path to be val, if the item does not exist', () ->
    obj = {a: {b: {}}}
    val = {}
    utils.mk_objs(obj, ['a', 'b', 'c'], val)    
    expect(obj.a.b.c).toBe(val)

  it 'defaults val to be an empty object', () ->
    obj = {a: {b: {}}}
    utils.mk_objs(obj, ['a', 'b', 'c'])
    expect(obj.a.b.c).toEqual({})

  it 'creates any missing objects on path', () ->
    obj = {a: {}}
    actual = utils.mk_objs(obj, ['a', 'b', 'c'])
    expect(obj).toEqual({a: {b: {c: {}}}})

  it 'returns the created object at path', () ->
    obj = {a: {}}
    actual = utils.mk_objs(obj, ['a', 'b', 'c'])
    expect(actual).toBe(obj.a.b.c)

  it 'errors if a traversed item is not an object', () ->
    expect(() ->
      obj = {a: 1}
      actual = utils.mk_objs(obj, ['a', 'b', 'c'])
    ).toThrow()

  it 'errors if a traversed item is an array', () ->
    expect(() ->
      obj = {a: []}
      actual = utils.mk_objs(obj, ['a', 'b', 'c'])
    ).toThrow()


describe 'process_resp', () ->
  it 'returns a standardized error message when there is an http error code', (done) ->
    callback = (err) ->
      expect(err).toEqual({err: null, msg: 'body', code: 404, req: { _headers : { header : 'header1' }, path : 'requested/path', method : 'GET' }})
      done()

    utils.process_resp({ignore_codes: [409]}, callback)(null, {statusCode:404, req: {_headers: {header: 'header1'}, path: 'requested/path', method: 'GET'}}, 'body')

  it 'returns a standardized error message when there is a connection error', (done) ->
    callback = (err) ->
      expect(err).toEqual({err: 'ENOENT', msg: null, code: undefined, req: {}})
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

  it 'returns the original resp/body when the error is in the ignore_codes array', (done) ->
    callback = (err, resp, body) ->
      expect(err).toEqual(null)
      expect(resp).toEqual({statusCode:409})
      expect(body).toEqual('body')
      done()

    utils.process_resp({ignore_codes: [409]}, callback)(null, {statusCode:409}, 'body')

  it 'returns only the body when body_only==true', (done) ->
    callback = (err, body) ->
      expect(err).toEqual(null)
      expect(body).toEqual('body')
      done()

    utils.process_resp({body_only: true}, callback)(null, {statusCode:200}, 'body')
