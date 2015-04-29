a = require('../../../lib/design_docs/_users/lib/actions')
h = require('pantheon-helpers').design_docs.helpers

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
    a.do_actions.user['r+'](this.user, this.action, actor)
    expect(this.user.roles).toEqual(['kratos|admin'])

  it 'does not add the resource role to the user if already there', () ->
    this.user.roles = ['kratos|admin', 'gh|user']

    a.do_actions.user['r+'](this.user, this.action, actor)
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
    a.do_actions.user['r-'](this.user, this.action, actor)
    expect(this.user.roles).toEqual(['gh|user'])

  it 'does not remove the resource role from the user if not there', () ->
    this.user.roles = ['gh|user']

    a.do_actions.user['r-'](this.user, this.action, actor)
    expect(this.user.roles).toEqual(['gh|user'])

describe 'user_u+', () ->
  beforeEach () ->
    this.action = {a: 'u+'}
    this.user = {_id: 'user1', roles:[], audit: []}

  it 'adds the "kratos|enabled" resource role to the user, if not already there', () ->
    a.do_actions.user['u+'](this.user, this.action, actor)
    expect(this.user.roles).toEqual(['kratos|enabled'])

  it 'does not add the resource role to the user if already there', () ->
    this.user.roles = ['kratos|enabled', 'gh|user']

    a.do_actions.user['u+'](this.user, this.action, actor)
    expect(this.user.roles).toEqual(['kratos|enabled', 'gh|user'])

describe 'user_u-', () ->
  beforeEach () ->
    this.action = {a: 'u-'}
    this.user = {_id: 'user1', roles:['kratos|admin', 'gh|user', 'kratos|enabled'], audit: []}

  it 'removes all resource roles', () ->
    a.do_actions.user['u-'](this.user, this.action, actor)
    expect(this.user.roles).toEqual([])

describe 'user_d+', () ->
  beforeEach () ->
    this.action = {
      a: 'u-',
      path: ['x', 'y'],
      data: {a: 1, c: 3},
    }
    this.user = {_id: 'user1', data: {}, audit: []}

  it 'creates any objects along the path', () ->
    a.do_actions.user['d+'](this.user, this.action, actor)
    expect(this.user.data.x.y).toEqual({a:1, c:3})

  it 'merges the updated values into any existing object', () ->
    h.mk_objs(this.user, ['data', 'x', 'y'], {b: 2, c: 2.5})
    a.do_actions.user['d+'](this.user, this.action, actor)
    expect(this.user.data.x.y).toEqual({a:1, b:2, c:3})

  it 'errors if value is not an object', () ->
    expect(() ->
      this.action.path = []
      a.do_actions.user['d+'](this.user, this.action, actor)
    ).toThrow()