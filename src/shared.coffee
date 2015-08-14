s = {}

# change this if you do not like the default for specifying type: {"_id": "<type>_<id>"}
s.getDocType = (doc) ->
  """
  If you use this getDocType function, you MUST ALWAYS prepend
  the type name to the id, separated by an underscore.
  The special case is users, which CouchDB always prepends with `org.couchdb.user:`
  """
  if doc._id.indexOf('org.couchdb.user:') == 0
      return 'user'
  else if doc._id.indexOf('_') > 0
      return doc._id.split('_')[0]
  else
      return null

###
a hash of functions to modify a document in preparation for display to users
(filter out secrets, add metadata specific to the user, etc)
(doc, actor) -> return modifiedDoc
key is the document type, value is the function to prep that document type
###
s.prepDocFns = {
  user: (user) ->
    delete user.password_scheme
    delete user.iterations
    delete user.derived_key
    delete user.salt
    return user
}

s.prepDoc = (doc, actor) ->
  docType = s.getDocType(doc)
  prepDoc = s.prepDocFns[docType]
  if prepDoc
    doc = prepDoc(doc, actor)
  return doc

module.exports = s
