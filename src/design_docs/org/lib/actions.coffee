validate = require('./validation/index')
do_action = require('pantheon-helpers').design_docs.do_action
validate_doc_update = require('pantheon-helpers').design_docs.validate_doc_update.validate_doc_update
h = require('./helpers')
_ = require('underscore')

a = {}

a.do_actions =
  team:
    'u+': (team, action, actor) ->
      members = h.mk_objs(team.roles, [action.role, 'members'], [])
      h.insert_in_place(members, action.user)
    'u-': (team, action, actor) ->
      members = h.mk_objs(team.roles, [action.role, 'members'], [])
      h.remove_in_place(members, action.user)
    'a+': (team, action, actor) ->
      action.asset.id = action.id
      assets = h.mk_objs(team.rsrcs, [action.resource, 'assets'], [])
      h.insert_in_place_by_id(assets, action.asset)
    'a-': (team, action, actor) ->
      assets = h.mk_objs(team.rsrcs, [action.resource, 'assets'], [])
      removed_asset = h.remove_in_place_by_id(assets, action.asset)
      if removed_asset
        action.asset = removed_asset
  create:
    't+': (team, action, actor) ->
      _.extend(team, {
        _id: 'team_' + action.name,
        name: action.name,
        rsrcs: {},
        roles: {},
        enforce: []
      })

a.validate_actions =
  team:
    't+': (event, actor, old_team, new_team) ->
            validate.add_team(actor, new_team)
    'a+': (event, actor, old_team, new_team) ->
            validate.add_team_asset(actor, old_team, event.resource, event.asset)
    'a-': (event, actor, old_team, new_team) ->
            validate.remove_team_asset(actor, old_team, event.resource, event.asset)
    'u+': (event, actor, old_team, new_team) ->
            validate.add_team_member(actor, old_team, null, event.role)
    'u-': (event, actor, old_team, new_team) ->
            validate.remove_team_member(actor, old_team, null, event.role)

a.do_action = do_action(
                a.do_actions,
                validate._get_doc_type,
                h.add_team_perms,
              )

a.validate_doc_update = validate_doc_update(
                          a.validate_actions,
                          validate._get_doc_type,
                        )
module.exports = a