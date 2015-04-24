auth = require('./validation/index').auth
h = require('pantheon-helpers').design_docs.helpers

h.add_team_perms = (original_team, user) ->
  ###
  return a copy of the team with permissions metadata added to the roles and resources
  ###
  team = JSON.parse(JSON.stringify(original_team)) # deep cloning team
  for rsrc_name in auth.resources
    rsrc_auth = auth[rsrc_name]
    perms = h.mk_objs(team.rsrcs, [rsrc_name, 'perms'], {
      add: rsrc_auth.add_team_asset(user, team)
      remove: rsrc_auth.remove_team_asset(user, team)
    })

  for role_name in auth.roles.team
    h.mk_objs(team.roles, [role_name, 'perms'], {
      add: auth.add_team_member(user, team, role_name)
      remove: auth.remove_team_member(user, team, role_name)
    })
  return team

module.exports = h
