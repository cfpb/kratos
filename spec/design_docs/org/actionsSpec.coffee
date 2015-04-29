a = require('../../../lib/design_docs/org/lib/actions')
h = require('pantheon-helpers').design_docs.helpers

actor = {name: 'actor1'}

describe 'team_u+', () ->
  beforeEach () ->
    this.action = {
      a: 'u+',
      role: 'admin',
      user: 'user1',
    }
    this.team = {_id: 'team_test', roles: {}, audit: []}


  it 'adds the user to the role, if not already there', () ->
    a.do_actions.team['u+'](this.team, this.action, actor)
    expect(this.team.roles.admin.members[0]).toEqual('user1')

  it 'does not add the user if the user already has that role', () ->
    h.mk_objs(this.team.roles, ['admin','members'], ['user1', 'user3'])

    a.do_actions.team['u+'](this.team, this.action, actor)
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
    a.do_actions.team['u-'](this.team, this.action, actor)
    expect(this.team.roles.admin.members).toEqual(['user2'])

  it 'does not remove the user if the user is not a member', () ->
    this.team.roles.admin.members = ['user2']
    a.do_actions.team['u-'](this.team, this.action, actor)
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
    a.do_actions.team['a+'](this.team, this.action, actor)
    expect(this.team.rsrcs.gh.assets).toEqual([{id: 'asset1', name: 'asset1name'}])

  it 'does not add the asset if it already belongs to team', () ->
    h.mk_objs(this.team.rsrcs, ['gh','assets'], [{id: 'asset1'}, {id: 'asset3'}])

    a.do_actions.team['a+'](this.team, this.action, actor)
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
    a.do_actions.team['a-'](this.team, this.action, actor)
    expect(this.team.rsrcs.gh.assets).toEqual([{id: 'asset2'}])

  it 'does not remove the asset if not there', () ->
    this.team.rsrcs.gh.assets = [{id: 'asset2'}]
    a.do_actions.team['a-'](this.team, this.action, actor)
    expect(this.team.rsrcs.gh.assets).toEqual([{id: 'asset2'}])
