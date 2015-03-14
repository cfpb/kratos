validation_helpers = require('../../../lib/design_docs/shared/validation_helpers')
_ = require('underscore')

describe 'is_super_admin', () ->
  it 'returns true when the user is the super admin', () ->
    actual = validation_helpers.is_super_admin({name: 'admin'})
    expect(actual).toBe(true)

  it 'returns false when the user is not super admin', () ->
    actual = validation_helpers.is_super_admin({name: 'asoetkhb48'})
    expect(actual).toBe(false)

describe 'get_new_audit_entries', () ->
  it 'returns a list of all audit entries added to the new doc', () ->
    old_doc = {audit: [1, 2, 3, 4]}
    new_doc = {audit: [1, 2, 3, 4, 5, 6]}
    actual = validation_helpers.get_new_audit_entries(new_doc, old_doc)
    expect(actual).toEqual([5,6])

  it 'returns an empty list if there are no new audit entries', () ->
    old_doc = {audit: [1, 2, 3, 4]}
    new_doc = {audit: [1, 2, 3, 4]}
    actual = validation_helpers.get_new_audit_entries(new_doc, old_doc)
    expect(actual).toEqual([])

  it 'returns a list of new audit entries even if there is no old doc', () ->
    old_doc = null
    new_doc = {audit: [1]}
    actual = validation_helpers.get_new_audit_entries(new_doc, old_doc)
    expect(actual).toEqual([1])

user = {name: 'user'}
team = {roles: {}}
new_team = {roles: {}, updated: true}
entry = {
    "u": "user",
    "dt": 1418687484765,
    "a": "p",
    "k": "key",
    "v": "value"
}

get_entry = (updates) ->
  new_entry = _.clone(entry)
  _.extend(new_entry, updates)
  return new_entry

actions = 
  'p': () -> return true
  'p2': () -> return true
  'f': () -> return false

describe 'validate_audit_entry', () ->
  it 'passes the event, actor, old doc and new doc to the entry validation function', () ->
    e = get_entry({a: 's'})
    a = _.clone(actions)
    a.s = (event, actor, old_doc, new_doc) ->
      expect(event).toEqual(e)
      expect(actor).toEqual(user)
      expect(old_doc).toEqual(team)
      expect(new_doc).toEqual(new_team)
      return true
    validation_helpers.validate_audit_entry(a, e, user, team, new_team)

  it 'does not throw an error if the user can perform the action', () ->
    actual = () ->
      validation_helpers.validate_audit_entry(actions, get_entry(), user, team, new_team)
    expect(actual).not.toThrow()

  it 'throws an error if the user cannot perform the action', () ->
    actual = () ->
      validation_helpers.validate_audit_entry(actions, get_entry({a:'f'}), user, team, new_team)
    expect(actual).toThrow({ unauthorized: 'You do not have the privileges necessary to perform the action.' })

  it 'throws an error if the action is invalid', () ->
    e = get_entry({a: 'n'})
    actual = () ->
      validation_helpers.validate_audit_entry(actions, e, user, team, new_team)
    expect(actual).toThrow({ forbidden: 'Invalid action: ' + e.a + '.' })

  it 'throws an error if the entry user and logged in user do not match', () ->
    e = get_entry({u: 'different_user'})
    actual = () ->
      validation_helpers.validate_audit_entry(actions, e, user, team, new_team)
    expect(actual).toThrow({ forbidden: 'User performing action (' + e.u + ') does not match logged in user (' + user.name + ').' })

describe 'validate_audit_entries', () ->
  it 'does not throw an error if all entries are valid', () ->
    entries = [get_entry(), get_entry({a: 'p2'})]
    actual = () ->
      validation_helpers.validate_audit_entries(actions, entries, user, team, new_team)
    expect(actual).not.toThrow()
  it 'throws an error if any entry is invalid', () ->
    entries = [get_entry(), get_entry({a: 'f'})]
    actual = () ->
      validation_helpers.validate_audit_entries(actions, entries, user, team, new_team)
    expect(actual).toThrow({ unauthorized: 'You do not have the privileges necessary to perform the action.' })
  it 'passes the actions, event, actor, old_doc, and new_doc to validate_audit_entry', () ->
    spyOn(validation_helpers, 'validate_audit_entry').andCallFake(
      (actions, entry, actor, old_doc, new_doc) ->
        expect(actions).toEqual('actions')
        expect(entry).toEqual('entry')
        expect(actor).toEqual('actor')
        expect(old_doc).toEqual('old_doc')
        expect(new_doc).toEqual('new_doc')
        return true
    )    
    validation_helpers.validate_audit_entries('actions', ['entry'], 'actor', 'old_doc', 'new_doc')
