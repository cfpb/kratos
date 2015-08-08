actions = require('../lib/actions')
utils = require('pantheon-helpers').utils

actor = {name: 'actor1'}

describe 'user_r+', () ->
  beforeEach () ->
    this.action = {
      a: 'r+',
      resource: 'kratos',
      role: 'admin',
    }
    this.user = {_id: 'user1', roles:[], audit: []}

  it 'adds the resource role to the user, if not already there', () ->
    actions.user['r+'](this.user, this.action, actor)
    expect(this.user.roles).toEqual(['kratos|admin'])

  it 'does not add the resource role to the user if already there', () ->
    this.user.roles = ['kratos|admin', 'gh|user']

    actions.user['r+'](this.user, this.action, actor)
    expect(this.user.roles).toEqual(['kratos|admin', 'gh|user'])

describe 'user_r-', () ->
  beforeEach () ->
    this.action = {
      a: 'r-',
      resource: 'kratos',
      role: 'admin',
    }
    this.user = {_id: 'user1', roles:['kratos|admin', 'gh|user'], audit: []}

  it 'removes the resource role from the user, if there', () ->
    actions.user['r-'](this.user, this.action, actor)
    expect(this.user.roles).toEqual(['gh|user'])

  it 'does not remove the resource role from the user if not there', () ->
    this.user.roles = ['gh|user']

    actions.user['r-'](this.user, this.action, actor)
    expect(this.user.roles).toEqual(['gh|user'])

describe 'user_u+', () ->
  beforeEach () ->
    this.action = {a: 'u+'}
    this.user = {_id: 'user1', roles:[], audit: []}

  it 'adds the "kratos|enabled" resource role to the user, if not already there', () ->
    actions.user['u+'](this.user, this.action, actor)
    expect(this.user.roles).toEqual(['kratos|enabled'])

describe 'team_u+', () ->
  beforeEach () ->
    this.action = {
      a: 'u+',
      role: 'admin',
      user: 'user1',
    }
    this.team = {_id: 'team_test', roles: {}, audit: []}


  it 'adds the user to the role, if not already there', () ->
    actions.team['u+'](this.team, this.action, actor)
    expect(this.team.roles.admin.members[0]).toEqual('user1')

  it 'does not add the user if the user already has that role', () ->
    utils.mkObjs(this.team.roles, ['admin','members'], ['user1', 'user3'])

    actions.team['u+'](this.team, this.action, actor)
    expect(this.team.roles.admin.members).toEqual(['user1', 'user3'])

describe 'team_u-', () ->
  beforeEach () ->
    this.action = {
      a: 'u-',
      role: 'admin',
      user: 'user1',
    }
    this.team = {_id: 'team_test', roles: {admin: {members: ['user1', 'user2']}}, audit: []}
    

  it 'removes the user from the role, if there', () ->
    actions.team['u-'](this.team, this.action, actor)
    expect(this.team.roles.admin.members).toEqual(['user2'])

  it 'does not remove the user if the user is not a member', () ->
    this.team.roles.admin.members = ['user2']
    actions.team['u-'](this.team, this.action, actor)
    expect(this.team.roles.admin.members).toEqual(['user2'])


describe 'team_a+', () ->
  beforeEach () ->
    this.action = {
      a: 'a+',
      resource: 'gh',
      id: 'asset1'
      asset: {name: 'asset1name'},
    }
    this.team = {_id: 'team_test', rsrcs: {}, audit: []}

  it 'adds the asset to the team, if not already there', () ->
    actions.team['a+'](this.team, this.action, actor)
    expect(this.team.rsrcs.gh.assets).toEqual([{id: 'asset1', name: 'asset1name'}])

  it 'does not add the asset if it already belongs to team', () ->
    utils.mkObjs(this.team.rsrcs, ['gh','assets'], [{id: 'asset1'}, {id: 'asset3'}])

    actions.team['a+'](this.team, this.action, actor)
    expect(this.team.rsrcs.gh.assets).toEqual([{id: 'asset1'}, {id: 'asset3'}])


describe 'team_a-', () ->
  beforeEach () ->
    this.action = {
      a: 'a-',
      resource: 'gh',
      asset: {id: 'asset1'},
    }
    this.team = {_id: 'team_test', rsrcs: {'gh': {assets: [{id: 'asset1'}, {id: 'asset2'}]}}, audit: []}
    

  it 'removes the asset from the team, if there', () ->
    actions.team['a-'](this.team, this.action, actor)
    expect(this.team.rsrcs.gh.assets).toEqual([{id: 'asset2'}])

  it 'does not remove the asset if not there', () ->
    this.team.rsrcs.gh.assets = [{id: 'asset2'}]
    actions.team['a-'](this.team, this.action, actor)
    expect(this.team.rsrcs.gh.assets).toEqual([{id: 'asset2'}])
