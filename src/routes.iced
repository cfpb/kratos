teams = require('./api/teams')
users = require('./api/users')
user = require('./api/user')

module.exports = (app) ->
    app.get('/kratos/orgs/:org_id/teams/', teams.get_teams)
    app.get('/kratos/orgs/:org_id/teams/:team_id', teams.get_team)
    # add new team - no body
    app.put('/kratos/orgs/:org_id/teams/:team_id', teams.create_team)

    # add user to team - no body
    app.put('/kratos/orgs/:org_id/teams/:team_id/roles/:key/:value/', teams.add_remove_member_asset('u+'))
    # remove user from team - no body
    app.delete('/kratos/orgs/:org_id/teams/:team_id/roles/:key/:value/', teams.add_remove_member_asset('u-'))
    # add asset to team - content_type=application/json; {new: <string>}
    app.post('/kratos/orgs/:org_id/teams/:team_id/resources/:key/', teams.add_asset)
    # remove asset from team - no body
    app.delete('/kratos/orgs/:org_id/teams/:team_id/resources/:key/:value/', teams.add_remove_member_asset('a-'))

    app.get('/kratos/users', users.get_users)
    app.get('/kratos/users/:user_id', users.get_user)
    app.put('/kratos/users/:user_id/roles/:resource/:role', users.add_remove_role('r+'))
    app.delete('/kratos/users/:user_id/roles/:resource/:role', users.add_remove_role('r-'))

    # get the current logged-in user
    app.get('/kratos/user', user.get_user)

