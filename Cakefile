# copyright David Greisen licensed under Apache License v 2.0
# derived from code from ShareJS https://github.com/share/ShareJS (MIT)
{exec} = require 'child_process'
path = require('path')
fs = require('fs')
Promise = require('pantheon-helpers').promise

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
  cp = exec "nodemon --watch ./lib --ignore ./lib/design_docs ./lib/app.js"
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
  if not db_name
    throw(new Error('must specify db_name with `-n` or `--db_name`'))
  users_api = require('./lib/api/users')
  users_api.get_users('promise').then((users) ->
    if users.length
      return console.error('ERROR:: User database already contains users. This script can only import users into an empty _users database.')
    console.log('importing from github to ' + db_name)
    import_all = Promise.denodeify(require('./lib/resources/gh').import_all)
    import_all(db_name)
  ).then(() ->
    console.log('completed without error')
  (err) ->
    console.error('ERROR: ', err)
  )

task 'import_teams_from_gh', 'Import teams from Github - not idempotent!!', (options) ->
  db_name = options.db_name
  console.log('importing teams from github to ' + db_name)
  import_teams = Promise.denodeify(require('./lib/resources/gh').import_teams)
  import_teams(db_name, 'admin').then(() ->
    console.log('completed without error')
  (err) ->
    console.error('ERROR: ', err)
  )

option '-v', '--verbose', 'verbose testing output'

task 'test', 'run all tests', (options) ->
  Promise.exec("./node_modules/iced-coffee-script/bin/coffee --bare --compile --output ./spec/ ./spec/").then(() ->
    cmd = "./node_modules/istanbul/lib/cli.js cover ./node_modules/jasmine-node/bin/jasmine-node ./spec"
    cmd += if options.verbose then "--verbose " else ""
    cmd += " ./spec/"

    cp = exec(cmd)
    cp.stdout.pipe(process.stdout)
    cp.stderr.pipe(process.stderr)
    cp.on('exit', (code) -> process.exit(code))
  )
