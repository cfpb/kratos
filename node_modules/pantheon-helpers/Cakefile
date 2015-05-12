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

task 'test', 'run all tests', (options) ->
  if options.verbose
    cp = exec "jasmine-node --coffee --verbose ./spec"
  else
    cp = exec "jasmine-node --coffee ./spec"
  cp.stdout.pipe(process.stdout)
  cp.stderr.pipe(process.stderr)
