auth = require('../../lib/auth/auth')
kratos = auth.kratos

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
  it 'allowed when user is a kratos admin adding a team admin', () ->
    actual = kratos.add_team_member(kratos_admin, team, 'admin')
    expect(actual).toBe(true)

  it 'allowed when user is a kratos admin adding a team non-admin admin', () ->
    actual = kratos.add_team_member(kratos_admin, team, 'member')
    expect(actual).toBe(true)

  it 'not allowed when user is a team admin adding a team admin', () ->
    actual = kratos.add_team_member(team_admin, team, 'admin')
    expect(actual).toBe(false)

  it 'allowed when user is a team admin adding a non-team admin', () ->
    actual = kratos.add_team_member(team_admin, team, 'member')
    expect(actual).toBe(true)

  it 'not allowed when user is not a kratos admin or a team admin', () ->
    actual = kratos.add_team_member(user, team, 'member')
    expect(actual).toBe(false)

describe 'remove_team_member', ->
  it 'allowed when user is a kratos admin adding a team admin', () ->
    actual = kratos.remove_team_member(kratos_admin, team, 'admin')
    expect(actual).toBe(true)

  it 'allowed when user is a kratos admin adding a team non-admin admin', () ->
    actual = kratos.remove_team_member(kratos_admin, team, 'member')
    expect(actual).toBe(true)

  it 'not allowed when user is a team admin adding a team admin', () ->
    actual = kratos.remove_team_member(team_admin, team, 'admin')
    expect(actual).toBe(false)

  it 'allowed when user is a team admin adding a non-team admin', () ->
    actual = kratos.remove_team_member(team_admin, team, 'member')
    expect(actual).toBe(true)

  it 'not allowed when user is not a kratos admin or a team admin', () ->
    actual = kratos.remove_team_member(user, team, 'member')
    expect(actual).toBe(false)
