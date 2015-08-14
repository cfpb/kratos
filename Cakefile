# copyright David Greisen licensed under Apache License v 2.0
# derived from code from ShareJS https://github.com/share/ShareJS (MIT)
{exec} = require 'child_process'
path = require('path')
fs = require('fs')
Promise = require('pantheon-helpers').promise
{proxyExec} = require('pantheon-helpers').utils

DIR = __dirname

task 'build', 'Build the .js files', (options) ->
  console.log('Compiling Coffee from src to lib')
  proxyExec("coffee --compile --output ./lib/ ./src/", process)

task 'watch', 'Watch src directory and build the .js files', (options) ->
  console.log('Watching Coffee in src and compiling to lib')
  proxyExec("coffee --watch --output ./lib/ ./src/", process)

task 'runtestserver', 'Run the server (port 5000); restart on change', (options) ->
  console.log('Running the server on port 5000; restarting on change')
  proxyExec("coffee --watch --output ./lib/ ./src/", process)
  proxyExec("nodemon --watch ./lib --ignore ./lib/design_docs ./lib/app.js", process)

task 'runworker', 'Run the couchdb worker', (options) ->
  console.log('Running the couchdb worker')
  proxyExec("node ./lib/worker.js", process)

option '-t', '--db_type [type]', 'db type to update'

task 'sync_design_docs', 'sync all design docs with couchdb', (options) ->
  if options.db_type
    dbTypes = [options.db_type]
  else
    designDocsDir = path.join(DIR, 'lib', 'design_docs')
    designDocs = fs.readdirSync(designDocsDir)
    dbTypes = []
    designDocs.forEach((fileName) ->
      fileParts = fileName.split('.')
      dbTypes.push(fileParts[0]) if fileParts[1] == 'js'
    )
  for dbType in dbTypes
    console.log('Syncing couchdb ' + dbType + ' design docs ')
    require('./lib/couch_utils').sync_all_db_design_docs(dbType)

option '-n', '--db_name [name]', 'db name to import to'

task 'import_from_gh', 'Import from Github - not idempotent!!', (options) ->
  dbName = options.db_name
  if not dbName
    throw(new Error('must specify db_name with `-n` or `--db_name`'))
  usersApi = require('./lib/api/users')
  usersApi.getUsers(require('./lib/couch_utils').nano_system_user, 'promise').then((users) ->
    if users.length
      return console.error('ERROR:: User database already contains users. This script can only import users into an empty _users database.')
    console.log('importing from github to ' + dbName)
    importAll = Promise.denodeify(require('kratos-gh').import(require('./lib/couch_utils')).importAll)
    importAll(dbName)
  ).then(() ->
    console.log('completed without error')
  (err) ->
    console.error('ERROR: ', err)
  )

task 'import_teams_from_gh', 'Import teams from Github - not idempotent!!', (options) ->
  dbName = options.db_name
  console.log('importing teams from github to ' + dbName)
  importTeams = Promise.denodeify(require('kratos-gh').import(require('./lib/couch_utils')).importTeams)
  importTeams(dbName, 'admin').then(() ->
    console.log('completed without error')
  (err) ->
    console.error('ERROR: ', err)
  )

option '-v', '--verbose', 'verbose testing output'
option '-s', '--spec-only', 'run specs without coverage'
task 'test', 'run all tests', (options) ->
  cmd = "./node_modules/iced-coffee-script/bin/coffee --bare --compile --output ./_specjs/ ./spec/"
  proxyExec(cmd, process, () -> 
    cmd = if options['spec-only'] then "" else "./node_modules/istanbul/lib/cli.js cover "
    cmd += "./node_modules/jasmine-node/bin/jasmine-node "
    cmd += if options.verbose then "--verbose " else ""
    cmd += " ./_specjs/"
    proxyExec(cmd, process, (code) ->
      exec('rm -rf ./_specjs')
      process.exit(code)
    )
  )
