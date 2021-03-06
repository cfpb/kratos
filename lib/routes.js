// Generated by IcedCoffeeScript 1.8.0-c
(function() {
  var audit, teams, user, users;

  teams = require('./api/teams');

  users = require('./api/users');

  user = require('./api/user');

  audit = require('./api/audit');

  module.exports = function(app) {
    app.get('/kratos/orgs/:org_id/teams/', teams.handle_get_teams);
    app.route('/kratos/orgs/:org_id/teams/:team_id').get(teams.handle_get_team).put(teams.handle_create_team);
    app.get('/kratos/orgs/:org_id/teams/:team_id/details', teams.handle_get_team_details);
    app.route('/kratos/orgs/:org_id/teams/:team_id/roles/:role/:user_id').put(teams.handle_add_member)["delete"](teams.handle_remove_member);
    app.post('/kratos/orgs/:org_id/teams/:team_id/resources/:resource/', teams.handle_add_asset);
    app["delete"]('/kratos/orgs/:org_id/teams/:team_id/resources/:resource/:asset_id/', teams.handle_remove_asset);
    app.all('/kratos/orgs/:org_id/teams/:team_id/resources/:resource/:asset_id/:path*', teams.handle_proxy_action);
    app.route('/kratos/users').get(users.handle_get_users).post(users.handle_create_user);
    app.route('/kratos/users/:user_id').get(users.handle_get_user).put(users.handle_reactivate_user)["delete"](users.handle_deactivate_user);
    app.route('/kratos/users/:user_id/roles/:resource/:role').put(users.handle_add_role)["delete"](users.handle_remove_role);
    app.put('/kratos/users/:user_id/data/:path?*', users.handle_add_data);
    app.get('/kratos/user', user.handle_get_user);
    return app.get('/kratos/audit', audit.handleGetAudit);
  };

}).call(this);
