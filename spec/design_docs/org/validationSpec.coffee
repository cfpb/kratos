validation = require('../../../lib/design_docs/org/lib/validate')
_ = require('underscore')

describe 'is_team', () ->
  it 'returns true when the document is a team', () ->
    actual = validation.is_team({_id: 'team_team_name'})
    expect(actual).toBe(true)

  it 'returns false when the document is not a team', () ->
    actual = validation.is_team({_id: '_design/base'})
    expect(actual).toBe(false)

# admin_user = {name: 'xxxx', roles: ['gh|user']}
# team = {roles: {admin: {members: ['xxxx']}}}
# regular_user = {name: 'yyyy'}
# super_admin_user = {name: 'admin'}
# role_entry = {
#     "u": "xxxx",
#     "dt": 1418687484765,
#     "a": "u+",
#     "k": "member",
#     "v": "new_user"
# }
# asset_entry = {
#     "u": "xxxx",
#     "dt": 1418687391245,
#     "a": "a+",
#     "k": "gh",
#     "v": {
#         "id": "c2b2fb49-5741-4a37-abfd-016cf3cd7226",
#         "new": "new_repo"
#     }
# }
# get_asset_entry = (updates) ->
#   entry = _.clone(asset_entry)
#   _.extend(entry, updates)
#   return entry
# get_role_entry = (updates) ->
#   entry = _.clone(role_entry)
#   _.extend(entry, updates)
#   return entry
