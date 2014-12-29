auth = require('./auth/auth')

x = {}

x.mk_objs = (obj, path_array, val={}) ->
  ###
  make a set of nested object.

  obj = {'x': 1}
  mk_objs(obj, ['a', 'b'], ['1'])
  # returns []
  # obj now equals {'x': 1, 'a': {'b': ['1']}}

  return the val
  ###
  last_key = path_array.pop()
  for key in path_array
    if not obj[key]?
      obj[key] = {}
    obj = obj[key]
  if not obj[last_key]
    obj[last_key] = val
  return obj[last_key]


x.add_team_perms = (original_team, user) ->
  # deep cloning team
  team = JSON.parse(JSON.stringify(original_team))
  for rsrc_name in auth.resources
    rsrc_auth = auth[rsrc_name]
    perms = x.mk_objs(team.rsrcs, [rsrc_name, 'perms'], {
      add: rsrc_auth.add_team_asset(user, team)
      remove: rsrc_auth.remove_team_asset(user, team)
    })

  for role_name in auth.roles.team
    x.mk_objs(team.roles, [role_name, 'perms'], {
      add: auth.kratos.add_team_member(user, team, role_name)
      remove: auth.kratos.remove_team_member(user, team, role_name)
    })
  return team

module.exports = x
