# copyright David Greisen licensed under Apache License v 2.0
# derived from code from ShareJS https://github.com/share/ShareJS (MIT)
{exec} = require 'child_process'
path = require('path')
fs = require('fs')

DIR = __dirname

task 'build', 'Build the .js files', (options) ->
  console.log('Compiling Coffee from src to lib')
  cp = exec "iced --compile --output ./lib/ ./src/"
  cp.stdout.pipe(process.stdout)
  cp.stderr.pipe(process.stderr)

task 'watch', 'Watch src directory and build the .js files', (options) ->
  console.log('Watching Coffee in src and compiling to lib')
  cp = exec "iced --watch --output ./lib/ ./src/"
  cp.stdout.pipe(process.stdout)
  cp.stderr.pipe(process.stderr)

task 'runtestserver', 'Run the server (port 5000); restart on change', (options) ->
  console.log('Running the server on port 5000; restarting on change')
  cp = exec "iced --watch --output ./lib/ ./src/"
  cp.stdout.pipe(process.stdout)
  cp.stderr.pipe(process.stderr)
  cp = exec "supervisor -w ./lib ./lib/app.js"
  cp.stdout.pipe(process.stdout)
  cp.stderr.pipe(process.stderr)

task 'runworker', 'Run the couchdb worker', (options) ->
  console.log('Running the couchdb worker')
  cp = exec "node ./lib/worker.js"
  cp.stdout.pipe(process.stdout)
  cp.stderr.pipe(process.stderr)

option '-t', '--db_type [type]', 'db type to update'

task 'sync_design_docs', 'sync all design docs with couchdb', (options) ->
  if options.db_type
    db_types = [options.db_type]
  else
    design_docs_dir = path.join(DIR, 'lib', 'design_docs')
    design_docs = fs.readdirSync(design_docs_dir)
    db_types = []
    design_docs.forEach((file_name) ->
      file_parts = file_name.split('.')
      db_types.push(file_parts[0]) if file_parts[1] == 'js'
    )
  for db_type in db_types
    console.log('Syncing couchdb ' + db_type + ' design docs ')
    require('./lib/couch_utils').sync_all_db_design_docs(db_type)

option '-n', '--db_name [name]', 'db name to import to'

task 'import_from_gh', 'Import from Github - not idempotent!!', (options) ->
  db_name = options.db_name
  users_api = require('./lib/api/users')
  await users_api._get_users(defer(err, resp))
  return console.log(err) if err
  if resp.length
    return console.error('ERROR:: User database already contains users. This script can only import users into an empty _users database.')

  console.log('importing from github to ' + db_name)
  await require('./lib/resources/gh').import_all(db_name, defer(err))
  if err
    console.log(err)
  else
    console.log('completed without error')

task 'import_teams_from_gh', 'Import teams from Github - not idempotent!!', (options) ->
  db_name = options.db_name
  console.log('importing teams from github to ' + db_name)
  await require('./lib/resources/gh').import_teams(db_name, 'admin', defer(err))
  if err
    console.log(err)
  else
    console.log('completed without error')

option '-v', '--verbose', 'verbose testing output'

task 'test', 'run all tests', (options) ->
  if options.verbose
    cp = exec "jasmine-node --coffee --verbose ./spec"
  else
    cp = exec "jasmine-node --coffee ./spec"
  cp.stdout.pipe(process.stdout)
  cp.stderr.pipe(process.stderr)
