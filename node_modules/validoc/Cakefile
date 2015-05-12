path = require('path')
fs = require('fs')
{exec} = require 'child_process'

DIR = __dirname

task 'build', 'Build the .js files', (options) ->
  console.log('Compiling Coffee from src to lib/validoc')
  cp = exec "coffee --compile --output ./lib/validoc ./src/"
  cp.stdout.pipe(process.stdout)
  cp.stderr.pipe(process.stderr)

task 'watch', 'Watch src directory and build the .js files', (options) ->
  console.log('Watching Coffee in src and compiling to lib/validoc')
  cp = exec "coffee --watch --output ./lib/validoc ./src/"
  cp.stdout.pipe(process.stdout)
  cp.stderr.pipe(process.stderr)

option '-v', '--verbose', 'verbose testing output'

task 'test', 'run all tests (options: -v)', (options) ->
  cmd = path.join(DIR, 'node_modules', 'jasmine-node', 'bin', 'jasmine-node')
  if options.verbose
    cp = exec cmd + " --coffee --verbose ./spec"
  else
    cp = exec cmd + " --coffee ./spec"
  cp.stdout.pipe(process.stdout)
  cp.stderr.pipe(process.stderr)
