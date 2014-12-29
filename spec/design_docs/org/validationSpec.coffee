validation = require('../../../lib/design_docs/org/lib/validation')
_ = require('underscore')

describe 'is_team', () ->
  it 'returns true when the document is a team', () ->
    actual = validation.is_team({_id: 'team_team_name'})
    expect(actual).toBe(true)

  it 'returns false when the document is not a team', () ->
    actual = validation.is_team({_id: '_design/base'})
    expect(actual).toBe(false)

describe 'is_super_admin', () ->
  it 'returns true when the user is the super admin', () ->
    actual = validation.is_super_admin({name: 'admin'})
    expect(actual).toBe(true)

  it 'returns false when the user is not super admi', () ->
    actual = validation.is_super_admin({name: 'asoetkhb48'})
    expect(actual).toBe(false)

describe 'get_new_audit_entries', () ->
  it 'returns a list of all audit entries added to the new doc', () ->
    old_doc = {audit: [1, 2, 3, 4]}
    new_doc = {audit: [1, 2, 3, 4, 5, 6]}
    actual = validation.get_new_audit_entries(new_doc, old_doc)
    expect(actual).toEqual([5,6])

  it 'returns an empty list if there are no new audit entries', () ->
    old_doc = {audit: [1, 2, 3, 4]}
    new_doc = {audit: [1, 2, 3, 4]}
    actual = validation.get_new_audit_entries(new_doc, old_doc)
    expect(actual).toEqual([])

  it 'returns a list of new audit entries even if there is no old doc', () ->
    old_doc = null
    new_doc = {audit: [1]}
    actual = validation.get_new_audit_entries(new_doc, old_doc)
    expect(actual).toEqual([1])

admin_user = {name: 'xxxx', roles: ['gh|user']}
team = {roles: {admin: {members: ['xxxx']}}}
regular_user = {name: 'yyyy'}
super_admin_user = {name: 'admin'}
role_entry = {
    "u": "xxxx",
    "dt": 1418687484765,
    "a": "u+",
    "k": "member",
    "v": "new_user"
}
asset_entry = {
    "u": "xxxx",
    "dt": 1418687391245,
    "a": "a+",
    "k": "gh",
    "v": {
        "id": "c2b2fb49-5741-4a37-abfd-016cf3cd7226",
        "new": "new_repo"
    }
}
get_asset_entry = (updates) ->
  entry = _.clone(asset_entry)
  _.extend(entry, updates)
  return entry
get_role_entry = (updates) ->
  entry = _.clone(role_entry)
  _.extend(entry, updates)
  return entry


describe 'validate_audit_entry', () ->

  it 'does not throw an error if the user can add a team member', () ->
    actual = () ->
      validation.validate_audit_entry(role_entry, admin_user, team)
    expect(actual).not.toThrow()
  it 'throws an error if the user cannot add a team member', () ->
    actual = () ->
      validation.validate_audit_entry(role_entry, regular_user, team)
    expect(actual).toThrow()

  it 'does not throw an error if the user can add an asset', () ->
    actual = () ->
      validation.validate_audit_entry(asset_entry, admin_user, team)
    expect(actual).not.toThrow()
  it 'throws an error if the user cannot add an asset', () ->
    actual = () ->
      validation.validate_audit_entry(asset_entry, regular_user, team)
    expect(actual).toThrow()

  it 'does not throw an error if the user can remove an asset', () ->
    entry = get_asset_entry({a: 'a-'})
    actual = () ->
      validation.validate_audit_entry(entry, admin_user, team)
    expect(actual).not.toThrow()
  it 'throws an error if the user cannot remove an asset', () ->
    entry = get_asset_entry({a: 'a-'})
    actual = () ->
      validation.validate_audit_entry(entry, regular_user, team)
    expect(actual).toThrow()

  it 'does not throw an error if the user can remove a role', () ->
    entry = get_role_entry({a: 'u-'})
    actual = () ->
      validation.validate_audit_entry(entry, admin_user, team)
    expect(actual).not.toThrow()
  it 'throws an error if the user cannot remove a role', () ->
    entry = get_role_entry({a: 'u-'})
    actual = () ->
      validation.validate_audit_entry(entry, regular_user, team)
    expect(actual).toThrow()

  it 'throws an error if the resource is invalid', () ->
    entry = get_asset_entry({k: 'notaresource'})
    actual = () ->
      validation.validate_audit_entry(entry, admin_user, team)
    expect(actual).toThrow()

  it 'throws an error if the action is invalid', () ->
    entry = get_asset_entry({a: 'z!'})
    actual = () ->
      validation.validate_audit_entry(entry, admin_user, team)
    expect(actual).toThrow()

  it 'throws an error if the entry user and logged in user do not match', () ->
    entry = get_asset_entry({u: 'yyyy'})
    actual = () ->
      validation.validate_audit_entry(entry, admin_user, team)
    expect(actual).toThrow()

describe 'validate_audit_entries', () ->
  it 'does not throw an error if all entries are valid', () ->
    entries = [asset_entry, role_entry]
    actual = () ->
      validation.validate_audit_entries(entries, admin_user, team)
    expect(actual).not.toThrow()
  it 'throws an error if any entry is invalid', () ->
    entry = get_role_entry({u: 'yyyy'})
    entries = [asset_entry, entry]
    actual = () ->
      validation.validate_audit_entries(entries, admin_user, team)
    expect(actual).toThrow()
