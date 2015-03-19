gh = (validation) ->
  validation.gh =
    add_team_asset: (team, asset) ->
    remove_team_asset: (team, asset) ->

if window?
  gh(window.kratos.validation.validation)
else if exports?
  module.exports = gh
