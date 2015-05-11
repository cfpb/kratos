do_action = require('../../lib/pantheon-helpers-design-docs/do_action')

describe 'do_action', () ->
  beforeEach () ->
    this.actions =
      team:
        success: (team, action, actor) ->
          team.data.a = 'modified'
        noop: (team, action, actor) ->
          team.data.a = 'same'
        error: (team, action, actor) ->
          throw ('error handler error')
      create: 
        create_team: (team, action, actor) ->
          team.data = {}

    this.action = {
      a: 'success',
      k: 'k',
      v: 'v',
    }
    this.req = {
      userCtx: {name: '1234e3df'}
      body: JSON.stringify(this.action)
      uuid: 'couch-provided-uuid'
    }
    this.doc = {_id: 'team_test', data: {a:'same'}, audit: []}
    this.prep_doc = (doc) -> 
      doc.prepped = true
      return doc
    this.get_doc_type = (doc) ->
      return 'team'
    this.do_action = do_action(this.actions, this.get_doc_type)

  it 'errors if no valid action', () ->
    this.action.a = 'x'
    this.req.body = JSON.stringify(this.action)

    actual = this.do_action(this.doc, this.req)
    expect(actual).toEqual([null, {code : 403, body: '{"status":"error","msg":"invalid action \\\"x\\\" for doc type \\\"team\\\"."}'}])

  it 'errors if it does not know how to handle the document type', () ->
    actual = do_action(this.actions, (doc) -> return 'user')(this.doc, this.req)
    expect(actual).toEqual([null, {code : 403, body: '{"status":"error","msg":"invalid action \\\"success\\\" for doc type \\\"user\\\"."}'}])

  it "errors if the action handler throws an error, returning the handler's error", () ->
    this.action.a = 'error'
    this.req.body = JSON.stringify(this.action)

    actual = this.do_action(this.doc, this.req)
    expect(actual).toEqual([null, {code : 500, body: JSON.stringify({"status": "error", "msg": "error handler error"})}])

  it 'gets the handler for the action and calls handler with doc, action and actor', () ->
    spyOn(this.actions.team, 'success')

    actual = this.do_action(this.doc, this.req)
    expect(this.actions.team.success).toHaveBeenCalledWith(this.doc, this.action, this.req.userCtx)

  it 'gets a create handler if there is no doc, and calls handler with a skeleton doc, action and actor', () ->
    spyOn(this.actions.create, 'create_team')
    this.action.a = 'create_team'
    this.req.body = JSON.stringify(this.action)

    actual = this.do_action(null, this.req)
    expect(this.actions.create.create_team).toHaveBeenCalledWith({_id: 'couch-provided-uuid', audit: []}, this.action, this.req.userCtx)

  it 'does not save the doc if the doc has not changed', () ->
    this.action.a = 'noop'
    this.req.body = JSON.stringify(this.action)

    actual = this.do_action(this.doc, this.req)
    expect(actual[0]).toBeNull()

  it 'saves any modifications to the doc made by the handler', () ->
    actual = this.do_action(this.doc, this.req)
    expect(actual[0].data.a).toEqual('modified')

  it 'appends the action entry to audit, and adds user and datetime to entry', () ->
    actual = this.do_action(this.doc, this.req)
    entry = actual[0].audit[0]
    expect(entry.a).toEqual('success')
    expect(entry.k).toEqual('k')
    expect(entry.v).toEqual('v')
    expect(entry.u).toEqual('1234e3df')
    expect(typeof entry.dt).toEqual('number')

  it 'calls prep_doc with the document and the actor, if the prep_doc exists', () ->
    spyOn(this, 'prep_doc').andReturn({})
    actual = do_action(this.actions, this.get_doc_type, this.prep_doc)(this.doc, this.req)
    expect(this.prep_doc).toHaveBeenCalledWith(this.doc, this.req.userCtx)

  it 'returns the display doc after running it through prep_doc fn, and stringifying it', () ->
    actual = do_action(this.actions, this.get_doc_type, this.prep_doc)(this.doc, this.req)
    expect(JSON.parse(actual[1]).prepped).toEqual(true)

  it 'ensures the stored document is not modified by the prep_doc fn', () ->
    actual = do_action(this.actions, this.get_doc_type, this.prep_doc)(this.doc, this.req)
    expect(actual[0].prepped).toBeUndefined()
