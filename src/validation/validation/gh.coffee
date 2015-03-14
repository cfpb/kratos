gh = (validation) ->
  validation.gh =
    add_team_asset: (team, asset) ->
      return true

    remove_team_asset: (team, asset) ->
      return true

if window?
  gh(window.kratos.validation.validation)
else if exports?
  module.exports = gh
