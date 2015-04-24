auth = require('../../../lib/validation').auth

system_user         = {name: 'admin'}
team_admin          = {name: 'etkdg394hpmujn', roles: ['kratos|enabled']}
team_gh_admin       = {name: 'nauhbkuwmkjvqq', roles: ['gh|user', 'kratos|enabled']}
user                = {name: 'thubsn24joa5gk', roles: ['kratos|enabled']}
kratos_admin        = {name: 'nahubk_hpb49km', roles: ['kratos|admin', 'kratos|enabled']}
both_admin          = {name: 'ahbksexortixvi', roles: ['kratos|admin', 'kratos|enabled']}
disabled_both_admin = {name: 'jmhpduteuetojm', roles: ['kratos|admin', 'gh|user']}
team                = {roles: {admin: {members: ['etkdg394hpmujn', 'ahbksexortixvi', 'nauhbkuwmkjvqq', 'jmhpduteuetojm']}}}

describe 'auth.is_active_user', () ->
  it 'allowed if the user is not disabled', () ->
    actual = auth.is_active_user(user)
    expect(actual).toBe(true)

  it 'allowed if the user is the system user', () ->
    actual = auth.is_active_user(system_user)
    expect(actual).toBe(true)

  it 'not allowed if the user is disabled', () ->
    actual = auth.is_active_user(disabled_both_admin)
    expect(actual).toBe(false)

describe 'auth._has_resource_role', () ->
  it 'allowed if the user has the role for the resource', () ->
    actual = auth._has_resource_role(kratos_admin, 'kratos', 'admin')
    expect(actual).toBe(true)

  it 'allowed if the user is the system user', () ->
    actual = auth._has_resource_role(system_user, 'kratos')
    expect(actual).toBe(true)

  it 'not allowed if the user does not have the role for the resource', () ->
    actual = auth._has_resource_role(user, 'kratos', 'admin')
    expect(actual).toBe(false)

  it 'not allowed if the user is disabled', () ->
    actual = auth._has_resource_role(disabled_both_admin, 'kratos', 'admin')
    expect(actual).toBe(false)

describe 'auth._is_resource_admin', () ->
  it 'allowed if the user has is an admin for the resource', () ->
    actual = auth._is_resource_admin(kratos_admin, 'kratos')
    expect(actual).toBe(true)

  it 'not allowed if the user is not an admin for the resource', () ->
    actual = auth._is_resource_admin(user, 'kratos')
    expect(actual).toBe(false)

  it 'not allowed if the user is disabled', () ->
    actual = auth._is_resource_admin(disabled_both_admin, 'kratos', 'admin')
    expect(actual).toBe(false)

describe 'auth._has_team_role', () ->
  it 'allowed if the user has the role for the team', () ->
    actual = auth._has_team_role(team_admin, team, 'admin')
    expect(actual).toBe(true)

  it 'allowed if the user is the system user', () ->
    actual = auth._has_team_role(system_user, 'kratos')
    expect(actual).toBe(true)

  it 'not allowed if the user does not have the role for the team', () ->
    actual = auth._has_team_role(user, team, 'admin')
    expect(actual).toBe(false)

  it 'not allowed if the user is disabled', () ->
    actual = auth._has_team_role(disabled_both_admin, 'kratos', 'admin')
    expect(actual).toBe(false)

describe 'auth._is_team_admin', () ->
  it 'allowed if the user has the admin role for the team', () ->
    actual = auth._is_team_admin(team_admin, team)
    expect(actual).toBe(true)

  it 'not allowed if the user does not have the role for the team', () ->
    actual = auth._is_team_admin(user, team)
    expect(actual).toBe(false)

  it 'not allowed if the user is disabled', () ->
    actual = auth._is_team_admin(disabled_both_admin, 'kratos', 'admin')
    expect(actual).toBe(false)

describe 'auth.add_team_asset', () ->
  it 'calls the add_team_asset method of the resource and returns the result', () ->
    actual = auth.add_team_asset(team_gh_admin, team, 'gh')
    expect(actual).toBe(true)
  it 'not allowed if the resource does not exist', () ->
    actual = auth.add_team_asset(team_gh_admin, team, 'xx')
    expect(actual).toBe(false)
  it 'not allowed if the user is disabled', () ->
    actual = auth.add_team_asset(disabled_both_admin, team, 'gh')
    expect(actual).toBe(false)

describe 'auth.remove_team_asset', () ->
  it 'calls the remove_team_asset method of the resource and returns the result', () ->
    actual = auth.remove_team_asset(team_gh_admin, team, 'gh')
    expect(actual).toBe(true)
  it 'not allowed if the resource does not exist', () ->
    actual = auth.remove_team_asset(team_gh_admin, team, 'xx')
    expect(actual).toBe(false)
  it 'not allowed if the user is disabled', () ->
    actual = auth.remove_team_asset(disabled_both_admin, team, 'gh')
    expect(actual).toBe(false)

describe 'auth.add_resource_role', () ->
  it 'calls the add_resource_role method of the resource and returns the result', () ->
    actual = auth.add_resource_role(system_user, 'gh', 'user')
    expect(actual).toBe(true)
  it 'not allowed if the resource does not exist', () ->
    actual = auth.add_resource_role(system_user, 'xx', 'user')
    expect(actual).toBe(false)
  it 'not allowed if the user is disabled', () ->
    actual = auth.add_resource_role(disabled_both_admin, 'gh', 'user')
    expect(actual).toBe(false)

describe 'auth.remove_resource_role', () ->
  it 'calls the remove_resource_role method of the resource and returns the result', () ->
    actual = auth.remove_resource_role(system_user, 'gh', 'user')
    expect(actual).toBe(true)
  it 'not allowed if the resource does not exist', () ->
    actual = auth.remove_resource_role(system_user, 'xx', 'user')
    expect(actual).toBe(false)
  it 'not allowed if the user is disabled', () ->
    actual = auth.remove_resource_role(disabled_both_admin, 'gh', 'user')
    expect(actual).toBe(false)

describe 'add_user', () ->
  it 'allowed when user is a kratos admin', () ->
    actual = auth.add_user(kratos_admin)
    expect(actual).toBe(true)
  it 'not allowed when user is not a kratos admin', () ->
    actual = auth.add_user(user)
    expect(actual).toBe(false)

describe 'remove_user', () ->
  it 'allowed when user is a kratos admin', () ->
    actual = auth.remove_user(kratos_admin)
    expect(actual).toBe(true)
  it 'not allowed when user is not a kratos admin', () ->
    actual = auth.remove_user(user)
    expect(actual).toBe(false)

describe 'add_team', () ->
  it 'allowed when user is a kratos admin', () ->
    actual = auth.add_team(kratos_admin)
    expect(actual).toBe(true)
  it 'not allowed when user is not a kratos admin', () ->
    actual = auth.add_team(user)
    expect(actual).toBe(false)

describe 'remove_team', () ->
  it 'allowed when user is a kratos admin', () ->
    actual = auth.remove_team(kratos_admin)
    expect(actual).toBe(true)
  it 'not allowed when user is not a kratos admin', () ->
    actual = auth.remove_team(user)
    expect(actual).toBe(false)

describe 'add_team_member', ->
  it 'not allowed when role does not exist', () ->
    actual = auth.add_team_member(kratos_admin, team, 'xxx')
    expect(actual).toBe(false)

  it 'allowed when user is a kratos admin adding a team admin', () ->
    actual = auth.add_team_member(kratos_admin, team, 'admin')
    expect(actual).toBe(true)

  it 'allowed when user is a kratos admin adding a team non-admin member', () ->
    actual = auth.add_team_member(kratos_admin, team, 'member')
    expect(actual).toBe(true)

  it 'not allowed when user is a team admin adding a team admin', () ->
    actual = auth.add_team_member(team_admin, team, 'admin')
    expect(actual).toBe(false)

  it 'allowed when user is a team admin adding a non-admin member', () ->
    actual = auth.add_team_member(team_admin, team, 'member')
    expect(actual).toBe(true)

  it 'not allowed when user is not a kratos admin or a team admin', () ->
    actual = auth.add_team_member(user, team, 'member')
    expect(actual).toBe(false)

describe 'remove_team_member', ->
  it 'allowed when user is a kratos admin removing a role that does not exist', () ->
    actual = auth.remove_team_member(kratos_admin, team, 'xxx')
    expect(actual).toBe(true)

  it 'allowed when user is a team admin removing a role that does not exist', () ->
    actual = auth.remove_team_member(team_admin, team, 'xxx')
    expect(actual).toBe(true)

  it 'allowed when user is a kratos admin removing a team admin', () ->
    actual = auth.remove_team_member(kratos_admin, team, 'admin')
    expect(actual).toBe(true)

  it 'allowed when user is a kratos admin removing a team non-admin member', () ->
    actual = auth.remove_team_member(kratos_admin, team, 'member')
    expect(actual).toBe(true)

  it 'not allowed when user is a team admin removing a team admin', () ->
    actual = auth.remove_team_member(team_admin, team, 'admin')
    expect(actual).toBe(false)

  it 'allowed when user is a team admin removing a non-admin member', () ->
    actual = auth.remove_team_member(team_admin, team, 'member')
    expect(actual).toBe(true)

  it 'not allowed when user is not a kratos admin or a team admin', () ->
    actual = auth.remove_team_member(user, team, 'member')
    expect(actual).toBe(false)
