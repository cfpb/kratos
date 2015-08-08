api = require('./api')
{teams, users, user} = api
utils = require('./utils')
{auditRoutes} = require('pantheon-helpers')
couchUtils = require('./couch_utils')
validation = require('./validation')
express = require('express')

resourcePlugins = utils.getPlugins()

module.exports = (app) ->
  app.get('/kratos/orgs/:orgId/teams/', teams.handleGetTeams)
  app.route('/kratos/orgs/:orgId/teams/:teamId')
     .get(teams.handleGetTeam)
     # add new team - no body
     .put(teams.handleCreateTeam)

  app.get('/kratos/orgs/:orgId/teams/:teamId/details', teams.handleGetTeamDetails)

  app.route('/kratos/orgs/:orgId/teams/:teamId/roles/:role/:userId')
     # add user to team - no body
     .put(teams.handleAddMember)
     # remove user from team - no body
     .delete(teams.handleRemoveMember)

  # add asset to team - content_type=application/json; {new: <string>}
  app.post('/kratos/orgs/:orgId/teams/:teamId/resources/:resource/', teams.handleAddAsset)
  # remove asset from team - no body
  app.delete('/kratos/orgs/:orgId/teams/:teamId/resources/:resource/:assetId/', teams.handleRemoveAsset)


  # proxy resource actions
  for plugin in resourcePlugins
    if plugin.proxy
      pluginRouter = express.Router({mergeParams: true})
      plugin.proxy(pluginRouter, api, validation, couchUtils)
      app.use('/kratos/orgs/:orgId/teams/:teamId/resources/' + plugin.name, pluginRouter)

  app.route('/kratos/users')
     .get(users.handleGetUsers)
     .post(users.handleCreateUser)

  app.route('/kratos/users/:userId')
     .get(users.handleGetUser)
     # reactivate a deactivated user - no body
     .put(users.handleReactivateUser)
     # deactivate a user - no body
     .delete(users.handleDeactivateUser)

  app.route('/kratos/users/:userId/roles/:resource/:role')
     .put(users.handleAddRole)
     .delete(users.handleRemoveRole)

  # merge data at path with put data
  app.put('/kratos/users/:userId/data/:path?*', users.handleAddData)

  # get the current logged-in user
  app.get('/kratos/user', user.handleGetUser)

  auditRoutes(app, ['_users', 'org_devdesign'], couchUtils, '/kratos')
