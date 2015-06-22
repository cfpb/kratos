# Pantheon Helpers

[![Build Status](https://travis-ci.org/cfpb/pantheon-helpers.svg?branch=master)](https://travis-ci.org/cfpb/pantheon-helpers)

[![Coverage Status](https://coveralls.io/repos/cfpb/pantheon-helpers/badge.svg)](https://coveralls.io/r/cfpb/pantheon-helpers)

## Description
The CFPB Pantheon of microservices help medium-sized development teams get their work done.
Pantheon Helpers is a small Node.js library to make it easier to build a microservice in Node.js with CouchDB.

## Features
This library makes it easy to build an application with the following features:

  * auditing
  * validation
  * rapid developement with a build script, and helpers for useful CouchDB and async promise patterns
  * asyncronous server actions to provide snappy api response times even when the actions kicked off by the api take a long time

Pantheon helpers provide a framework for handling "actions".
You:
  1. Define the actions your application will perform.
  2. Write an action transform function for each action. 
     The transform function takes an action and a CouchDB document,
     and idempotently transforms the document as required by the action.
  3. Write a validation function for each action.
     The validation function takes the action,
     the user who performed the action (the actor),
     and the old and new doc. It throws an error if
     the action was invalid or unauthorized.
  4. Write an asyncronous worker handler for any actions that result in side-effects. 
     The worker handler will be called _after_ the document has been written to the database,
     and _after_ a response has been sent to the client performing the action.
     The worker handler can run any slow, asyncronous code that the user shouldn't have to wait to complete before getting a response.
       For instance, updating a remote server with data uploaded by the action.

Pantheon provides all the plumbing to ensure that these functions are run at the right time,
in response to the right action,
have the expected result,
and are logged.

## Installation

In your microservice application's home directory, run:

    npm install git+https://github.com/cfpb/pantheon-helpers.git

    npm install -g coffee-script jasmine-node


## Lifecycle of an action

1) Perform an action:

```coffeescript
doAction = require('pantheon-helpers/lib/doAction')
doAction(dbClient, 'designDocName', docId, {a: 'action name', ...}, callback)
```

The dbClient must be bound to an authenticated user and a particular database.
The action hash must contain an `a` key with the action name,
and it may contain any other keys/values needed to perform the action.
It may not contain the following reserved keys:
`dt` (datetime stamp), `u` (user performing action),
and `id` (uuid of the action).

The result of doAction will be
(1) a stream, if no callback is specified,
(2) a callback called with the resulting doc (or error),
    if a callback function is specified, or
(3) a promise, if callback is the string `"promise"`. 

2) The action is sent to CouchDB where the `do_action` [update handler](https://wiki.apache.org/couchdb/Document_Update_Handlers) takes over.

3) The `do_action update handler` passes the event to its `action handler`.
Action handlers must be defined in the design doc.
Actions are defined for each document type;
you can also define actions that can create new documents. 

4) The action handler receives the existing document
(or a skeleton document if it needs to create a new doc),
the action hash passed into doAction,
and the user who performed the action 
(based on the user bound to the dbClient passed to `doAction`.
The action handler DOES NOT RETURN ANYTHING.
It must modify the passed document (and action hash if desired) in place.

5) If the action handler modified the document,
then the do_action update handler adds the action to the audit entry. 
If the document was not modified,
then the unmodified document is return as the response for `doAction`.

6) If the action modified the document,
then Couch next calls the validation function defined for the action.
Just like action handlers, they are defined for each document type.

7) The validation function is passed a the action hash,
the user that performed the action,
the document as it was before the action handler modified it,
and the document as modified by the action handler.
The validation function can perform any validation logic it wants given these inputs.
If the action as performed by the user was not valid or was unauthorized,
the validation function should throw an error hash. 
For an unauthorized action: 
`{state: 'unauthorized', err: 'descriptive error message'}`,
for an invalid action:
`{state: 'invalid', err: 'descriptive error message'}`

8a) If the validation function fails,
the document will not be modified,
and `doAction` will return an unauthorized or invalid error.

8b) If the validation function succeeds,
the modified document will be saved,
and `doAction` will return the updated document.

9) The worker process is constantly watching the database for changes.
When the document is saved,
the worker process will wake up,
determine which actions in the audit log have not been handled by the worker yet,
and call the appropriate worker handler for each action.
Just like action handlers and validation functions,
worker handlers are defined for each document type.

10) The worker handler is passed the action and the document.
The worker should do anything that has side effects/takes a long time,
such as spinning up a service, calling another api endpoint, etc.
Whatever is done MUST BE IDEMPOTENT. 
There is no guarantee that the action will only be run through a worker once.
The worker must return a Promise.
If the worker fails,
or partially fails,
at whatever it is trying to do,
it should return a rejected promise.
If it succeeds completely, it should return a resolved promise.

11) If the worker handler failed,
then the returned error will be logged,
and the action will me marked as failed so it can be retried at a later time.
The time to retry will be 1 minute for the first failure,
then 2, 4, 8, 16... for subsequent failures.
If the worker succeeded,
then the action will be marked as succeeding, so it is not tried again.
Regardless of whether the worker handler succeeded or failed,
if the value of the Promise returned by the worker handler is a hash that includes a `data` hash and a `path` array,
then the data hash will be merged with the hash in the document at path,
and the resulting document will be saved to the database.


## Usage
For the remainder of this guide,
we will be creating a microservice called "Sisyphus" in the directory `$SISYPHUS`.
If you would like to follow along,
create a directory for the project and run:

    export $SISYPHUS=/path/to/sisyphus/directory

Our microservice will have endpoints to let us:

  * create a boulder
  * start rolling the boulder up the hill
  * set the boulder rolling back down the hill
  * get the current state of the boulder

The boulder will take 2 minutes to roll uphill,
at which point it will escape Sisyphus 
and roll down the hill for 20 seconds.
Then the whole process can start over again.

### 1. Set up directory structure
There should already be a node_modules directory with pantheon-helpers within it.
If not, follow the installation instructions, above.

Execute the pantheon-helpers bootstrap script:

    $SISYPHUS/node_modules/pantheon-helpers/bootstrap

You should now have the following directory structure:

    $SISYPHUS
      |- Cakefile: build tool. Run `cake` within $SISYPHUS
         to see available commands and arguments
      |- spec: jasmine tests go here; recreate the src 
         directory structure to make it easy to find tests
          |- apis: tests for api route handlers go here
          |- design_docs: tests for design docs go here
      |- src: coffeescript source files go here
          |- config.coffee: configuration variables
          |- config_secret.coffee: secret config variables;
             ignored by git; imported by config.coffee
          |- couch_utils.coffee: couch utilities, bound to your
             couchdb instance defined in your config files
          |- loggers.coffee: web and worker [bunyan](https://github.com/trentm/node-bunyan) loggers,
             configurable via `config.LOGGERS.WEB` and `config.LOGGERS.WORKER`.
             You will need to modify your config to send the logs to the appropriate location
             (usually a file when in production).
          |- app.coffee: executing this file starts the
             web server
          |- worker.coffee: executing this file starts
             any/all backround workers
          |- .gitignore: ignores config_secret
          |- apis: api route handlers go here
          |- design_docs: files to be imported by Kanso into CouchDB design docs go here

      |- lib: javascript compiled from ./src by 
              `cake build` will go here
          |- design_docs: some uncompiled javascript 
             generated by `cake start_design_doc` will
             go here
              |- pantheon: a symlink to a kanso design doc to support such things as
                 retrying failed actions, and audit queries.

To complete the setup, 
You will need to set your CouchDB config variables so Sisyphus can access CouchDB in either:

 * $SISYPHUS/src/config.coffee
 * $SISYPHUS/src/config_secret.coffee

system username --
the username your application uses to log into CouchDB
-- and the CouchDB password that user uses.
However, you should not do this manually.
Instead, you should use the cfpb/pantheon ansible scripts.
See that repo's README for more info.


### 2. Getting ready to work
Run `cake watch`. This will watch for changes to .coffee files and compile them to javascript.


### 3. Set up your CouchDB database
#### CouchDB credentials
Add your CouchDB credentials to $SISYPHUS/src/config.coffee and $SISYPHUS/src/config_secret.coffee. You will need to specify a username and password with which to access couchdb. Make sure the password is in config_secret.coffee.

You should see that the `cake watch` recompiles both config files as soon as you save them. 
If you don't use `cake watch` you will need to run `cake build` every time you make a change.

Now, we need to create the database in CouchDB.
Go to `localhost:5984/_utils`, click "Create Database",
and create a database called `boulders`.
Replace `localhost:5984` with the host/port for your CouchDB instance.
You may need to have an admin create the database for you.


#### Design documents
We use [Kanso](http://kan.so/) to load Design Docs into CouchDB. 
Design Docs let us run custom code on CouchDB in a fashion similar to stored procedures in RDBMSs.
You should [familiarize yourself with CouchDB Design Docs](http://guide.couchdb.org/draft/design.html), if you are not already.

A CouchDB instance can have many databases. Each database can have
many design docs. It can become difficult to ensure design docs remain
up-to-date across all databases. Pantheon-helpers helps you manage your design docs.

To create a new design doc, run:

    cake start_design_doc

and enter `boulder` for name and `base boulder DB design doc` for description.

Now we have a skeleton design doc in `$SISYPHUS/src/design_docs/boulder`. 
The `./lib/app.coffee` is the primary entry point into your
design doc.
If you take a look, it has placeholders for some of the more common design document features.
Of particular note, are `audit.mixin` and `actions.mixin`. 
These add the actions functionality (from `./lib/actions.coffee`)
and audit functionality (from pantheon-helpers) to your design doc.
We will be modifying `./lib/actions.coffee` later to 
create the actions our app can perform.

If you look in `$SISYPHUS/lib/design_docs/boulder`,
you will see some files that are not in source.
First, is the `kanso.json` file, 
this is similar to node.js `package.json` or a bower `bower.json` file.
It tells kanso what to package up and send to couchdb.

Next is the `_security` file.
This is a json file that couchdb uses to manage permissions.
See http://docs.couchdb.org/en/latest/intro/security.html and
http://docs.couchdb.org/en/latest/api/database/security.html.
You should note that only the security document from the
first design doc defined for each database will be loaded.

Finally, in the `lib` subdirectory you will see a copy of underscore,
and a symlink to the `pantheon-helpers/lib/design_docs` folder.
Any files that you want to reference in your design doc must be in the `boulder` directory,
otherwise Kanso can't package them up.
So we add them here.

Now that we have created our design document,
we have associate it with a type of database.
To do this, we create a new file at
$SISYPHUS/src/design_docs/boulders.coffee with the following contents:

    module.exports = ['boulder']

This tells Pantheon to add the `boulder` design doc to every
single database that is (1) called `boulders` 
or (2) starts with `boulders_`.
If we wanted all those databases to also have another design doc installed, 
we would add the name of the desired design doc to the exported array.

### 3. Design the Sisyphus microservice
Rolling the boulder up the hill takes a long time (in web time): 2 minutes. 
When we make a request to roll the boulder up the hill,
we do not want to have to wait two minutes for a response.
Instead, we would like to receive a response instantly that our request to roll the boulder up the hill has been accepted and is being processed.
Then we want a background process to actually roll the boulder up the hill for two minutes.

Pantheon-helpers makes it easy to build this sort of decoupled application.
First, let's figure out what our data is going to look like,
then let's figure out what actions we want to be able to perform on that data.
Finally, we'll implement everything.

Our boulder is going to be represented by a json document.
We want to know whether it's rolling up the hill,
rolling down the hill, or at the bottom of the hill.
We're also curious about Zeus's reaction to events as they unfold.
We'll store Zeus's reaction to the most recent action right in the boulder document.
Thus, our json document will look like this:

    { "_id": "document ID"
    , "type": "boulder"
    , "status": "rolling up|rolling down|at bottom"
    , "zeus": 
      { "is": "expectant|delighted|satisfied|mirthful|vengeful"
      }
    }

That's pretty easy! 
We don't even have to worry about the _id.
CouchDB will create one for us if we don't set it explicitly.

We are going to need to transform our boulder document in four different ways:

  1. create a new boulder (`b+`)
  2. start rolling the boulder up the hill (`bu`)
  3. make the boulder slip away and roll back down the hill (`bd`)
  4. bring the boulder to rest at the bottom of the hill (`br`)

Obviously, we can never destroy a boulder since this is an eternal task.
Note that not all of these actions are actually correspond to an endpoint. 
For example, 
a `br` will only ever be called by a worker handling a `bd` event.

Now that we have created our design doc, we need to sync it with CouchDB. Just run

    Cake sync_design_docs

This will update all the design documents in all your CouchDB databases.

### 4. Testing
Testing is easy because the system is loosely coupled,
and each function you write 
(with the exception of worker handlers)
should have no side effects.

Because it is so easy, you should be writing a ton of tests.

You run your tests with `cake test`.
You will be writing your tests using jasmine-node,
so you will need to write tests against the [v1.3 api](http://jasmine.github.io/1.3/introduction.html).

You should set up $SISYPHUS/spec to mirror your $SISYPHUS/src directory.
Tests for, e.g., $SISYPHUS/src/design_docs/boulder/lib/actions.coffee 
should go in $SISYPHUS/src/design_docs/boulder/lib/actionsSpec.coffee.
The `Spec` postfix is needed so jasmine-node

You should make liberal use of jasmine spys to mock and spy on external dependencies.

There is already a .travis.yml file in your project skeleton.
All you need to do is turn your repo on in travis-ci.

### 5. Implement CouchDB actions
We will define our actions in `src/design_docs/boulder/lib/actions.coffee`.
We need to define:
  1. how to actually do the action, and
  2. how to validate when an action is allowed

Since most applications will have more than just one
document type, we define functions in relation to the
document type they can operate on.
We must also tell Pantheon-helpers how to tell the difference between document types.

In `src/design_docs/boulder/lib/actions.coffee`

```coffeescript
...

# define our get_doc_type function.
# will return boulder for boulder types
get_doc_type = (doc) -> return doc.type

# define our action handlers that will actually modify our doc
# in response to actions.
a.do_actions = {
  # we define all actions that can be performed on boulder docs
  boulder: {
    # an action is a function that receives the doc to be
    # acted on, the action to be performed, and the
    # user performing the action. It must update the
    # doc in place. The do_action framework ensures that the
    # document is saved only if the action handler actually
    # changed the document.
    'bu': (doc, action, actor) ->
      doc.status = 'rolling up'
    'bd': (doc, action, actor) ->
      doc.status = 'rolling down'
  }
  # we define all actions that create new docs here (since we 
  # wouldn't know the type of a new doc until after it is created)
  create: {
    'b+': (doc, action, actor) ->
      doc.type = 'boulder'
      doc.status = 'at bottom'
  }
}

# define our validation handlers that ensure that the action is valid.
a.validate_actions = {
  # we define validation handlers for our boulder docs
  boulder: {
    # throw an error if the action is invalid;
    bu: (event, actor, old_doc, new_doc) ->
      if old_doc.status != 'at bottom'
        throw {
          state: 'invalid', 
          err: 'cannot start rolling boulder up until it reaches bottom'
        }
    bd: (event, actor, old_doc, new_doc) ->
      if old_doc.status != 'rolling up'
        throw {
          state: 'invalid',
          err: 'cannot roll down until boulder has started rolling up'
        }

    # You must define a validation function for all
    # valid actions, even if there is no validation logic.
    # Since b+ is always valid, we have an empty method.

    # Validation for b+ is under the boulder doc_type, 
    # because the action handler defined above has already
    # run and the boulder document has been created by this point.
    b+: (event, actor, old_doc, new_doc) ->
  }
}

# we want to show how far up the hill Sisyphus is. 
# but we don't want to store this - it will change 
# moment by moment - so we are going to create a doc_prep
# function that takes a document and prepares it for
# display. If you are offended by the horrible hackiness
# of these calculations, you are encouraged to submit a 
# pull request.

# Now, whenever you perform an action, you will receive back
# a copy of the document with any modifications made by the
# prep_boulder_for_display function.

prep_boulder_for_display = (bouldDoc) ->
  # get the most recent action for this boulder
  last_action = bouldDoc.audit[bouldDoc.audit.length-1]

  now = +new Date()
  if not last_action or last_action.a = 'br'
    bouldDoc.hillPosition = 0

  else if last_action.a == 'bu'
    bouldDoc.hillPosition = Math.floor((now - last_action.dt)*.9/120, .9)

  else if last_action.a == 'bd'
    bouldDoc.hillPosition = Math.ceiling((now - last_action.dt)*.9/20, 0)

a.do_action = do_action(
                a.do_actions,
                get_doc_type,
                prep_boulder_for_display,
              )
...
```

We have now defined how an action modifies a document, and we have defined when an action is valid.

A couple of notes:
  * Handler and validation functions cannot have any side effects.
    You can't make http requests or grab other documents.
  * Validation functions must throw either 
    {state: 'invalid', err: 'msg'} or {state: 'unauthorized', err: 'msg'}

We have now setup our design documents so CouchDB can handle our actions.
How do we actually perform an action from Node.js?
Pantheon-helpers provides a helper function, `doAction` to make this easy:

```coffeescript  
# get an authenticated couch client pointing to the boulders database
db = require('./couch_utils').nano_system_user.use('boulders')

# import the do_action method
doAction = require('pantheon-helpers/lib/doAction')

# do the action, passing in the database, the design document name where the action is defined, the document ID (or `null` if this action creates a new doc), and the action.

# create a boulder
doAction(db, 'boulder', null, {a: 'b+'}, (err, boulder_doc) ->
  # start rolling the boulder up the hill
  doAction(db, 'boulder', boulder_doc._id, {a: 'bu'})
)
```

As you can see, an action is just a dictionary.
The action id is specified by the `a` key.
You can use any other keys you like, with the
exception of the reserved system keys:
`dt` (datetime stamp), `u` (user performing action),
and `id` (uuid of the action)
The entire action dictionary is passed to your handler,
validation, and worker functions, and is stored in the
audit log.


### 6. Create background worker
Our actions now modify our document,
but they don't do anything in "real life".
Let's change that.

Our background worker watches the database for changes.
Whenever an event happens,
the Worker will find the appropriate worker function for that event
and call it.

In `$SISYPHUS/src/worker.coffee`:

```coffeescript
...

db = couch_utils.nano_system_user.use('boulders')

# return a promise, rather than using callbacks
doAction = require('pantheon-helpers/lib/doAction')
Promise = require('pantheon-helpers/lib/promise')

handlers: {
  # worker functions for boulder documents
  boulder:
    'bu': (event, doc, logger) ->
      # wait two minutes, then fire off a 'bd' event
      Promise.setTimeout(120000).next(() ->
        doAction(db, doc._id, {a: 'bd'})
      ).next(() ->
        # determine how Zeus felt about it
        zeus_response = _.sample([
          'delighted', 'satisfied', 'mirthful', 'vengeful'
        ])
        # return that Zeus's response so we can store in in doc.
        Promise.resolve({data: {is: zeus_response} path: ['zeus']})
      )
    'bd': (event, doc, logger) ->
      # wait 20 second, then fire off a 'br' event
      Promise.setTimeout(20000).next(() ->
        doAction(db, doc._id, {a: 'br'})
      ).next(() ->
        # determine how Zeus felt about it
        zeus_reaction = _.sample(['expectant'])
        # return Zeus's reaction so we can store in in doc.
        # note that we _must_ return a promise, not a raw value.
        # the value returned by a handler must be a dictionary
        # the object pointed to by path into the doc must also be a dict.
        # the object pointed to by path will be updated with the data dict's contents.
        Promise.resolve({data: {is: zeus_reaction}, path: ['zeus']})
      )
    # we don't need to do anything when a boulder is created or comes to rest
    'b+': null
    'br': null
}

...
```

A couple things:
  * Worker handlers MUST return a promise.
  * Any `data` returned in the promise will be merged into the
    document at the specified `path`. 
    Thus both `data` and the object at `path` must be hashes.
  * If your worker handler errors out, then the event will be marked
    as having errored.
    While not implemented yet,
    pantheon-helpers will eventually log the exact error and retry at a later time
  * **logging:** 
    The fact that your handler has been called,
    as well as the response and state (resolved/rejected),
    is logged by pantheon helpers.
    If you want to log additional information, 
    you can use the logger,
    which is passed as the third argument to your worker handler.
    You can create a log entry by making a call such as `logger.info({optional: 'metadata'}, 'log msg')`.
    See https://github.com/trentm/node-bunyan for full documentation.
    The relevant metadata linking your log entry to the particular document/revision action with which it is being called has already been included in the logger, s
    o you do not have to add this metadata.

### 7. Create the API
To have a working app, now all we need to do is set up our api.

We have two endpoints: `/boulders` and `boulders/:boulderId`.
We will correspondingly implement our route handlers in
`$SISYPHUS/src/api/boulders.coffee`
and `$SISYPHUS/src/api/boulder.coffee`.

$SISYPHUS/src/api/boulders.coffee:

```coffeescript  
doAction = require('pantheon-helpers/lib/doAction')

b = {}

b.createBoulder = (db, callback) ->
  return doAction(db, 'boulder', null, {a: 'b+'}, callback)

b.handleCreateBoulder = (req, resp) ->
  db = req.couch.use('boulder')
  b.createBoulder(db).pipe(resp)

module.exports = b
```

And that's it. Let's unpack this a bit. 
We created two functions:
`createBoulder` and `handleCreateBoulder`.
This is a convention used throughout the pantheon. 
The plain `createBoulder` does the actual work.
The `handleCreateBoulder` handles an http request by calling `createBoulder`.
This way, you can perform api actions within your application without
making an http request. It also makes testing easier.

`handleCreateBoulder` gets a CouchDB client from req.couch.
req.couch is a CouchDB client that has been authenticated as
whichever user authenticated against your application. 
This way, your validation functions in couch can also handle authorization.

You'll also notice that we did not pass a callback to b.createBoulder.
b.createBoulder returns a stream of the CouchDB response.
We can then pipe that response directly to our response object.
This is very memory efficient. 
Node does not have to receive the entire couch response into memory before sending it to the client. 
Instead, it just acts as a proxy, forwarding the CouchDB response to the client as it is received.

$SISYPHUS/src/api/boulder.coffee:

```coffeescript
doAction = require('pantheon-helpers/lib/doAction')

b = {}

b.getBoulder = (db, boulderId, callback) ->
  return db.get(boulderId, callback)

b.rollBoulderUp = (db, boulderId, callback) ->
  return doAction(db, 'boulder', boulderId, {a: 'bu'}, callback)

b.handleRollBoulderUp = (req, resp) ->
  db = req.couch.use('boulder')
  boulderId = req.params.boulderId
  b.rollBoulderUp(db, boulderId).pipe(resp)

b.rollBoulderDown = (db, boulderId, callback) ->
  return doAction(db, 'boulder', boulderId, {a: 'bd'}, callback)

b.handleRollBoulderDown = (req, resp) ->
  db = req.couch.use('boulder')
  boulderId = req.params.boulderId
  b.rollBoulderDown(db, boulderId).pipe(resp)

module.exports = b
```

$SISYPHUS/routes.coffee:

```coffeescript
boulders = require('./api/boulders')
boulder = require('./api/boulder')

module.exports = (app) ->
  app.post('/sisyphus/boulders/', boulders.handleCreateBoulder)

  app.get('/sisyphus/boulders/:boulderId', boulder.handleGetBoulder)
  app.put('/sisyphus/boulders/:boulderId/state/down', boulder.handleRollBoulderDown)
  app.put('/sisyphus/boulders/:boulderId/state/up', boulder.handleRollBoulderUp)
```

You now have a fully functioning application with auditing, logging, and a background worker process.

Thanks for reading!
