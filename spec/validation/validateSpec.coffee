v = require('../../lib/validation')
validation = v.validation
auth = v.auth

describe '_is_team', () ->
  it 'returns true when the document is a team', () ->
    actual = v._is_team({_id: 'team_team_name'})
    expect(actual).toBe(true)

  it 'returns false when the document is not a team', () ->
    actual = v._is_team({_id: '_design/base'})
    expect(actual).toBe(false)

describe '_is_user', () ->
  it 'returns true when the document is a user', () ->
    actual = v._is_user({_id: 'org.couchdb.user:06e6b8b013b0a60c83332bc86a02bdc6'})
    expect(actual).toBe(true)

  it 'returns false when the document is not a user', () ->
    actual = v._is_user({_id: '_design/base'})
    expect(actual).toBe(false)

describe '_validate', () ->
  beforeEach () ->

  it 'calls the auth and validation "fn_name" functions specified by path with the auth and val args specified', () ->
    spyOn(validation, 'add_team').andReturn(true)
    spyOn(auth, 'add_team').andReturn(true)
    
    v._validate('add_team', ['actor'], ['team'])
    expect(auth.add_team).toHaveBeenCalledWith('actor')
    expect(validation.add_team).toHaveBeenCalledWith('team')

  it 'throws an auth error if authorization fails', () ->
    spyOn(validation, 'add_team').andReturn(true)
    spyOn(auth, 'add_team').andReturn(false)
  
    expect(() =>
      v._validate('add_team', ['actor'], ['team'])
      expect(auth.add_team).toHaveBeenCalledWith('actor')
      expect(validation.add_team).toHaveBeenCalledWith('team')
    ).toThrow({state: 'unauthorized', err: 'You do not have the privileges necessary to perform the action.'})

  it "throws a validation error with the validation fn's validation error if validation fails", () ->
    spyOn(validation, 'add_team').andCallFake(() -> throw("it's an error"))
    spyOn(auth, 'add_team').andReturn(true)
  
    expect(() =>
      v._validate('add_team', ['actor'], ['team'])
      expect(auth.add_team).toHaveBeenCalledWith('actor')
      expect(validation.add_team).toHaveBeenCalledWith('team')
    ).toThrow({state: 'invalid', err: "it's an error"})

  it "stringifies the fn's validation error if not already a string", () ->
    spyOn(validation, 'add_team').andCallFake(() -> throw({e: "it is an error"}))
    spyOn(auth, 'add_team').andReturn(true)

    expect(() =>
      v._validate('add_team', ['actor'], ['team'])
      expect(auth.add_team).toHaveBeenCalledWith('actor')
      expect(validation.add_team).toHaveBeenCalledWith('team')
    ).toThrow({state: 'invalid', err: '{"e":"it is an error"}'})

describe 'add_team', () ->
  it 'calls corresponding method in validation and auth', () ->
    spyOn(validation, 'add_team').andReturn(true)
    spyOn(auth, 'add_team').andReturn(true)
    actual = v.add_team('actor', 'team')
    expect(validation.add_team).toHaveBeenCalledWith('team')
    expect(auth.add_team).toHaveBeenCalledWith('actor')
    expect(actual).toBe(true)

describe 'remove_team', () ->
  it 'calls corresponding method in validation and auth', () ->
    spyOn(validation, 'remove_team').andReturn(true)
    spyOn(auth, 'remove_team').andReturn(true)
    actual = v.remove_team('actor', 'team')
    expect(validation.remove_team).toHaveBeenCalledWith('team')
    expect(auth.remove_team).toHaveBeenCalledWith('actor')
    expect(actual).toBe(true)

describe 'add_team_asset', () ->
  it 'calls corresponding method in validation and auth', () ->
    spyOn(validation, 'add_team_asset').andReturn(true)
    spyOn(auth, 'add_team_asset').andReturn(true)
    actual = v.add_team_asset('actor', 'team', 'resource', 'asset')
    expect(validation.add_team_asset).toHaveBeenCalledWith('team', 'resource', 'asset')
    expect(auth.add_team_asset).toHaveBeenCalledWith('actor', 'team', 'resource')
    expect(actual).toBe(true)

describe 'remove_team_asset', () ->
  it 'calls corresponding method in validation and auth', () ->
    spyOn(validation, 'remove_team_asset').andReturn(true)
    spyOn(auth, 'remove_team_asset').andReturn(true)
    actual = v.remove_team_asset('actor', 'team', 'resource', 'asset')
    expect(validation.remove_team_asset).toHaveBeenCalledWith('team', 'resource', 'asset')
    expect(auth.remove_team_asset).toHaveBeenCalledWith('actor', 'team', 'resource')
    expect(actual).toBe(true)

describe 'add_team_member', () ->
  it 'calls corresponding method in validation and auth', () ->
    spyOn(validation, 'add_team_member').andReturn(true)
    spyOn(auth, 'add_team_member').andReturn(true)
    actual = v.add_team_member('actor', 'team', 'user', 'role')
    expect(validation.add_team_member).toHaveBeenCalledWith('team', 'user', 'role')
    expect(auth.add_team_member).toHaveBeenCalledWith('actor', 'team', 'role')
    expect(actual).toBe(true)

describe 'remove_team_member', () ->
  it 'calls corresponding method in validation and auth', () ->
    spyOn(validation, 'remove_team_member').andReturn(true)
    spyOn(auth, 'remove_team_member').andReturn(true)
    actual = v.remove_team_member('actor', 'team', 'user', 'role')
    expect(validation.remove_team_member).toHaveBeenCalledWith('team', 'user', 'role')
    expect(auth.remove_team_member).toHaveBeenCalledWith('actor', 'team', 'role')
    expect(actual).toBe(true)

describe 'add_user', () ->
  it 'calls corresponding method in validation and auth', () ->
    spyOn(validation, 'add_user').andReturn(true)
    spyOn(auth, 'add_user').andReturn(true)
    actual = v.add_user('actor', 'user')
    expect(validation.add_user).toHaveBeenCalledWith('user')
    expect(auth.add_user).toHaveBeenCalledWith('actor')
    expect(actual).toBe(true)

describe 'remove_user', () ->
  it 'calls corresponding method in validation and auth', () ->
    spyOn(validation, 'remove_user').andReturn(true)
    spyOn(auth, 'remove_user').andReturn(true)
    actual = v.remove_user('actor', 'user')
    expect(validation.remove_user).toHaveBeenCalledWith('user')
    expect(auth.remove_user).toHaveBeenCalledWith('actor')
    expect(actual).toBe(true)

describe 'add_resource_role', () ->
  it 'calls corresponding method in validation and auth', () ->
    spyOn(validation, 'add_resource_role').andReturn(true)
    spyOn(auth, 'add_resource_role').andReturn(true)
    actual = v.add_resource_role('actor', 'user', 'resource', 'role')
    expect(validation.add_resource_role).toHaveBeenCalledWith('user', 'resource', 'role')
    expect(auth.add_resource_role).toHaveBeenCalledWith('actor', 'resource', 'role')
    expect(actual).toBe(true)

describe 'remove_resource_role', () ->
  it 'calls corresponding method in validation and auth', () ->
    spyOn(validation, 'remove_resource_role').andReturn(true)
    spyOn(auth, 'remove_resource_role').andReturn(true)
    actual = v.remove_resource_role('actor', 'user', 'resource', 'role')
    expect(validation.remove_resource_role).toHaveBeenCalledWith('user', 'resource', 'role')
    expect(auth.remove_resource_role).toHaveBeenCalledWith('actor', 'resource', 'role')
    expect(actual).toBe(true)
