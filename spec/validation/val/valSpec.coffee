validation = require('../../../lib/validation').validation

system_user         = {name: 'admin'}
team_admin          = {name: 'etkdg394hpmujn', roles: ['kratos|enabled']}
team_gh_admin       = {name: 'nauhbkuwmkjvqq', roles: ['gh|user', 'kratos|enabled']}
user                = {name: 'thubsn24joa5gk', roles: ['kratos|enabled']}
disabled_user       = {name: 'tbkuhdetmjenao', roles: []}
kratos_admin        = {name: 'nahubk_hpb49km', roles: ['kratos|admin', 'kratos|enabled']}
both_admin          = {name: 'ahbksexortixvi', roles: ['kratos|admin', 'kratos|enabled']}
disabled_both_admin = {name: 'jmhpduteuetojm', roles: ['kratos|admin', 'gh|user']}
team                = {roles: {admin: {members: ['etkdg394hpmujn', 'ahbksexortixvi', 'nauhbkuwmkjvqq', 'jmhpduteuetojm']}}}


describe 'validation.add_team_asset', () ->
  it 'delegates to the resource', () ->
    spyOn(validation.gh, 'add_team_asset').andReturn('xxx')
    actual = validation.add_team_asset(team, 'gh', {'a': 'b'})
    expect(actual).toEqual('xxx')
    expect(validation.gh.add_team_asset).toHaveBeenCalledWith(team, {'a': 'b'})
  it 'not allowed if the resource has no handler', () ->
    validation.test_resource = {}
    expect(() ->
      actual = validation.add_team_asset(team, 'test_resource', {'a': 'b'})
    ).toThrow('resource, test_resource, does not support adding assets')


describe 'validation.remove_team_asset', () ->
  it 'delegates to the resource', () ->
    spyOn(validation.gh, 'remove_team_asset').andReturn('xxx')
    actual = validation.remove_team_asset(team, 'gh', {'a': 'b'})
    expect(actual).toEqual('xxx')
    expect(validation.gh.remove_team_asset).toHaveBeenCalledWith(team, {'a': 'b'})
  it 'not allowed if the resource has no handler', () ->
    validation.test_resource = {}
    expect(() ->
      actual = validation.remove_team_asset(team, 'test_resource', {'a': 'b'})
    ).toThrow('resource, test_resource, does not support removing assets')

describe 'add_team_member', ->
  it 'allowed when the role is an admin role', () ->
    actual = validation.add_team_member(team, user, 'admin')
    expect(actual).toBeUndefined()
  it 'allowed when the role is a non-admin role', () ->
    actual = validation.add_team_member(team, user, 'member')
    expect(actual).toBeUndefined()
  it 'not allowed when role does not exist', () ->
    expect(() ->
      actual = validation.add_team_member(team, user, 'xxx')
    ).toThrow('invalid role: xxx')

describe 'add_resource_role', () ->
  it 'allowed when the user is enabled and the role exists', ->
    actual = validation.add_resource_role(user, 'gh', 'user')
    expect(actual).toBeUndefined()
  it 'not allowed if the resource role does not exist', () ->
    expect(() ->
      actual = validation.add_resource_role(user, 'gh', 'xxx')
    ).toThrow('invalid role: xxx')
  it 'not allowed if the user is not enabled', () ->
    expect(() ->
      actual = validation.add_resource_role(disabled_user, 'gh', 'user')
    ).toThrow('invalid user: tbkuhdetmjenao')

describe 'remove_resource_role', () ->
  it 'allowed if the user is enabled and the role exists', ->
    actual = validation.remove_resource_role(user, 'gh', 'user')
    expect(actual).toBeUndefined()
  it 'allowed if the resource role does not exist', () ->
    actual = validation.remove_resource_role(system_user, 'gh', 'xx')
    expect(actual).toBeUndefined()
  it 'allowed if the user is not enabled', () ->
    actual = validation.remove_resource_role(disabled_user, 'gh', 'user')
    expect(actual).toBeUndefined()

describe 'add_user_data', () ->
  it 'not allowed when setting value not in system schema', () ->
    old_user = {data: {username: 'user1'}}
    new_user = {data: {username: 'user1', xxyyzz: true}}
    expect(() ->
      actual = validation.add_user_data(system_user, old_user, new_user)
    ).toThrow()

  it 'allowed when system sets contractor', () ->
    old_user = {data: {username: 'user1'}}
    new_user = {data: {username: 'user1', contractor: true}}
    actual = validation.add_user_data(system_user, old_user, new_user)
    expect(actual).toBeUndefined()

  it 'not allowed when self sets contractor', () ->
    old_user = {name: user.name, data: {username: 'user1'}}
    new_user = {name: user.name, data: {username: 'user1', contractor: true}}
    expect(() ->
      actual = validation.add_user_data(user, old_user, new_user)
    ).toThrow()
