follow = require('follow')
worker = require('../lib').worker
Promise = require('promise')


describe 'get_handlers', () ->
  handlers = 
    team:
      'u+': '1u+'
      'u-': '1u-'
      'a+': '1sa+'
      'a+': '1oa+'

  event = {
    a: 'u+',
  }

  it 'returns a single matching handler with a null key', () ->
    event = {a: 'u+'}
    actual = worker.get_handlers(handlers, event, 'team')
    expect(actual).toEqual({null: '1u+'})

  it 'only returns handlers that exist', () ->
    event = {a: 'x-'}
    actual = worker.get_handlers(handlers, event, 'team')
    expect(actual).toEqual({})


describe 'get_plugin_handlers', () ->
  handlers = 
    plugin1:
      team:
        'u+': '1u+'
        'u-': '1u-'
        self:
          'a+': '1sa+'
        other:
          'a+': '1oa+'
    plugin2:
      team:
        'u+': '2u+'
        self:
          'a+': '2sa+'
        other:
          'a+': '2oa+'

  event = {
    a: 'u+',
    plugin: 'plugin1',
  }
  it 'returns a matching handler for each plugin', () ->
    event = {a: 'u+'}
    actual = worker.get_plugin_handlers(handlers, event, 'team')
    expect(actual).toEqual({plugin1: '1u+', plugin2: '2u+'})

  it 'returns the self handler for the event plugin and an other handler for all other plugins', () ->
    event = {a: 'a+', plugin: 'plugin1'}
    actual = worker.get_plugin_handlers(handlers, event, 'team')
    expect(actual).toEqual({plugin1: '1sa+', plugin2: '2oa+'})

  it 'only returns handlers that exist', () ->
    event = {a: 'u-'}
    actual = worker.get_plugin_handlers(handlers, event, 'team')
    expect(actual).toEqual({plugin1: '1u-'})


describe 'get_audit_entries_to_sync', () ->
  it 'returns audit entries that are unsynced', () ->
    doc = {audit:[{id: 'not-yet-synced'}]}

    actual = worker.get_audit_entries_to_sync(doc)
    expect(actual).toEqual([{id: 'not-yet-synced'}])

  it 'returns audit entries that failed, but do not have a retry time', () ->
    doc = {audit:[{id: 'failed-sync', synced: false}]}

    actual = worker.get_audit_entries_to_sync(doc)
    expect(actual).toEqual([{id: 'failed-sync', synced: false}])

  it 'returns audit entries that failed, but do not have a retry time', () ->
    doc = {audit:[{id: 'failed-sync', synced: false, attempts: [0]}]}

    actual = worker.get_audit_entries_to_sync(doc)
    expect(actual).toEqual([{id: 'failed-sync', synced: false, attempts: [0]}])

  it 'does not return audit entries that succeeded', () ->
    doc = {audit:[{id: 'successfully-synced', synced: true}]}

    actual = worker.get_audit_entries_to_sync(doc)
    expect(actual).toEqual([])

  it 'does not return audit entries that failed and have not reached their retry time', () ->
    doc = {audit:[{id: 'failed-sync', synced: false, attempts: [1e+100]}]}

    actual = worker.get_audit_entries_to_sync(doc)
    expect(actual).toEqual([])


describe 'get_next_attempt_time', () ->
  it 'returns a time one minute in the future when no previous attempts', () ->
    actual = worker.get_next_attempt_time(1, [])
    expect(actual).toEqual(1 + 1*60*1000)

  it 'returns a time two minutes in the future when a single previous attempt made', () ->
    actual = worker.get_next_attempt_time(1, [1])
    expect(actual).toEqual(1 + 2*60*1000)

  it 'returns a time 2^4 minutes in the future when four previous attempts made', () ->
    actual = worker.get_next_attempt_time(1, [1,2,3,4])
    expect(actual).toEqual(1 + 16*60*1000)


describe 'update_document_with_worker_result', () ->
  beforeEach () ->
    this.doc = {x: {y: {existing_data: '93c50'}}}
    this.update_document_with_worker_result = worker.update_document_with_worker_result(this.doc)

  it 'updates the dict in the document at `path` with the `data` dict in a successful result', () ->
    this.update_document_with_worker_result({state: 'resolved', value: {data: {remote_id: 'f29a4'}, path: ['x', 'y']}})
    expect(this.doc).toEqual({x: {y: {existing_data: '93c50', remote_id: 'f29a4'}}})

  it 'updates the dict in the document at `path` with the `data` dict in a failed result', () ->
    this.update_document_with_worker_result({state: 'rejected', error: {data: {remote_id: 'f29a4'}, path: ['x', 'y']}})
    expect(this.doc).toEqual({x: {y: {existing_data: '93c50', remote_id: 'f29a4'}}})

  it 'does not update the document if there is no path', () ->
    this.update_document_with_worker_result({state: 'resolved', value: {data: {remote_id: 'f29a4'}}})
    expect(this.doc).toEqual({x: {y: {existing_data: '93c50'}}})

  it 'does not update the document if there is no data', () ->
    this.update_document_with_worker_result({state: 'resolved', value: {path: []}})
    expect(this.doc).toEqual({x: {y: {existing_data: '93c50'}}})

  it 'does not update the document if there is no anything', () ->
    this.update_document_with_worker_result({state: 'resolved'})
    expect(this.doc).toEqual({x: {y: {existing_data: '93c50'}}})


describe 'update_audit_entry', () ->
  beforeEach () ->
    this.doc = 
      audit: [
        {id: '1', synced: true},
        {id: '2', synced: false},
        {id: '3'},
        {id: '4', synced: false, attempts: [50]}
      ]
    this.update_document_with_worker_result_response = jasmine.createSpy('update_document_with_worker_result_response')
    spyOn(worker, 'update_document_with_worker_result').andReturn(this.update_document_with_worker_result_response)
    spyOn(worker, 'get_next_attempt_time').andReturn(100)
    this.update_audit_entry = worker.update_audit_entry(this.doc)

  it 'sets synced to true if all handlers succeeded', () ->
    this.update_audit_entry({gh: {state: 'resolved'}, kratos: {state: 'resolved'}}, '2')
    expect(this.doc.audit[1].synced).toBe(true)

  it 'removes failed attempts array, if it exists, when all handlers succeeded', () ->
    this.update_audit_entry({gh: {state: 'resolved'}, kratos: {state: 'resolved'}}, '4')
    expect(this.doc.audit[3].attempts).toBe(undefined)

  it 'sets synced to false, calls get_next_attempt_time, and unshifts that into the attempts array if any handlers failed, and entry sync had not previously succeeded', () ->
    this.update_audit_entry({gh: {state: 'resolved'}, kratos: {state: 'rejected'}}, '3')
    expect(worker.get_next_attempt_time).toHaveBeenCalled()
    expect(this.doc.audit[2].synced).toBe(false)
    expect(this.doc.audit[2].attempts).toEqual([100])
    this.update_audit_entry({gh: {state: 'resolved'}, kratos: {state: 'rejected'}}, '4')
    expect(this.doc.audit[3].synced).toBe(false)
    expect(this.doc.audit[3].attempts).toEqual([100, 50])

  it 'does not set synced to false if entry sync had previously succeeded', () ->
    this.update_audit_entry({gh: {state: 'resolved'}, kratos: {state: 'rejected'}}, '1')
    expect(this.doc.audit[0].synced).toBe(true)

  it 'calls update_document_with_worker_result with doc', () ->
    this.update_audit_entry({gh: {state: 'resolved'}, kratos: {state: 'rejected'}}, '1')
    expect(worker.update_document_with_worker_result).toHaveBeenCalledWith(this.doc)

  it 'calls the function returned by update_document_with_worker_result once for each resource with a resource handler result and a resource', () ->
    this.update_audit_entry({gh: {state: 'resolved'}, kratos: {state: 'rejected'}}, '1')
    expect(this.update_document_with_worker_result_response.calls.length).toEqual(2)
    expect(this.update_document_with_worker_result_response.calls[0].args[0]).toEqual({state: 'resolved'})
    expect(this.update_document_with_worker_result_response.calls[0].args[1]).toEqual('gh')
    expect(this.update_document_with_worker_result_response.calls[1].args[1]).toEqual('kratos')


describe 'update_audit_entries', () ->

  beforeEach () ->
    that = this
    this.doc = {
      audit: [
        {id: '1', synced: true},
        {id: '2', synced: false},
        {id: '3'},
      ]
    }
    this.db = {
      get: (doc_id, callback) -> callback(null, that.doc)
      insert: (doc_id, callback) -> callback(null)
    }
    spyOn(this.db, 'get').andCallThrough()
    spyOn(this.db, 'insert').andCallThrough()
    this.update_audit_entry_response = jasmine.createSpy('update_audit_entry_response')
    spyOn(worker, 'update_audit_entry').andReturn(this.update_audit_entry_response)

    this.handler_results = {
      '1': {gh: {state: 'resolved'}, kratos: {state: 'resolved'}},
      '2': {gh: {state: 'resolved'}, kratos: {state: 'rejected'}},
    }

  it 'gets the doc using the passed db and doc_id', (done) ->
    worker.update_audit_entries(this.db, 'doc_id', this.handler_results).then(() =>
      expect(this.db.get).toHaveBeenCalledWith('doc_id', jasmine.any(Function))
      return done()
    ).catch(done)

  it 'calls update_audit_entry with the doc', (done) ->
    worker.update_audit_entries(this.db, 'doc_id', this.handler_results).then(() =>
      expect(worker.update_audit_entry).toHaveBeenCalledWith(this.doc)
      return done()
    ).catch(done)

  it 'calls the fn returned by update_audit_entry once for each entry with the entry_results and the entry_id', (done) ->
    worker.update_audit_entries(this.db, 'doc_id', this.handler_results).then(() =>
      expect(this.update_audit_entry_response.calls[0].args[0]).toBe(this.handler_results['1'])
      expect(this.update_audit_entry_response.calls[0].args[1]).toEqual('1')
      expect(this.update_audit_entry_response.calls[1].args[1]).toEqual('2')
      return done()
    ).catch(done)

  it 'saves the document if changes have been made', (done) ->
    this.update_audit_entry_response.andCallFake(() => this.doc.audit[1].synced = true)
    worker.update_audit_entries(this.db, 'doc_id', this.handler_results).then(() =>
      expect(this.db.insert).toHaveBeenCalledWith(this.doc, jasmine.any(Function))
      return done()
    ).catch(done)

  it 'does not save the document if changes have not been made', (done) ->
    worker.update_audit_entries(this.db, 'doc_id', this.handler_results).then(() =>
      expect(this.db.insert).not.toHaveBeenCalled()
      return done()
    ).catch(done)


describe 'on_change', () ->
  beforeEach () ->
    this.logger = logger = jasmine.createSpyObj('logger', ['child', 'info', 'error'])
    logger.child.andReturn(logger)
    this.get_doc_type = jasmine.createSpy('get_doc_type').andReturn('doc_type')

    this.gh_handler = jasmine.createSpy('gh_handler').andReturn(Promise.resolve({new_data: true}))
    this.kratos_handler = jasmine.createSpy('gh_handler').andReturn(Promise.reject())

    spyOn(worker, 'get_handlers').andReturn({gh: this.gh_handler, kratos: this.kratos_handler})
    spyOn(worker, 'get_audit_entries_to_sync').andReturn([{id: 'entry1'}, {id: 'entry2'}])
    spyOn(worker, 'update_audit_entries').andReturn(Promise.resolve())
    this.change = {doc: {_id: '123'}}
    this.on_change = worker.on_change(this.logger, 'db', 'handlers', this.get_doc_type, worker.get_handlers)

    this.expected_results =
      entry1:
        gh:
          {state: 'resolved', value: {new_data: true}}
        kratos:
          {state: 'rejected', error: undefined}
      entry2:
        gh:
          {state: 'resolved', value: {new_data: true}}
        kratos:
          {state: 'rejected', error: undefined}

  it 'gets unsynced audit entries from get_audit_entries_to_sync, passing in the doc from the change event', (done) ->
    this.on_change(this.change).then(() =>
      expect(worker.get_audit_entries_to_sync).toHaveBeenCalledWith(this.change.doc)
      done()
    ).catch(done)

  it 'gets the handlers for each unsynced entry by calling get_handlers with the resources, entry, and doc_type', (done) ->
    this.on_change(this.change).then(() =>
      expect(worker.get_handlers).toHaveBeenCalledWith('handlers', {'id': 'entry2'}, 'doc_type')
      done()
    ).catch(done)

  it 'calls each handler for each entry', (done) ->
    this.on_change(this.change).then(() =>
      expect(this.gh_handler.calls.length).toBe(2)
      expect(this.gh_handler.calls[0].args[0]).toEqual({id: 'entry1'})
      expect(this.gh_handler.calls[1].args[0]).toEqual({id: 'entry2'})
      expect(this.gh_handler.calls[0].args[1]).toEqual(this.change.doc)

      expect(this.kratos_handler.calls.length).toBe(2)
      expect(this.kratos_handler.calls[0].args[0]).toEqual({id: 'entry1'})
      expect(this.kratos_handler.calls[1].args[0]).toEqual({id: 'entry2'})
      expect(this.kratos_handler.calls[0].args[1]).toEqual(this.change.doc)

      done()
    ).catch(done)

  it 'formats all the responses from the handlers into a tree of hashes', (done) ->
    this.on_change(this.change).then(() =>
      expect(worker.update_audit_entries.calls[0].args[2]).toEqual(this.expected_results)
      done()
    ).catch(done)

  it 'calls update_audit_entries with the db, doc_id, and results', (done) ->
    this.on_change(this.change).then(() =>
      expect(worker.update_audit_entries).toHaveBeenCalledWith('db', this.change.doc._id, this.expected_results)
      done()
    ).catch(done)


describe 'processFailures', () ->
  beforeEach () ->
    this.db = {view: jasmine.createSpy('view')}
    this.onChange = jasmine.createSpy('onChange').andReturn(Promise.resolve())
    this.db.view.andReturn(Promise.resolve({rows: [{doc: {_id: 'a'}}, {doc: {_id: 'b'}}]}))
    this.processFailures = worker.processFailures(this.db, this.onChange)

  it 'gets the docs that are ready to be resynced', (done) ->
    this.processFailures().then(() =>
      expect(this.db.view.toHaveBeenCalled)
      done()      
    ).catch(done)

  it 'calls onChange on each doc ready to be resynced', (done) ->
    this.processFailures().then(() =>
      expect(this.onChange.calls.length).toEqual(2)
      expect(this.onChange.mostRecentCall.args[0]).toEqual({doc: {_id: 'b'}})
      done()      
    ).catch(done)


describe 'watchForFailures', () ->
  beforeEach () ->
    spyOn(worker, 'setInterval').andReturn('interval')
    spyOn(worker, 'processFailures').andReturn('function')

  it 'creates and returns an interval that calls the function returned by processFailures with specified period', () ->
    cut = worker.watchForFailures
    actual = cut('db', 'onChange', 2000)
    expect(worker.setInterval).toHaveBeenCalledWith('function', 2000)
    expect(worker.processFailures).toHaveBeenCalledWith('db', 'onChange')
    expect(actual).toEqual('interval')


describe 'start_worker', () ->
  beforeEach () ->
    this.db = {config: {url: 'url', db: 'db'}}
    this.logger = {
      info: () ->
      error: () ->
    }
    this.feedFollow = jasmine.createSpy('feedFollow')
    this.feedOn = jasmine.createSpy('feedOn')
    spyOn(follow, 'Feed').andReturn({follow: this.feedFollow, on: this.feedOn})
    spyOn(worker, 'on_change').andReturn('on_change')
    spyOn(worker, 'watchForFailures').andReturn('interval')

  it 'creates a new feed with opts from the passed nano db', () ->
    worker.start_worker(this.logger, this.db, 'handlers', 'get_doc_type')
    expect(follow.Feed).toHaveBeenCalledWith({db: 'url/db', include_docs: true})

  it 'attaches worker.on_change to the "change" event', () ->
    worker.start_worker(this.logger, this.db, 'handlers', 'get_doc_type', 'get_plugin_handlers')
    expect(worker.on_change).toHaveBeenCalledWith(this.logger, this.db, 'handlers', 'get_doc_type', 'get_plugin_handlers')
    expect(this.feedOn).toHaveBeenCalledWith('change', 'on_change')

  it 'starts following the feed', () ->
    worker.start_worker(this.logger, this.db, 'handlers', 'get_doc_type')
    expect(this.feedFollow).toHaveBeenCalled()

  it 'returns the feed and interval', () ->
    actual = worker.start_worker(this.logger, this.db, 'handlers', 'get_doc_type')
    expect(actual.feed.follow).toBeDefined()
    expect(actual.interval).toEqual('interval')
