failures = require('../../lib/design_docs/pantheon/lib/app')

describe 'failures_by_retry_date', () ->
  beforeEach () ->
    failures.emitted = []

  it 'emits at most a single datestamp per document', () ->
    cut = failures.views.failures_by_retry_date.map

    cut({audit: [{attempts: [5, 3, 1]}, {attempts: [4]}]})

    actual = failures.emitted
    expect(actual.length).toEqual(1)

  it 'emits nothing if there are no failed attempts', () ->
    cut = failures.views.failures_by_retry_date.map

    cut({audit: [{synced: true}, {synced: true}]})

    actual = failures.emitted
    expect(actual.length).toEqual(0)

  it 'emits the smallest datestamp as a key, and no value', () ->
    cut = failures.views.failures_by_retry_date.map

    cut({audit: [{attempts: [5, 3, 1]}, {attempts: [4]}]})

    actual = failures.emitted
    expect(actual[0]).toEqual([4, undefined])
