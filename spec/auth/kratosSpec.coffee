auth = require('../../lib/auth/auth')
kratos = auth.kratos

super_admin   = {name: 'admin'}
team_admin   = {name: 'etkdg394hpmujn', roles: []}
user         = {name: 'thubsn24joa5gk', roles: []}
kratos_admin = {name: 'nahubk_hpb49km', roles: ['kratos|admin']}
both_admin   = {name: 'ahbksexortixvi', roles: ['kratos|admin']}

team         = {roles: {admin: {members: ['etkdg394hpmujn', 'ahbksexortixvi']}}}

describe 'add_team', () ->
  it 'allowed when user is a kratos admin', () ->
    actual = kratos.add_team(kratos_admin)
    expect(actual).toBe(true)
  it 'not allowed when user is not a kratos admin', () ->
    actual = kratos.add_team(user)
    expect(actual).toBe(false)

describe 'remove_team', () ->
  it 'allowed when user is a kratos admin', () ->
    actual = kratos.remove_team(kratos_admin)
    expect(actual).toBe(true)
  it 'not allowed when user is not a kratos admin', () ->
    actual = kratos.remove_team(user)
    expect(actual).toBe(false)

describe 'add_team_member', ->
  it 'not allowed when role does not exist', () ->
    actual = kratos.add_team_member(kratos_admin, team, 'xxx')
    expect(actual).toBe(false)

  it 'allowed when user is a kratos admin adding a team admin', () ->
    actual = kratos.add_team_member(kratos_admin, team, 'admin')
    expect(actual).toBe(true)

  it 'allowed when user is a kratos admin adding a team non-admin member', () ->
    actual = kratos.add_team_member(kratos_admin, team, 'member')
    expect(actual).toBe(true)

  it 'not allowed when user is a team admin adding a team admin', () ->
    actual = kratos.add_team_member(team_admin, team, 'admin')
    expect(actual).toBe(false)

  it 'allowed when user is a team admin adding a non-admin member', () ->
    actual = kratos.add_team_member(team_admin, team, 'member')
    expect(actual).toBe(true)

  it 'not allowed when user is not a kratos admin or a team admin', () ->
    actual = kratos.add_team_member(user, team, 'member')
    expect(actual).toBe(false)

describe 'remove_team_member', ->
  it 'not allowed when role does not exist', () ->
    actual = kratos.remove_team_member(kratos_admin, team, 'xxx')
    expect(actual).toBe(false)

  it 'allowed when user is a kratos admin adding a team admin', () ->
    actual = kratos.remove_team_member(kratos_admin, team, 'admin')
    expect(actual).toBe(true)

  it 'allowed when user is a kratos admin adding a team non-admin member', () ->
    actual = kratos.remove_team_member(kratos_admin, team, 'member')
    expect(actual).toBe(true)

  it 'not allowed when user is a team admin adding a team admin', () ->
    actual = kratos.remove_team_member(team_admin, team, 'admin')
    expect(actual).toBe(false)

  it 'allowed when user is a team admin adding a non-admin member', () ->
    actual = kratos.remove_team_member(team_admin, team, 'member')
    expect(actual).toBe(true)

  it 'not allowed when user is not a kratos admin or a team admin', () ->
    actual = kratos.remove_team_member(user, team, 'member')
    expect(actual).toBe(false)

describe 'add_resource_role', () ->
  it 'allowed when the user is a super admin', () ->
    actual = kratos.add_resource_role(super_admin, 'user')
    expect(actual).toBe(true)

  it 'now allowed when the user is not a super admin', () ->
    actual = kratos.add_resource_role(team_admin, 'user')
    expect(actual).toBe(false)

describe 'remove_resource_role', () ->
  it 'allowed when the user is a super admin', () ->
    actual = kratos.remove_resource_role(super_admin, 'user')
    expect(actual).toBe(true)
  it 'now allowed when the user is not a super admin', () ->
    actual = kratos.remove_resource_role(team_admin, 'user')
    expect(actual).toBe(false)
