_ = require('underscore')
shared = require('./shared')
helpers = require('pantheon-helpers').design_docs.helpers(shared)

dd = 
  views:
    by_resource_id:
      map: (doc) ->
        for resource_name, resource of doc.rsrcs
          resource_id = resource.id
          if resource_id
            emit([resource_name, resource_id], doc.name)
    by_resource_username:
      map: (doc) ->
        auth = require('views/lib/auth')
        if not auth.is_active_user(doc)
          return
        for resource_name, resource of doc.rsrcs
          resource_username = resource.username
          if resource_username
            emit([resource_name, resource_username], doc.name)
    by_username:
      map: (doc) ->
        auth = require('views/lib/auth')
        if auth.is_active_user(doc) and doc.data.username
          emit(doc.data.username)
    by_name:
      map: (doc) ->
        auth = require('views/lib/auth')
        if auth._is_user(doc)
          emit([auth.is_active_user(doc), doc.name])
    by_auth:
      map: (doc) ->
        auth = require('views/lib/auth')
        if not auth.is_active_user(doc)
          return
        for role in doc.roles
          out = role.split('|')
          out.push(doc.name)
          emit(out)
    contractors:
      map: (doc) ->
        auth = require('views/lib/auth')
        if auth.is_active_user(doc)
          emit(doc.data?.contractor or false, doc.data.username)

  lists:
    get_users: (header, req) ->
      helpers.lists.get_prepped_of_type(getRow, start, send, 'user', header, req)
    get_user: (header, req) ->
      helpers.lists.get_first_prepped(getRow, start, send, header, req)

  shows:
    get_user: helpers.shows.get_prepped

  rewrites: [
    {
      from: "/users/:user_id",
      to: "/_show/get_user/:user_id",
      query: {},
    },
  ]

module.exports = dd
