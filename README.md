# CFPB/Kratos
## Zeus's winged enforcer.

[![Build Status](https://travis-ci.org/cfpb/kratos.svg)](https://travis-ci.org/cfpb/kratos)

[![Coverage Status](https://coveralls.io/repos/cfpb/kratos/badge.svg?branch=master)](https://coveralls.io/r/cfpb/kratos?branch=master)

A pluggable microservice to enforce authorization across the entire enterprise.
One of the Pantheon of CFPB microservices.


Kratos keeps tracks of three things: (1) **teams**,
(2) which **users** have which roles on those teams,
and (3) which **assets** are available to the team.
It can then, based on it's database of teams/users/assets,
setup teams, users and permissions on other **resources**.

Kratos is built with [Pantheon-Helpers](https://github.com/cfpb/pantheon-helpers),
so it is built on an evented architucture using NodeJS and CouchDB.
In order for kratos to enforce authorization on other resources,
you must create a resource adapter.
A resource adapter consists of:
(1) authorization and (2) validation functions for asset management and
(3) worker handlers.

This document explains generally how kratos works,
and specifically how to create an adapter.

## General Architecture
Kratos is built with [Pantheon-Helpers](https://github.com/cfpb/pantheon-helpers).
You should familiarize yourself with Pantheon-helpers documentation before continuing.

### Authorization model
Users can have two different types of roles.
A user with a particular **Team Role** only has that role on a particular team.
If a user has a **Resource role**, they have that role system-wide.
**Assets** can be assigned to teams (and soon, hopefully, users).

An example of a **resource role** might be `gh|user`.
It conveys that the user has fulfilled all requirements necessary to be allowed to access the public github.
An example of a **Team Role** might be `administrator of the Pantheon Team`.
The Github resource adapter then defines how to map resource and team roles to github permissions.
The Github resource adapter specifies that a user gets read/write access to a repo if (1) they have the `gh|user` resource role, and
(2) they are a member or administrator of the team that ownes the repo.





which is
All authenticated users have an entry in the _users database.

Kratos uses to CouchDB databases:
the _users database and the t


An **asset** is provided by a **service**.
So, for example,
if you want kratos to manage 

Kratos defines a number of actions for manipulating these three things.
