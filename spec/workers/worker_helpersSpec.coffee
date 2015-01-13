worker = require('../../lib/worker_helpers')

describe 'get_handlers', () ->

  resources = 
    rsrc1:
      team:
        'u+': '1u+'
        'u-': '1u-'
        self:
          'a+': '1sa+'
        other:
          'a+': '1oa+'
    rsrc2:
      team:
        'u+': '2u+'
        self:
          'a+': '2sa+'
        other:
          'a+': '2oa+'

  event = {
    a: 'u+',
    k: 'rsrc1',
  }
  it 'returns a matching handler for each resource', () ->
    event = {a: 'u+'}
    handlers = worker.get_handlers(event, 'team', resources)
    expect(handlers).toEqual({rsrc1: '1u+', rsrc2: '2u+'})

  it 'returns the self handler for the event resource and an other handler for all other resources', () ->
    event = {a: 'a+', k: 'rsrc1'}
    handlers = worker.get_handlers(event, 'team', resources)
    expect(handlers).toEqual({rsrc1: '1sa+', rsrc2: '2oa+'})

  it 'only returns handlers that exist', () ->
    event = {a: 'u-'}
    handlers = worker.get_handlers(event, 'team', resources)
    expect(handlers).toEqual({rsrc1: '1u-'})
