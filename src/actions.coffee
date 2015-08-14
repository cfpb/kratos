utils = require('pantheon-helpers').utils
_ = require('underscore')

actionHandlers = {
  user:
    'r+': (user, action, actor) ->
      role = action.resource + '|' + action.role
      utils.insertInPlace(user.roles, role)
    'r-': (user, action, actor) ->
      role = action.resource + '|' + action.role
      utils.removeInPlace(user.roles, role)
    'u+': (user, action, actor) ->
      utils.insertInPlace(user.roles, 'kratos|enabled')
    'u-': (user, action, actor) ->
      user.roles = []
    'd+': (user, action, actor) ->
      path = ['data'].concat(action.path)
      value = action.data
      if not _.isObject(value) or _.isArray(value)
        throw new Error('value must be an object')
      merge_target = utils.mkObjs(user, path, {})
      _.extend(merge_target, value)
  team:
    'u+': (team, action, actor) ->
      members = utils.mkObjs(team.roles, [action.role, 'members'], [])
      utils.insertInPlace(members, action.user)
    'u-': (team, action, actor) ->
      members = utils.mkObjs(team.roles, [action.role, 'members'], [])
      utils.removeInPlace(members, action.user)
    'a+': (team, action, actor) ->
      action.asset.id = action.id
      assets = utils.mkObjs(team.rsrcs, [action.resource, 'assets'], [])
      utils.insertInPlaceById(assets, action.asset)
    'a-': (team, action, actor) ->
      assets = utils.mkObjs(team.rsrcs, [action.resource, 'assets'], [])
      removed_asset = utils.removeInPlaceById(assets, action.asset)
      if removed_asset
        action.asset = removed_asset
  create:
    'u+': (user, action, actor) ->
      _.extend(user, action.record, {
        _id: 'org.couchdb.user:' + user._id,
        type: 'user',
        name: user._id,
      })
    't+': (team, action, actor) ->
      _.extend(team, {
        _id: 'team_' + action.name,
        name: action.name,
        rsrcs: {},
        roles: {},
        enforce: []
      })
}

module.exports = actionHandlers
