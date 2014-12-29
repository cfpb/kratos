auth = require('../../lib/auth/auth')
gh = auth.gh

team_admin    = {name: 'etkdg394hpmujn', roles: []}
team_gh_admin = {name: 'nauhbkuwmkjvqq', roles: ['gh|user']}
user          = {name: 'thubsn24joa5gk', roles: []}
kratos_admin  = {name: 'nahubk_hpb49km', roles: ['kratos|admin']}
both_admin    = {name: 'ahbksexortixvi', roles: ['kratos|admin']}

team         = {roles: {admin: {members: ['etkdg394hpmujn', 'ahbksexortixvi', 'nauhbkuwmkjvqq']}}}

describe 'add_team_asset', ->
  it 'allowed when user is a kratos admin', () ->
    actual = gh.add_team_asset(kratos_admin, team)
    expect(actual).toBe(true)

  it 'allowed when user is a team admin and a gh user', () ->
    actual = gh.add_team_asset(team_gh_admin, team)
    expect(actual).toBe(true)

  it 'not allowed when user is a team admin but not a gh user', () ->
    actual = gh.add_team_asset(team_admin, team)
    expect(actual).toBe(false)

  it 'not allowed when user is not a kratos admin or a team admin', () ->
    actual = gh.add_team_asset(user, team)
    expect(actual).toBe(false)

describe 'remove_team_asset', ->
  it 'allowed when user is a kratos admin', () ->
    actual = gh.remove_team_asset(kratos_admin, team)
    expect(actual).toBe(true)

  it 'allowed when user is a team admin and a gh user', () ->
    actual = gh.remove_team_asset(team_gh_admin, team)
    expect(actual).toBe(true)

  it 'not allowed when user is a team admin but not a gh user', () ->
    actual = gh.remove_team_asset(team_admin, team)
    expect(actual).toBe(false)

  it 'not allowed when user is not a kratos admin or a team admin', () ->
    actual = gh.remove_team_asset(user, team)
    expect(actual).toBe(false)
