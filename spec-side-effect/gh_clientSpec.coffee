conf = require('../lib/config')

# monkeypatch org, so it points to testing org
# must monkeypatch before importing any other libraries!
if not conf.RESOURCES.GH_TEST
  throw Error('You must provide a RESOURCES.GH_TEST config hash pointing to a github.com org whose ENTIRE CONTENTS CAN BE DELETED.')
conf.RESOURCES.GH = conf.RESOURCES.GH_TEST
gh_conf = conf.RESOURCES.GH

if gh_conf.ORG_NAME != 'kratos-test'
  throw Error('DANGER: ORG_NAME is set to "' + gh_conf.ORG_NAME + '". This may indicate a problem with the test harness that could lead to data loss')

_ = require('underscore')
gh = require('../lib/workers/gh_client')
request = require('request')
utils = require('../lib/utils')
Promise = require('promise')
path = require('path')

{setTimeout} = require('timers')
wait = Promise.denodeify((delay, callback) -> setTimeout(callback, delay))

KRATOS_DIR = path.join(__dirname, '..')
TEMPLATE_DIR = path.join(KRATOS_DIR, './template_repo/')

{exec} = require 'child_process'
exec = Promise.denodeify(exec)

git = gh.client

handle = (msg, done) ->
  return (res) ->
    console.log(msg, res)
    expect(true).toBeFalse()
    done()
onError = (done) ->
  return handle("ERR", done)
onSuccess = (done) -> 
  return handle("SUCCESS", done)

reset_org = (callback) ->
  if gh_conf.ORG_NAME.indexOf('-test') < 0
    throw Error('DANGER: ORG_NAME is set to "' + gh_conf.ORG_NAME + '". This may indicate a problem with the test harness that could lead to data loss')

  Promise.all([
    git.get_all('organizations/' + gh_conf.ORG_ID + '/repos'),
    git.get_all('organizations/' + gh_conf.ORG_ID + '/teams'),
    exec('rm -rf ' + TEMPLATE_DIR)
  ]).then((objs) ->
    del_objs = _.compact(_.filter(objs[0], (repo) -> repo.full_name not in (gh_conf.UNMANAGED_REPOS or [])).concat(
               _.filter(objs[1], (team) -> team.id not in (gh_conf.UNMANAGED_TEAMS or []))))
    Promise.all(del_objs.map((obj) -> git.del({url: obj.url, ignore_codes: [404]})))
  ).then(() ->
    if callback then return callback()
  ).catch((err) ->
    if callback then return callback(err)
    console.log('ERROR!!', err)
  )

jasmine.getEnv().defaultTimeoutInterval = 5000

describe 'team_create', () ->
  beforeEach (done) ->
    return reset_org(done)
  it 'creates a github team given a kratos name and a permission', (done) ->
    gh.team.create({name: 'test', permission: 'admin'}).then((team) ->
      expect(team.name).toEqual('test team admin')
      done()
    ).catch(onError(done))
  it 'returns the team info, if the team already exists', (done) ->
    gh.team.create({name: 'test', permission: 'admin'}).then((team) ->
      return gh.team.create({name: 'test', permission: 'admin'})
    ).then((team) ->
      expect(team.name).toEqual('test team admin')
      done()
    ).catch(onError(done))

describe 'team_delete', () ->
  beforeEach (done) ->
    return reset_org(done)
  it 'deletes a github team given a github team id', (done) ->
    gh.team.create({name: 'test', permission: 'admin'}).then((team) ->
      return gh.team.delete(team.id)
    ).then(() ->
      return git.get_all('organizations/' + gh_conf.ORG_ID + '/teams')
    ).then((teams) ->
      expect(teams.length).toEqual(1)
      done()
    ).catch(onError(done))
  it 'does not error if the team does not exist', (done) ->
    gh.team.delete('2938374746464545').then((resp) ->
      expect(resp).toBeUndefined()
      done()
    ).catch(onError(done))

describe 'team_user_add', () ->
  team_id = null
  beforeEach (done) ->
    return reset_org().then(() ->
      gh.team.create({name: 'test', permission: 'admin'})        
    ).then((team) ->
      team_id = team.id
      done()
    )

  it 'adds the user with username to the team with gh_team_id', (done) ->
    gh.team.user.add(team_id, 'dgreisen-cfpb').then((resp) ->
      git.get(resp.body.url)
    ).then((resp) ->
      expect(resp.statusCode).toEqual(200)
      done()
    ).catch(onError(done))

  it 'does not error if the user is already added', (done) ->
    gh.team.user.add(team_id, 'dgreisen-cfpb').then((resp) ->
      gh.team.user.add(team_id, 'dgreisen-cfpb')
    ).then((resp) ->
      git.get(resp.body.url)
    ).then((resp) ->
      expect(resp.statusCode).toEqual(200)
      done()
    ).catch(onError(done))

describe 'team_user_remove', () ->
  team_id = null
  beforeEach (done) ->
    return reset_org().then(() ->
      gh.team.create({name: 'test', permission: 'admin'})        
    ).then((team) ->
      team_id = team.id
      done()
    ).catch(onError(done))

  it 'removes the user with username from the team with gh_team_id', (done) ->
    gh.team.user.add(team_id, 'dgreisen-cfpb').then((resp) ->
      gh.team.user.remove(team_id, 'dgreisen-cfpb')
    ).then((resp) ->
      git.get('/teams/' + team_id + '/memberships/dgreisen-cfpb')
    ).catch((err) ->
      expect(err.code).toEqual(404)
      done()
    ).catch(onError(done))

  it 'does not error if the user is already removed', (done) ->
    gh.team.user.remove(team_id, 'dgreisen-cfpb').then((resp) ->
      git.get('/teams/' + team_id + '/memberships/dgreisen-cfpb').catch((err) ->
        expect(err.code).toEqual(404)
        done()
      )
    ).catch(onError(done))

describe 'team_repo_add', () ->
  team_id = null
  repo_full_name = null
  beforeEach (done) ->
    return reset_org().then(() ->
      gh.team.create({name: 'test', permission: 'admin'})        
    ).then((team) ->
      team_id = team.id
    ).then(() ->
      gh.repo.create({name: 'test'})
    ).then((repo) ->
      repo_full_name = repo.full_name
      done()
    )

  it 'adds existing repo to the team with gh_team_id', (done) ->
    gh.team.repo.add(team_id, repo_full_name).then((resp) ->
      git.get(resp.url)
    ).then((resp) ->
      expect(resp.statusCode).toEqual(200)
      done()
    ).catch(onError(done))

  it 'does not error if the repo is already added', (done) ->
    gh.team.repo.add(team_id, repo_full_name).then((resp) ->
      gh.team.repo.add(team_id, repo_full_name)
    ).then((resp) ->
      git.get(resp.url)
    ).catch((err) -> console.log('ERR', err)).then((resp) ->
      expect(resp.statusCode).toEqual(200)
      done()
    ).catch(onError(done))

describe 'team_repo_remove', () ->
  team_id = null
  repo_full_name = null
  beforeEach (done) ->
    return reset_org().then(() ->
      gh.team.create({name: 'test', permission: 'admin'})        
    ).then((team) ->
      team_id = team.id
    ).then(() ->
      gh.repo.create({name: 'test'})
    ).then((repo) ->
      repo_full_name = repo.full_name
      done()
    )

  it 'removes the repo from the team with gh_team_id', (done) ->
    gh.team.repo.add(team_id, repo_full_name).then((resp) ->
      gh.team.repo.remove(team_id, repo_full_name)
    ).then((resp) ->
      git.get('/teams/' + team_id + '/repos/' + repo_full_name)
         .catch((err) ->
           expect(err.code).toEqual(404)
           done()
         )
    ).catch(onError(done))

  it 'does not error if the repo is already removed', (done) ->
    gh.team.repo.remove(team_id, 'dgreisen-cfpb').then((resp) ->
      git.get('/teams/' + team_id + '/repos/' + repo_full_name)
         .catch((err) ->
           expect(err.code).toEqual(404)
           done()
         )
    ).catch(onError(done))

describe 'teams_create', () ->
  beforeEach (done) ->
    reset_org(done)

  it 'creates teams from the passed array of opts', (done) ->
    gh.teams.create([
      {name: 'test', permission: 'admin'},
      {name: 'test', permission: 'push'}
    ]).then((resps) ->
      Promise.all([
        git.get(resps[0].url),
        git.get(resps[1].url)
      ])
    ).then((resps) ->
      expect(resps[0].statusCode).toEqual(200)
      expect(resps[1].statusCode).toEqual(200)
      done()
    ).catch(onError(done))

describe 'teams_repo_add', () ->
  team_ids = null
  repo_full_name = null
  beforeEach (done) ->
    return reset_org().then(() ->
      gh.teams.create([
        {name: 'test', permission: 'admin'},
        {name: 'test', permission: 'push'}
      ])
    ).then((teams) ->
      team_ids = _.pluck(teams, 'id')
    ).then(() ->
      gh.repo.create({name: 'test'})
    ).then((repo) ->
      repo_full_name = repo.full_name
      done()
    )

  it 'adds existing repo to the teams with gh_team_ids', (done) ->
    gh.teams.repo.add(team_ids, repo_full_name).then((resps) ->
      Promise.all([
        git.get(resps[0].url),
        git.get(resps[1].url)
      ])
    ).then((resps) ->
      expect(resps[0].statusCode).toEqual(200)
      expect(resps[1].statusCode).toEqual(200)
      done()
    ).catch(onError(done))


describe 'teams_repo_remove', () ->
  team_ids = null
  repo_full_name = null
  beforeEach (done) ->
    return reset_org().then(() ->
      gh.teams.create([
        {name: 'test', permission: 'admin'},
        {name: 'test', permission: 'push'}
      ])
    ).then((teams) ->
      team_ids = _.pluck(teams, 'id')
    ).then(() ->
      gh.repo.create({name: 'test'})
    ).then((repo) ->
      repo_full_name = repo.full_name
      done()
    )

  it 'removes the repo from the teams with gh_team_ids', (done) ->
    gh.teams.repo.add(team_ids, repo_full_name).then((resps) ->
      gh.teams.repo.remove(team_ids, repo_full_name)
    ).then((resps) ->
      Promise.all(team_ids.map((team_id) -> git.get({url: '/teams/' + team_id + '/repos/' + repo_full_name, ignore_codes: [404]})))
         .then((resps) ->
           expect(resps[0].statusCode).toEqual(404)
           expect(resps[1].statusCode).toEqual(404)
           done()
         )
    ).catch(onError(done))


describe 'teams_user_add', () ->
  team_ids = null
  beforeEach (done) ->
    return reset_org().then(() ->
      gh.teams.create([
        {name: 'test', permission: 'admin'},
        {name: 'test', permission: 'push'}
      ])
    ).then((teams) ->
      team_ids = _.pluck(teams, 'id')
      done()
    )
  it 'adds existing user to the teams with gh_team_ids', (done) ->
    gh.teams.user.add(team_ids, 'dgreisen-cfpb').then((resps) ->
      Promise.all([
        git.get(resps[0].url),
        git.get(resps[1].url)
      ])
    ).then((resps) ->
      expect(resps[0].statusCode).toEqual(200)
      expect(resps[1].statusCode).toEqual(200)
      done()
    ).catch(onError(done))

describe 'teams_repo_remove', () ->
  team_ids = null
  repo_full_name = null
  beforeEach (done) ->
    return reset_org().then(() ->
      gh.teams.create([
        {name: 'test', permission: 'admin'},
        {name: 'test', permission: 'push'}
      ])
    ).then((teams) ->
      team_ids = _.pluck(teams, 'id')
      done()
    )


  it 'removes the user from the teams with gh_team_ids', (done) ->
    gh.teams.user.add(team_ids, 'dgreisen-cfpb').then((resps) ->
      gh.teams.user.remove(team_ids, 'dgreisen-cfpb')
    ).then((resps) ->
      Promise.all(team_ids.map((team_id) -> git.get({url: '/teams/' + team_id + '/repos/' + repo_full_name, ignore_codes: [404]})))
         .then((resps) ->
           expect(resps[0].statusCode).toEqual(404)
           expect(resps[1].statusCode).toEqual(404)
           done()
         )
    ).catch(onError(done))


describe 'user_delete', () ->
  beforeEach (done) ->
    reset_org(done)

  it 'removes the user from the organization', (done) ->
    gh.user.delete('dgreisen-cfpb').catch((err) ->
      expect(err.msg.message).toEqual('Cannot remove the last owner')
      done()
    ).catch(onError(done))

  it 'does not error if the user is already removed from the org', (done) ->
    gh.user.delete('dgreisen').then((resp) ->
      expect(resp.statusCode).toEqual(404)
      done()
    ).catch(onError(done))


describe 'repo_create', () ->
  beforeEach (done) ->
    reset_org(done)
  it 'creates the repo if it does not exist, and returns repo details', (done) ->
    gh.repo.create({name: 'test'}).then((resp) ->
      console.log('resp', resp)
      expect(resp.name).toEqual('test')
      done()
    ).catch(onError(done))

  it 'returns repo details if it already exists', (done) ->
    gh.repo.create({name: 'test'}).then((resp) ->
      gh.repo.create({name: 'test'}).then((resp) ->
        console.log('test', resp)
        expect(resp.name).toEqual('test')
        done()
      )
    ).catch(onError(done))

describe 'repo_pushTemplate', () ->
  repo_data = null
  beforeEach (done) ->
    return reset_org().then(() ->
    ).then(() ->
      gh.repo.create({name: 'test'})
    ).then((repo) ->
      repo_data = repo
      done()
    )

  it 'clones the template repo (if not already there), and pushes to new repo', (done) ->
    gh.repo.pushTemplate(repo_data).then(() ->
      commits_url = repo_data.commits_url.split('{')[0]
      git.get({url:commits_url, body_only: true})
    ).then((commits) ->
      expect(commits.length).toBeGreaterThan(0)
      done()
    ).catch(onError(done))

  it 'just pushes to new repo if the template repo is already up to date', (done) ->
    last_commit = null
    new_repo_data = null
    gh.repo.pushTemplate(repo_data).then(() ->
      commits_url = repo_data.commits_url.split('{')[0]
      git.get({url:commits_url, body_only: true})
    ).then((commits) ->
      last_commit = commits[0]
      gh.repo.create({name: 'test2'})
    ).then((repo) ->
      new_repo_data = repo
      gh.repo.pushTemplate(new_repo_data)
    ).then(() ->
      commits_url = new_repo_data.commits_url.split('{')[0]
      git.get({url:commits_url, body_only: true})
    ).then((commits) ->
      new_last_commit = commits[0]
      expect(new_last_commit.sha).toEqual(last_commit.sha)
      done()
    ).catch(onError(done))

  it 'pulls the most recent template repo version', (done) ->
    last_commit = null
    new_repo_data = null
    gh.repo.pushTemplate(repo_data).then(() ->
      commits_url = repo_data.commits_url.split('{')[0]
      git.get({url:commits_url, body_only: true})
    ).then((commits) ->
      last_commit = commits[0]
      exec('git reset HEAD~1 --hard', {cwd: TEMPLATE_DIR})
    ).then(() ->
      gh.repo.create({name: 'test2'})
    ).then((repo) ->
      new_repo_data = repo
      gh.repo.pushTemplate(new_repo_data)
    ).then(() ->
      commits_url = new_repo_data.commits_url.split('{')[0]
      git.get({url:commits_url, body_only: true})
    ).then((commits) ->
      new_last_commit = commits[0]
      expect(new_last_commit.sha).toEqual(last_commit.sha)
      done()
    ).catch(onError(done))

  it 'does not push if the repository is not brand new', (done) ->
    wait(1500).then(() ->
      git.patch({
        url: repo_data.url,
        json: {
          name: repo_data.name,
          description: 'description'
        },
        body_only: true
      })
    ).then((new_repo_data) ->
      gh.repo.pushTemplate(new_repo_data)
    ).then(() ->
      commits_url = repo_data.commits_url.split('{')[0]
      git.get({url:commits_url, body_only: true})
    ).catch((err) ->
      expect(err.msg.message).toEqual('Git Repository is empty.')
      done()
    ).catch(onError(done))
