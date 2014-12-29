h = require('lib/helpers')
_ = require('lib/underscore')
auth = require('./auth/auth')

module.exports = 
  views:
    by_resource_id:
      map: (doc) ->
        for resource_name, resource of doc.rsrcs
          resource_id = resource.id
          if resource_id
            emit([resource_name, resource_id], doc.name)
    by_resource_username:
      map: (doc) ->
        for resource_name, resource of doc.rsrcs
          resource_username = resource.username || resource.login
          if resource_username
            emit([resource_name, resource_username], doc.name)
    by_username:
      map: (doc) ->
        if doc.username
          emit(doc.username)
    by_name:
      map: (doc) ->
        if doc.name
          emit(doc.name)
    by_auth:
      map: (doc) ->
        for role in doc.roles
          out = role.split('|')
          out.push(doc.name)
          emit(out)
    contractors:
      map: (doc) ->
        emit(doc.data?.contractor or false, doc.username)
  lists:
    get_users: (header, req) ->
      out = []
      while(row = getRow())
        doc = row.doc
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
          add: auth.kratos.add_team(user)
          remove: auth.kratos.remove_team(user)
        }
      }
      return {body: JSON.stringify(user), "headers" : {"Content-Type" : "application/json"}}
  updates:
    do_action: (user, req) ->
      if not user
        return [null, '{"status": "error", "msg": "user not found"}']
      body = JSON.parse(req.body)
      value = body.value
      action = body.action
      key = body.key
      acting_user = req.userCtx.name

      if action == 'r+'
        container = user.roles
        role = key + '|' + value
        if role in container
          return [null, JSON.stringify(h.sanitize_user(user))]
        else
          container.push(role)

      else if action == 'r-'
        container = user.roles
        role = key + '|' + value
        if role in container
          i = container.indexOf(role)
          container.splice(i, 1)
        else
          return [null, JSON.stringify(h.sanitize_user(user))]

      else
        return [null, '{"status": "error", "msg": "invalid action"}']

      user.audit.push({
        u: acting_user,
        dt: +new Date(),
        a: action,
        k: key,
        v: value,
        id: body.uuid,
      })
      return [user, JSON.stringify(h.sanitize_user(user))]




  rewrites: [
    {
      from: "/users",
      to: "/_list/get_users/by_username",
      method: 'GET',
      query: {include_docs: 'true'},
    },
    {
      from: "/users/:user_id",
      to: "/_show/get_user/:user_id",
      query: {},
    }
  ]
  validate_doc_update: (newDoc, oldDoc, userCtx, secObj) ->

