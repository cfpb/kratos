shared = require('../lib/shared')

describe 'getDocType', () ->
  it 'returns `user` when the doc is a user document (id starts with `org.couchdb.user:`', () ->
    cut = shared.getDocType

    actual = cut({_id: 'org.couchdb.user:cuwmg483cuhew'})

    expect(actual).toEqual('user')


  it 'returns the type as prepended to the _id, and separated by an _', () ->
    cut = shared.getDocType

    actual = cut({_id: 'type_cuwmg483cuhew'})

    expect(actual).toEqual('type')

  it 'returns null if there is no valid type to be pulled from the id', () ->
    cut = shared.getDocType

    actual = cut({_id: '_cuwmg483cuhew'})

    expect(actual).toEqual(null)

