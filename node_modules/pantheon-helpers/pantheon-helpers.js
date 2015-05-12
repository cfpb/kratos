(function() {
  // this code can only be used in couchdb.
  module.exports = {
    design_docs: {
      audit: require('lib/pantheon-helpers-design-docs/audit'),
      do_action: require('lib/pantheon-helpers-design-docs/do_action'),
      helpers: require('lib/pantheon-helpers-design-docs/helpers'),
      validate_doc_update: require('lib/pantheon-helpers-design-docs/validate_doc_update')
    }
  };

}).call(this);
