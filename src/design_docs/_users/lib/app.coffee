_ = require('underscore')
h = require('./helpers')
validate = require('./validation/index')
actions = require('./actions')
audit = require('pantheon-helpers').design_docs.audit


auth = validate.auth

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
      out = []
      while(row = getRow())
        doc = row.doc
        continue if not validate._is_user(doc)
        doc = h.sanitize_user(doc)
        out.push(doc)
      return JSON.stringify(out)
    get_user: (header, req) ->
      row = getRow()
      if row
        doc = h.sanitize_user(row.doc)
        return JSON.stringify(doc)
      else
        throw(['error', 'not_found', 'document matching query does not exist'])

  shows:
    get_user: (doc, req) ->
      user = h.sanitize_user(doc)
      user.perms = {
        team: {
          add: auth.add_team(user)
          remove: auth.remove_team(user)
        }
      }
      return {body: JSON.stringify(user), "headers" : {"Content-Type" : "application/json"}}

  validate_doc_update: actions.validate_doc_update

  updates:
    do_action: actions.do_action

  rewrites: [
    {
      from: "/users/:user_id",
      to: "/_show/get_user/:user_id",
      query: {},
    },
  ]

audit.mixin(dd)

module.exports = dd
