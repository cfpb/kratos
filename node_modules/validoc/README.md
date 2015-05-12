ValiDoc
==========

[![Build Status](https://travis-ci.org/dgreisen/validoc.svg)](https://travis-ci.org/dgreisen/validoc)

Highlights
----------
* runs on browser and node.js -
  writing one schema gets you client- and server-side validation
* inspired by Django Forms
* validate flat or arbitrarily nested data structures -
  great for rdbms's and nosql
* incredibly flexible - you can validate any json structure
* easy validation of multiple related fields 

Overview
--------
ValiDoc is a forms framework for node.js and the browser.
It was inspired, and designed to be compatible with,
[Django Forms](https://docs.djangoproject.com/en/1.4/topics/forms/).
Like Django forms, and unlike validation schema like JSONSchema,
you can easily create complex validation of multiple interrelated fields.
You can also create new Field types to validate any data you like.

ValiDoc works on both the browser and in NodeJS,
so you can generate UI on the front end, validate, and display errors,
then validate the data on the server for safety.
Write one schema to validate client side and server-side.

While we strive to remain compatible with Django forms,
ValiDoc extends the concepts to validate arbitrarily nested documents.
ValiDoc is well suited to validating both flat data that is destined 
for a table in an RDBMS, or for nested data that is destined for a document database such 
as CouchDB or Mongo.

Feedback
--------

I greatly appreciate feedback.
If you have a bug or feature request, please put it in the tracker.
For anything else, 
including if you'd like to let me know you are using ValiDoc code in a project,
you can reach me at dgreisen@gmail.com.