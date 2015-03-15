validation = require('../../../lib/validation/validate').validation

super_admin         = {name: 'admin'}
team_admin          = {name: 'etkdg394hpmujn', roles: []}
team_gh_admin       = {name: 'nauhbkuwmkjvqq', roles: ['gh|user']}
user                = {name: 'thubsn24joa5gk', roles: []}
disabled_user       = {name: 'tbkuhdetmjenao', roles: ['kratos|disabled']}
kratos_admin        = {name: 'nahubk_hpb49km', roles: ['kratos|admin']}
both_admin          = {name: 'ahbksexortixvi', roles: ['kratos|admin']}
disabled_both_admin = {name: 'jmhpduteuetojm', roles: ['kratos|admin', 'gh|user', 'kratos|disabled']}
team                = {roles: {admin: {members: ['etkdg394hpmujn', 'ahbksexortixvi', 'nauhbkuwmkjvqq', 'jmhpduteuetojm']}}}


describe 'validation.remove_resource_role', () ->
  it 'returns true if the user is enabled and the role exists', ->
    actual = validation.remove_resource_role(user, 'gh', 'user')
    expect(actual).toBe(true)
  it 'returns true if the resource role does not exist', () ->
    actual = validation.remove_resource_role(super_admin, 'gh', 'xx')
    expect(actual).toBe(true)
  it 'returns true if the user is not enabled', () ->
    actual = validation.remove_resource_role(disabled_user, 'gh', 'user')
    expect(actual).toBe(true)

describe 'validation.add_resource_role', () ->
  it 'returns true if the user is enabled and the role exists', ->
    actual = validation.add_resource_role(user, 'gh', 'user')
    expect(actual).toBe(true)
  it 'returns false if the resource role does not exist', () ->
    actual = validation.add_resource_role(user, 'gh', 'xx')
    expect(actual).toBe(false)
  it 'returns false if the user is not enabled', () ->
    actual = validation.add_resource_role(disabled_user, 'gh', 'user')
    expect(actual).toBe(false)

describe 'validation.add_team_asset', () ->
  it 'delegates to the resource', () ->
    spyOn(validation.gh, 'add_team_asset').andReturn('xxx')
    actual = validation.add_team_asset(team, 'gh', {'a': 'b'})
    expect(actual).toEqual('xxx')
    expect(validation.gh.add_team_asset).toHaveBeenCalledWith(team, {'a': 'b'})

describe 'validation.remove_team_asset', () ->
  it 'delegates to the resource', () ->
    spyOn(validation.gh, 'remove_team_asset').andReturn('xxx')
    actual = validation.remove_team_asset(team, 'gh', {'a': 'b'})
    expect(actual).toEqual('xxx')
    expect(validation.gh.remove_team_asset).toHaveBeenCalledWith(team, {'a': 'b'})

describe 'add_team_member', ->
  it 'allowed when the role is an admin role', () ->
    actual = validation.add_team_member(team, user, 'admin')
    expect(actual).toBe(true)
  it 'allowed when the role is a non-admin role', () ->
    actual = validation.add_team_member(team, user, 'member')
    expect(actual).toBe(true)
  it 'not allowed when role does not exist', () ->
    actual = validation.add_team_member(team, user, 'xxx')
    expect(actual).toBe(false)
