conf = require('../config')

gh_conf = conf.RESOURCES.GH
request = require('request')
parse_links = require('parse-links')
couch_utils = require('../couch_utils')
_ = require('underscore')
uuid = require('node-uuid')

gha_url = 'https://api.github.com'
gha = request.defaults(
  auth: gh_conf.ADMIN_CREDENTIALS
  json: true
  headers:
    'User-Agent': 'cfpb-kratos'
)
get_all = (client, url, callback) ->
  out = []
  while url
    await client.get(url, defer(err, resp, data))
    return err if err
    out = out.concat(data)
    link_header = resp.headers.link
    links = parse_links(link_header) if link_header?
    url = links?.next or null
  return callback(null, out)

x = {}

x.import_users = (callback) ->
  url = gha_url + '/organizations/' + gh_conf.ORG_ID + '/members'
  await get_all(gha, url, defer(err, members))
  users = []
  await couch_utils.get_uuids(members.length, defer(err, uuids))

  for member, i in members
    users.push({
      _id: "org.couchdb.user:" + uuids[i],
      type: "user",
      name: uuids[i],
      roles: ["kratos|enabled"],
      data: {
        username: member.login,
      },
      password: conf.COUCH_PWD,
      rsrcs: {
        gh: {
          username: member.login,
          id: member.id,
        }
      },
      audit: [],
    })
  db = couch_utils.nano_system_user.use('_users')
  return db.bulk({docs: users}, callback)

x.import_teams = (db_name, admin_id, callback) ->
  start_time = +new Date()
  url = gha_url + '/organizations/' + gh_conf.ORG_ID + '/teams'
  await get_all(gha, url, defer(err, raw_teams))
  callback(err) if err
  teams = {}
  for raw_team in raw_teams
    if raw_team.id in gh_conf.UNMANAGED_TEAMS
      continue
    [name, typ, perm] = raw_team.name.split(' ')
    raw_team.perm = perm
    raw_team.iname = name # internal name
    if typ != 'team'
      continue
    if not teams[name]?
      teams[name] = {}
    teams[name][perm] = raw_team
  team_data = []
  errs = []
  await
    i = 0
    for team_name, team of teams
      import_team(team, admin_id, defer(errs[i], team_data[i]))
      i++
  errs = _.compact(errs)
  return callback(errs) if errs.length
  team_docs = {docs: team_data}
  db = couch_utils.nano_system_user.use('org_' + db_name)
  await couch_utils.ensure_db(db, 'bulk', team_docs, defer(err, resp))
  return callback(err) if err
  console.log('total time:', +new Date() - start_time)
  return callback()

import_team = (teams, admin_id, callback) ->
  now = +new Date()
  await
    import_repos(teams, admin_id, defer(repo_errs, rsrc_doc))
    i = 0
    import_members(teams, admin_id, defer(member_errs, role_doc))
  return callback([repo_errs, member_errs]) if repo_errs or member_errs

  team_doc = {
    _id: 'team_' + teams['admin'].iname,
    name: teams['admin'].iname,
    rsrcs: {
      'gh': rsrc_doc,
    },
    roles: role_doc,
    audit: [{u: admin_id, dt: now, a: 't+', id: uuid.v4()}]
    enforce: []
  }
  record = _.clone(team_doc)
  delete record.enforce
  delete record.audit
  record.rsrcs = _.clone(record.rsrcs)
  record.rsrcs.gh = _.clone(record.rsrcs.gh)
  delete record.rsrcs.gh.data
  team_doc.audit[0].r = record
  return callback(null, team_doc)

import_members = (teams, admin_id, callback) ->
  role_doc = {
    member: {
      members: []
    }
  }

  members = []
  err = []
  await
    i = 0
    for team_name, team of teams
      url = team.url + '/members'
      get_all(gha, url, defer(err[i], members[i]))
      i++
  err = _.compact(err)
  return callback(err) if err.length

  members = _.flatten(members, true)
  members = _.map(members, (item) -> item.id)
  members = _.uniq(members)
  member_gh_ids = _.map(members, (item) -> ['gh', item])
  await couch_utils.nano_system_user.use('_users').view('base', 'by_resource_id', {keys: member_gh_ids}, defer(err, user_rows))
  return callback(err) if err

  for user in user_rows.rows
    role_doc.member.members.push(user.value)
  return callback(null, role_doc)

import_repos = (teams, admin_id, callback) ->
  team = teams['admin']
  resource_doc = {
    assets: [],
    data: _.object(_.map(teams, (item) -> [item.perm, item.id]))
  }

  url = team.url + '/repos'
  await get_all(gha, url, defer(err, repos))
  return callback(err) if err

  for repo in repos
    repo_record = {id: uuid.v4(), gh_id: repo.id, name: repo.name, full_name: repo.full_name}
    resource_doc.assets.push(repo_record)
  return callback(null, resource_doc)

x.import_all = (db_name, callback) ->
  admin_id = 'admin'
  await x.import_users(defer(err, resp))
  return callback(err) if err
  await x.import_teams(db_name, admin_id, defer(err, resp))
  callback(err) if err
  callback()

module.exports = x
