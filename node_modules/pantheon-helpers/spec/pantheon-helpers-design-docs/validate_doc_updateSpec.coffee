v = require('../../lib/pantheon-helpers-design-docs/validate_doc_update')

describe 'validate_doc_update', () ->
  beforeEach () ->
    this.get_doc_type = jasmine.createSpy('get_doc_type').andReturn('team')
    this.should_skip_validation_for_user = jasmine.createSpy('should_skip_validation_for_user').andReturn(false)
    this.validation_fns = {
      team: {
        'u+': 'handle_u+'
        'u-': 'handle_u-'
      }
    }
    spyOn(v, 'get_new_audit_entries').andReturn(['entry', 'entry2'])
    spyOn(v, 'validate_audit_entries')
    this.validate_doc_update = v.validate_doc_update(this.validation_fns, this.get_doc_type, this.should_skip_validation_for_user)

  it 'gets the doc type from the passed get_doc_type fn', () ->
    this.validate_doc_update('new_doc', 'old_doc', 'user_ctx', 'sec_obj')
    expect(this.get_doc_type).toHaveBeenCalledWith('old_doc')

  it 'gets new audit entries from v.get_new_audit_entries', () ->
    this.validate_doc_update('new_doc', 'old_doc', 'user_ctx', 'sec_obj')
    expect(v.get_new_audit_entries).toHaveBeenCalledWith('new_doc', 'old_doc')

  it 'does not run validation if the should_skip_validation_for_user returns false for the actor (user_ctx)', () ->
    this.should_skip_validation_for_user.andReturn(true)
    this.validate_doc_update('new_doc', 'old_doc', 'user_ctx', 'sec_obj')
    expect(v.validate_audit_entries).not.toHaveBeenCalled()

  it 'does not run validation if there are no new audit entries', () ->
    v.get_new_audit_entries.andReturn([])
    this.validate_doc_update('new_doc', 'old_doc', 'user_ctx', 'sec_obj')
    expect(v.validate_audit_entries).not.toHaveBeenCalled()

  it 'does not run validation if the document type is not in validation_fns', () ->
    this.get_doc_type.andReturn('not_a_handled_doc_type')
    this.validate_doc_update('new_doc', 'old_doc', 'user_ctx', 'sec_obj')
    expect(v.validate_audit_entries).not.toHaveBeenCalled()

  it 'calls v.validate_audit_entries with the actions for the document type, the new audit entries, the user_ctx and the old and new docs', () ->
    this.validate_doc_update('new_doc', 'old_doc', 'user_ctx', 'sec_obj')
    expect(v.validate_audit_entries).toHaveBeenCalledWith(this.validation_fns.team, ['entry', 'entry2'], 'user_ctx', 'old_doc', 'new_doc')

  it 'does not require a should_skip_validation_for_user method; defaults to skipping nothing', () ->
    v.validate_doc_update(this.validation_fns, this.get_doc_type)
    this.validate_doc_update('new_doc', 'old_doc', 'user_ctx', 'sec_obj')
    expect(v.validate_audit_entries).toHaveBeenCalled()
 
describe 'get_new_audit_entries', () ->
  beforeEach () ->
    this.old_doc = {audit: [1,2]}
    this.new_doc = {audit: [1,2,3,4]}

  it 'returns the audit entries created during this update', () ->
    actual = v.get_new_audit_entries(this.new_doc, this.old_doc)
    expect(actual).toEqual([3,4])

  it 'returns all entries if there is no old doc (just created)', () ->
    actual = v.get_new_audit_entries(this.new_doc, null)
    expect(actual).toEqual([1,2,3,4])

  it 'throws an error if an old audit entry is modified when there is a new audit entry', () ->
    this.old_doc.audit[1] = 3
    expect(() ->
      actual = v.get_new_audit_entries(this.new_doc, this.old_doc)
    ).toThrow()

  it 'does not throw an error if an old audit entry is modified, but there are no new audit entries', () ->
      actual = v.get_new_audit_entries({audit: [1,2]}, {audit: [1,2]})
      expect(actual).toEqual([])

describe 'validate_audit_entries', () ->
  beforeEach () ->
    this.actions = {
      'u+': 'handle_u+'
      'u-': 'handle_u-'
    }
    spyOn(v, 'validate_audit_entry')
    this.entries = ['entry', 'entry2']

  it 'calls validate_audit_entry once for each entry', () ->
    v.validate_audit_entries(this.actions, this.entries, 'actor', 'old_doc', 'new_doc')
    expect(v.validate_audit_entry.calls.length).toEqual(2)
    expect(v.validate_audit_entry.calls[0].args[1]).toEqual('entry')
    expect(v.validate_audit_entry.calls[1].args[1]).toEqual('entry2')

  it 'calls validate_audit_entry with the entries for the doctype, the entry, actor, and old/new docs', () ->
    v.validate_audit_entries(this.actions, this.entries, 'actor', 'old_doc', 'new_doc')
    expect(v.validate_audit_entry).toHaveBeenCalledWith(this.actions, 'entry2', 'actor', 'old_doc', 'new_doc')

describe 'validate_audit_entry', () ->
  beforeEach () ->
    this.actions = {
      'success': jasmine.createSpy('success').andReturn(true)
      'auth_fail': jasmine.createSpy('auth_fail').andCallFake(() -> throw({state: 'unauthorized', err: 'authorization error'}))
      'validation_fail': jasmine.createSpy('validation_fail').andCallFake(() -> throw({state: 'invalid', err: 'validation error'}))
    }
    this.entry = {
      u: 'user1',
      a: 'success',
    }
    this.actor = {
      name: 'user1'
    }

  it 'throws an error if the entry user is not the same as the actor', () ->
    this.actor.name = 'user2'
    expect(() =>
      v.validate_audit_entry(this.actions, this.entry, this.actor, 'old_doc', 'new_doc')
    ).toThrow()

  it 'throws an error if the action type has no corresponding validation function in the actions', () ->
    this.entry.a = 'not_an_action'
    expect(() =>
      v.validate_audit_entry(this.actions, this.entry, this.actor, 'old_doc', 'new_doc')
    ).toThrow()

  it 'does nothing if the validation passes', () ->
    v.validate_audit_entry(this.actions, this.entry, this.actor, 'old_doc', 'new_doc')

  it 'throws an auth error if there is an auth failure', () ->
    this.entry.a = 'auth_fail'
    expect(() =>
      v.validate_audit_entry(this.actions, this.entry, this.actor, 'old_doc', 'new_doc')
    ).toThrow({unauthorized: 'authorization error'})

  it 'throws an invalid error if there is a validation failure', () ->
    this.entry.a = 'validation_fail'
    expect(() =>
      v.validate_audit_entry(this.actions, this.entry, this.actor, 'old_doc', 'new_doc')
    ).toThrow({forbidden: 'validation error'})
