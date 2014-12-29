auth = require('../../lib/auth/auth')

team_admin    = {name: 'etkdg394hpmujn', roles: []}
team_gh_admin = {name: 'nauhbkuwmkjvqq', roles: ['gh|user']}
user          = {name: 'thubsn24joa5gk', roles: []}
kratos_admin  = {name: 'nahubk_hpb49km', roles: ['kratos|admin']}
both_admin    = {name: 'ahbksexortixvi', roles: ['kratos|admin']}

team         = {roles: {admin: {members: ['etkdg394hpmujn', 'ahbksexortixvi', 'nauhbkuwmkjvqq']}}}


describe 'auth._has_resource_role', () ->
  it 'returns true if the user has the role for the resource', ->
    actual = auth._has_resource_role(kratos_admin, 'kratos', 'admin')
    expect(actual).toBe(true)

  it 'returns false if the user does not have the role for the resource', ->
    actual = auth._has_resource_role(user, 'kratos', 'admin')
    expect(actual).toBe(false)

describe 'auth._is_resource_admin', () ->
  it 'returns true if the user has is an admin for the resource', ->
    actual = auth._is_resource_admin(kratos_admin, 'kratos')
    expect(actual).toBe(true)

  it 'returns false if the user is not an admin for the resource', ->
    actual = auth._is_resource_admin(user, 'kratos')
    expect(actual).toBe(false)

describe 'auth._has_team_role', () ->
  it 'returns true if the user has the role for the team', ->
    actual = auth._has_team_role(team_admin, team, 'admin')
    expect(actual).toBe(true)

  it 'returns false if the user does not have the role for the team', ->
    actual = auth._has_team_role(user, team, 'admin')
    expect(actual).toBe(false)

describe 'auth._is_team_admin', () ->
  it 'returns true if the user has the admin role for the team', ->
    actual = auth._is_team_admin(team_admin, team)
    expect(actual).toBe(true)

  it 'returns false if the user does not have the role for the team', ->
    actual = auth._is_team_admin(user, team)
    expect(actual).toBe(false)
