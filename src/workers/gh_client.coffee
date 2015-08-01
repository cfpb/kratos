_ = require('underscore')
conf = require('../config')

gh_conf = conf.RESOURCES.GH
path = require('path')
Promise = require('pantheon-helpers').promise
{exec} = require('child_process')
exec = Promise.denodeify(exec)
{mkdir} = require('fs')
mkdir = Promise.denodeify(mkdir)

KRATOS_DIR = path.join(__dirname, '../..')
TEMPLATE_DIR = path.join(KRATOS_DIR, './template_repo/')

git = Promise.RestClient({
  url: 'https://api.github.com',
  auth: gh_conf.ADMIN_CREDENTIALS,
  headers: {
    'User-Agent': 'cfpb-kratos',
  },
  json: true,
})

get_authenticated_repo_url = (repo_url) ->
  repo_parts = repo_url.split('//')
  repo_parts[1] = gh_conf.ADMIN_CREDENTIALS.pass + ':x-oauth-basic@' + repo_parts[1]
  authed_repo_url = repo_parts.join('//')
  return authed_repo_url

get_github_team_name = (kratos_team_name, gh_perm) ->
  display_perms = {admin: 'admin', push: 'write', read: 'read'}
  display_perm = display_perms[gh_perm]
  return kratos_team_name + ' team ' + display_perm

c =
  user:
    delete: (gh_username) ->
      git.del({url: '/organizations/' + gh_conf.ORG_ID + '/members/' + gh_username, ignore_codes: [404]})

  team:
    create: (gh_team_opts) ->
      ###
      gh_team_opts is a hash that at minimum must contain `name` and `permission`
      keys. `name` must be the *kratos* team name. *not* the github team name.
      The github team name will be autogenerated.
      ###
      gh_team_opts['name'] = get_github_team_name(gh_team_opts.name, gh_team_opts.permission)
      url = '/organizations/' + gh_conf.ORG_ID + '/teams'
      return git.post({url: url, json:gh_team_opts, body_only: true})
                .catch((err) ->
                  if err.msg?.errors?[0]?.code == 'already_exists'
                    return git.find_one(url, (team) -> return team.name == gh_team_opts['name'])
                  else
                    return Promise.reject(err)
                )
    delete: (gh_team_id) ->
      return git.del('/teams/' + gh_team_id)
                .catch((err) ->
                  if err.code == 404
                    return Promise.resolve()
                  else
                    return Promise.reject(err)
                )
    user:
      add: (gh_team_id, gh_username) ->
        return git.put('/teams/' + gh_team_id + '/memberships/' + gh_username)
      remove: (gh_team_id, gh_username) ->
        return git.del('/teams/' + gh_team_id + '/memberships/' + gh_username)

    repo:
      add: (gh_team_id, gh_repo_fullname) ->
        return git.put('/teams/' + gh_team_id + '/repos/' + gh_repo_fullname)
      remove: (gh_team_id, gh_repo_fullname) ->
        return git.del({url: '/teams/' + gh_team_id + '/repos/' + gh_repo_fullname, ignore_codes: [404]})

  teams:
    create: (gh_teams_opts) ->
      return Promise.all(gh_teams_opts.map((gh_team_opts) ->c.team.create(gh_team_opts)))
    repo:
      add: (gh_team_ids, gh_repo_fullname) ->
        return Promise.all(gh_team_ids.map((gh_team_id) -> c.team.repo.add(gh_team_id, gh_repo_fullname)))
      remove: (gh_team_ids, gh_repo_fullname) ->
        return Promise.all(gh_team_ids.map((gh_team_id) -> c.team.repo.remove(gh_team_id, gh_repo_fullname)))
    user:
      add: (gh_team_ids, gh_username) ->
        return Promise.all(gh_team_ids.map((gh_team_id) -> c.team.user.add(gh_team_id, gh_username)))
      remove: (gh_team_ids, gh_username) ->
        return Promise.all(gh_team_ids.map((gh_team_id) -> c.team.user.remove(gh_team_id, gh_username)))

  repo:
    create: (gh_repo_opts) ->
      ###
      gh_repo_opts is a hash that at minimum must contain a `name` key with the repo's name.
      Can include any other opts specified at https://developer.github.com/v3/repos/#create
      ###
      gh_repo_opts = _.defaults(gh_repo_opts, {
        description: "",
        homepage: "",
        private: false,
        has_issues: true,
        has_wiki: true,
        has_downloads: true
      })
      url = '/organizations/' + gh_conf.ORG_ID + '/repos'
      return git.post({
        url: url,
        json: gh_repo_opts,
        body_only: true,
      }).catch((err) ->
        if err.msg?.errors?[0]?.message == 'name already exists on this account'
          url = '/repos/' + gh_conf.ORG_NAME + '/' + gh_repo_opts.name
          return git.get({url: url, body_only: true})
        else
          return Promise.reject(err)
      )
    pushTemplate: (repo_data) ->
      # if this is not a brand new repo, then we won't push to it.
      if repo_data.created_at != repo_data.updated_at or repo_data.updated_at != repo_data.pushed_at
        return Promise.resolve(repo_data)
      return exec('git init', {cwd: TEMPLATE_DIR}).catch((err) ->
        if err.code == 'ENOENT'
          return mkdir(TEMPLATE_DIR).then(() ->
            exec('git init', {cwd: TEMPLATE_DIR})
          )
        else
          return Promise.reject(err)
      ).then(() ->
        exec('git pull "' + gh_conf.TEMPLATE_REPO + '"', {cwd: TEMPLATE_DIR})
      ).then(() ->
        push_repo_url = get_authenticated_repo_url(repo_data.clone_url)
        exec('git push "' + push_repo_url + '" master', {cwd: TEMPLATE_DIR})
      ).catch((err) ->
        console.error('pushTemplate error', err)
        c.repo.pushTemplate(repo_data)
      ).then(() ->
        Promise.resolve(repo_data)
      )

    createPush: (gh_repo_opts) ->
      # create the repo, if it doesn't exist, then push the template
      # if new repo
      c.repo.create(gh_repo_opts).then((repo_data) ->
        return c.repo.pushTemplate(repo_data)
      )

  client: git

module.exports = c
