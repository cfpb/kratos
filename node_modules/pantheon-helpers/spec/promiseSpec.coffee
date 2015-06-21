Promise = require('../lib').promise

_handleError = (done) ->
  (err) ->
    done(err)

describe 'resolveAll', () ->
  it 'resolves successful promises to object with state==resolved', (done) ->
    Promise.resolveAll([Promise.resolve('success')]).then((resp) ->
      expect(resp).toEqual([{state:'resolved', value: 'success'}])
      done()
    ).catch(_handleError(done))

  it 'resolves rejected promises to object with state=rejected', (done) ->
    Promise.resolveAll([Promise.reject('failure')]).then((resp) ->
      expect(resp).toEqual([{state:'rejected', error: 'failure'}])
      done()
    ).catch(_handleError(done))

  it 'resolves regardless of failures or successes', (done) ->
    Promise.resolveAll([
      Promise.resolve('success')
      Promise.reject('failure')
      Promise.resolve('success')
    ]).then((resp) ->
      expect(resp.length).toEqual(3)
      done()
    ).catch(_handleError(done))

describe 'hashResolveAll', () ->
  it 'accepts a hash of promises and returns a hash of result hashes with state and value/error', (done) ->
    Promise.hashResolveAll({
      a: Promise.resolve('success'),
      b: Promise.reject('failure'),
      c: Promise.resolve('success'),
    }).then((resp) ->
      expect(resp).toEqual({
        a: {state:'resolved', value: 'success'},
        b: {state:'rejected', error: 'failure'},
        c: {state:'resolved', value: 'success'},
      })
      done()
    ).catch(_handleError(done))

describe 'hashAll', () ->
  it 'accepts a hash of promises, and resolves to a corresponding hash of results', (done) ->
    Promise.hashAll({
      a: Promise.resolve('success a'),
      b: Promise.resolve('success b'),
    }).then((resp) ->
      expect(resp).toEqual({a: 'success a', b: 'success b'})
      done()
    ).catch(_handleError(done))
  it 'returns the first failure', (done) ->
    Promise.hashAll({
      a: Promise.resolve('success a'),
      b: Promise.reject('failure b'),
      c: Promise.resolve('success c'),
    }).catch((err) ->
      expect(err).toEqual('failure b')
      done()
    )
