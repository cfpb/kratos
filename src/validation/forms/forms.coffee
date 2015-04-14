forms = (validation) ->
  validation.forms = {}

  require('./user_data')(validation.forms)

module.exports = forms
