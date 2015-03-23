utils = require('../lib/utils')

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
