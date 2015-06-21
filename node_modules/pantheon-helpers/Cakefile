# copyright David Greisen licensed under Apache License v 2.0
# derived from code from ShareJS https://github.com/share/ShareJS (MIT)
{exec} = require 'child_process'
path = require('path')
fs = require('fs')
Promise = require('./lib/promise')

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
  Promise.exec("./node_modules/iced-coffee-script/bin/coffee --bare --compile --output ./spec/ ./spec/").then(() ->
    cmd = "./node_modules/istanbul/lib/cli.js cover ./node_modules/jasmine-node/bin/jasmine-node ./spec"
    cmd += if options.verbose then "--verbose " else ""
    cmd += " ./spec/"

    cp = exec(cmd)
    cp.stdout.pipe(process.stdout)
    cp.stderr.pipe(process.stderr)
    cp.on('exit', (code) -> process.exit(code))
  )
