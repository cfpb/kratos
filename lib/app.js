// Generated by IcedCoffeeScript 1.8.0-c
(function() {
  var app, bodyParser, conf, express, middleware, routes, server, session;

  conf = require('./config');

  express = require('express');

  bodyParser = require('body-parser');

  session = require('cookie-session');

  routes = require('./routes');

  middleware = require('./middleware');

  app = express();

  app.use(bodyParser.json());

  app.use(middleware.auth_hack);

  app.use(session({
    secret: conf.SECRET_KEY,
    name: 'express_sess'
  }));

  app.use(middleware.couch);

  routes(app);

  server = app.listen(5000, function() {
    var host, port;
    host = server.address().address;
    port = server.address().port;
    return console.log('app listening at http://%s:%s', host, port);
  });

}).call(this);
