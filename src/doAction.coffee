validation = require('./validation')
validationFns = validation.actions
auth = validation.auth
doAction = require('pantheon-helpers').doAction
couchUtils = require('./couch_utils')
actionHandlers = require('./actions')
shared = require('./shared')
utils = require('./utils')

###
the TEAM prepDocFn requires the node-only validation library,
it therefore cannot be used in couch. We monkeypatch in node
to add it.
###
shared.prepDocFns.team = (team, actor) ->
  ###
  return a copy of the team with permissions metadata added to the roles and resources
  ###
  for rsrc_name in auth.resources
    rsrc_auth = auth[rsrc_name]

    perms = {
      add: rsrc_auth.add_team_asset(actor, team)
      remove: rsrc_auth.remove_team_asset(actor, team)
      proxy: {}
    }

    for proxyActionName, proxyActionFn of rsrc_auth.proxy or {}
      perms.proxy[proxyActionName] = proxyActionFn(actor, team)

    utils.mkObjs(team.rsrcs, [rsrc_name, 'perms'], perms)

  for role_name in auth.roles.team
    utils.mkObjs(team.roles, [role_name, 'perms'], {
      add: auth.add_team_member(actor, team, role_name)
      remove: auth.remove_team_member(actor, team, role_name)
    })
  return team

getDocType = shared.getDocType 

prepDoc = shared.prepDoc

module.exports = doAction(null,
                     couchUtils,
                     actionHandlers,
                     validationFns,
                     getDocType,
                     prepDoc,
                    )
