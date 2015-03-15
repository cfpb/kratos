v = require('../../lib/validation/validate')
validation = actual = v.validation
auth = actual = v.auth

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
