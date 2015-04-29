auth = require('../../../lib/validation').auth
kratos = auth.kratos

super_admin   = {name: 'admin'}
team_admin   = {name: 'etkdg394hpmujn', roles: []}
user         = {name: 'thubsn24joa5gk', roles: []}
kratos_admin = {name: 'nahubk_hpb49km', roles: ['kratos|admin']}
both_admin   = {name: 'ahbksexortixvi', roles: ['kratos|admin']}

team         = {roles: {admin: {members: ['etkdg394hpmujn', 'ahbksexortixvi']}}}

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
