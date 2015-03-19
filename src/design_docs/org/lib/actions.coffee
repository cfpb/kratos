validate = require('./validation/validate')
do_action = require('./shared/do_action')
validate_doc_update = require('./shared/validate_doc_update').validate_doc_update
h = require('./helpers')

a = {}

a.do_actions =
  team:
    'u+': (team, action, actor) ->
      members = h.mk_objs(team.roles, [action.k, 'members'], [])
      h.insert_in_place(members, action.v)
    'u-': (team, action, actor) ->
      members = h.mk_objs(team.roles, [action.k, 'members'], [])
      h.remove_in_place(members, action.v)
    'a+': (team, action, actor) ->
      assets = h.mk_objs(team.rsrcs, [action.k, 'assets'], [])
      h.insert_in_place(assets, action.v)
    'a-': (team, action, actor) ->
      assets = h.mk_objs(team.rsrcs, [action.k, 'assets'], [])
      h.remove_in_place(assets, action.v)

a.validate_actions =
  team:
    't+': (event, actor, old_team, new_team) -> 
            validate.add_team(actor, new_team)
    'a+': (event, actor, old_team, new_team) -> 
            validate.add_team_asset(actor, old_team, event.k, event.r)
    'a-': (event, actor, old_team, new_team) -> 
            validate.remove_team_asset(actor, old_team, event.k, event.r)
    'u+': (event, actor, old_team, new_team) -> 
            validate.add_team_member(actor, old_team, null, event.k)
    'u-': (event, actor, old_team, new_team) -> 
            validate.remove_team_member(actor, old_team, null, event.k)

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