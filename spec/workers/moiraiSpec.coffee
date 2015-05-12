teams = require('../../lib/api/teams')
users = require('../../lib/api/users')
moirai = require('../../lib/workers/moirai')
Promise = require('promise')
_ = require('underscore')

onError = (done) ->
  (err) -> done(err)

describe 'setClusterKeys', () ->
  it 'sends the cluster and keys to the moirai API', (done) ->
    spyOn(moirai.testing.moiraiClient, 'put').andReturn(Promise.resolve())
    keys = ['key1', 'key2']
    moirai.testing.setClusterKeys('clusterid', keys).then(() ->
      expect(moirai.testing.moiraiClient.put).toHaveBeenCalledWith({
        url: '/moirai/clusters/clusterid/keys',
        json: keys,
        body_only: true
      })
      done()
    )

describe 'getTeamKeys', () ->
  beforeEach () ->
    this.team =
      roles:
        admin:
          members: [
            'member1',
            'member2'
          ]
        member:
          members: [
            'member3',
            'member4'
          ]
      rsrcs:
        moirai:
          assets: [
            {
              id: 'ab38f',
              cluster_id: 'cluster_test1',
              name: 'test1',
            },
            {
              id: 'xy93d',
              cluster_id: 'cluster_test2',
              name: 'test2',
            },
          ]
    spyOn(users, 'get_users').andReturn(Promise.resolve([

      {
        _id: 'org.couchdb.user:member1',
        data: {
          publicKeys: [{name: 'moirai', key: 'keyvalue1'}]
        }
      },
      {
        _id: 'org.couchdb.user:member2',
        data: {
          publicKeys: [{name: 'not-moirai', key: 'keyvalue2'}]
        }
      },
      {
        _id: 'org.couchdb.user:member3',
        data: {
          publicKeys: []
        }
      },
      {
        _id: 'org.couchdb.user:member3',
        data: {
          publicKeys: [
            {name: 'moirai', key: 'keyvalue4'},
            {name: 'moirai', key: 'keyvalue4.2'}
          ]
        }
      }
    ]))

  it 'calls get_users', (done) ->
    moirai.testing.getTeamKeys(this.team).then(() =>
      userList = ['member1', 'member2', 'member3', 'member4']
      expect(users.get_users).toHaveBeenCalledWith({names: userList}, 'promise')
      done()
    ).catch(onError(done))

  it 'gets a valid key where the name is moirai', (done) ->
    moirai.testing.getTeamKeys(this.team).then((result) =>
      expect(_.contains(result, 'keyvalue1')).toEqual(true)
      done()
    ).catch(onError(done))

  it 'does not get a key if the name is not moirai', (done) ->
    moirai.testing.getTeamKeys(this.team).then((result) =>
      expect(_.contains(result, 'keyvalue2')).toEqual(false)
      done()
    ).catch(onError(done))

  it 'only gets one moirai key per person', (done) ->
    moirai.testing.getTeamKeys(this.team).then((result) =>
      expect(_.contains(result, 'keyvalue4')).toEqual(true)
      expect(_.contains(result, 'keyvalue4.2')).toEqual(false)
      done()
    ).catch(onError(done))

  it 'gets the appropriate number of keys', (done) ->
    moirai.testing.getTeamKeys(this.team).then((result) =>
      expect(result.length).toEqual(2)
      done()
    ).catch(onError(done))

describe 'setTeamKeys', () ->
  beforeEach () ->
    this.team =
      rsrcs:
        moirai:
          assets: [
            {
              id: 'ab38f',
              cluster_id: 'cluster_test1',
              name: 'test1',
            },
            {
              id: 'xy93d',
              cluster_id: 'cluster_test2',
              name: 'test2',
            },
          ]
    spyOn(moirai.testing, 'getTeamKeys').andReturn(Promise.resolve(['key1', 'key3']))
    spyOn(moirai.testing, 'setClusterKeys').andReturn(Promise.resolve())

  it 'calls getTeamKeys', (done) ->
    moirai.testing.setTeamKeys(this.team).then(() =>
      expect(moirai.testing.getTeamKeys).toHaveBeenCalledWith(this.team)
      done()
    )

  it 'calls setClusterKeys with cluster id and key list', (done) ->
    moirai.testing.setTeamKeys(this.team).then(() =>
      expect(moirai.testing.setClusterKeys.calls.length).toEqual(2)
      expect(moirai.testing.setClusterKeys).toHaveBeenCalledWith(
        'cluster_test1',
        ['key1', 'key3']
      )
      expect(moirai.testing.setClusterKeys).toHaveBeenCalledWith(
        'cluster_test2',
        ['key1', 'key3']
      )
      done()
    )

describe 'handleAddUser', () ->
  it 'gets the team object and calls setTeamKeys', (done) ->
    handleAddUser = moirai.handlers.team['u+']
    spyOn(moirai.testing, 'setTeamKeys').andReturn(Promise.resolve())

    handleAddUser({user: 'userid', role: 'member'}, 'team').then((resp) ->
      expect(moirai.testing.setTeamKeys).toHaveBeenCalledWith('team')
      expect(resp).toBeUndefined()
      done()
    ).catch(onError)

describe 'handleRemoveUser', () ->
  it 'gets the team object and calls setTeamKeys', (done) ->
    handleRemoveUser = moirai.handlers.team['u-']
    spyOn(moirai.testing, 'setTeamKeys').andReturn(Promise.resolve())

    handleRemoveUser({user: 'userid', role: 'member'}, 'team').then((resp) ->
      expect(moirai.testing.setTeamKeys).toHaveBeenCalledWith('team')
      expect(resp).toBeUndefined()
      done()
    ).catch(onError)

describe 'removeCluster', () ->
  it 'calls the moirai API to remove the cluster', (done) ->
    spyOn(moirai.testing.moiraiClient, 'del').andReturn(Promise.resolve())
    moirai.testing.removeCluster('testClusterId').then(() ->
      expect(moirai.testing.moiraiClient.del).toHaveBeenCalledWith('/moirai/clusters/testClusterId')
      done()
    )

describe 'handleRemoveCluster', () ->
  it 'calls removeCluster', (done) ->
    handleRemoveCluster = moirai.handlers.team.self['a-']
    spyOn(moirai.testing, 'removeCluster').andReturn(Promise.resolve())

    handleRemoveCluster({asset: {cluster_id: 'clusterId'}}, 'team').then((resp) ->
      expect(moirai.testing.removeCluster).toHaveBeenCalledWith('clusterId')
      expect(resp).toBeUndefined()
      done()
    ).catch(onError)

describe 'handleAddCluster', () ->
  it 'gets keys from getTeamKeys, calls setClusterKeys', (done) ->
    handleAddCluster = moirai.handlers.team.self['a+']
    spyOn(moirai.testing, 'setClusterKeys').andReturn(Promise.resolve())
    testKeys = ['key1', 'key2']
    spyOn(moirai.testing, 'getTeamKeys').andReturn(Promise.resolve(testKeys))

    handleAddCluster({asset: {cluster_id: 'cluster_id'}}, 'team').then((resp) ->
      expect(moirai.testing.getTeamKeys).toHaveBeenCalledWith('team')
      expect(moirai.testing.setClusterKeys).toHaveBeenCalledWith('cluster_id', testKeys)
      expect(resp).toBeUndefined()
      done()
    ).catch(onError)

describe 'handleAddData', () ->
  beforeEach () ->
    spyOn(teams, 'get_all_team_roles_for_user').andReturn(
       Promise.resolve([{team: 'team1Obj'}, {team: 'team2Obj'}]))
    spyOn(moirai.testing, 'setTeamKeys').andReturn(Promise.resolve())
    this.event = {data: {publicKeys: ['key']}}
    this.user = {name: 'user_name'}

  it 'calls get_all_team_roles_for_user', (done) ->
    handleAddData = moirai.handlers.user['d+']
    handleAddData(this.event, this.user).then((resp) ->
      expect(teams.get_all_team_roles_for_user.calls.length).toEqual(1)
      expect(teams.get_all_team_roles_for_user).toHaveBeenCalledWith('user_name')
      expect(resp).toBeUndefined()
      done()
    ).catch(onError)

  it 'calls setTeamKeys', (done) ->
    handleAddData = moirai.handlers.user['d+']
    handleAddData(this.event, this.user).then((resp) ->
      expect(moirai.testing.setTeamKeys.calls.length).toEqual(2)
      expect(moirai.testing.setTeamKeys).toHaveBeenCalledWith('team1Obj')
      expect(moirai.testing.setTeamKeys).toHaveBeenCalledWith('team2Obj')
      expect(resp).toBeUndefined()
      done()
    ).catch(onError)

  it 'does nothing if publicKeys not defined', (done) ->
    this.event.data = {sampleData: 'test'}
    handleAddData = moirai.handlers.user['d+']
    handleAddData(this.event, this.user).then((resp) ->
      expect(moirai.testing.setTeamKeys.calls.length).toEqual(0)
      expect(resp).toBeUndefined()
      done()
    ).catch(onError)

describe 'getOrCreateAsset', () ->
  beforeEach () ->
    spyOn(moirai.testing.moiraiClient, 'post').andCallFake((assetData, team) ->
      return Promise.resolve({
        _id: 'cluster_id'
        name: assetData.json.name
      })
    )
    this.team =
      name: 'team1 name!'
      rsrcs:
        moirai:
          assets: [
            id: "ab38f",
            cluster_id: 'cluster_test1',
            name: "test1",
          ]
    this.actor =
      data:
        username: 'actorName'
        email: 'emailAddress'

  it 'does nothing if the cluster already exists', (done) ->
    moirai.getOrCreateAsset({name: 'test1'}, this.team, this.actor).then((resp) ->
      expect(moirai.testing.moiraiClient.post).not.toHaveBeenCalled()
      expect(resp).toBeUndefined()
      done()
    )

  it "gets/creates a repo, and returns the details to store in couch", (done) ->
    moirai.getOrCreateAsset({new: 'app name123'}, this.team, this.actor).then((resp) =>
      expect(moirai.testing.moiraiClient.post).toHaveBeenCalledWith({
        url: '/moirai/clusters',
        json: {
          name: 'app name123'
          instances: [{
            tags: {
              Name: 'moirai-team1-name-app-name123'
              Application: 'app name123'
              BusinessOwner: 'team1 name!'
              Creator: this.actor.data.username
            }
          }]
        },
        body_only: true
      })
      expect(resp).toEqual({cluster_id: 'id', name: 'app name123'})
      done()
    ).catch((err) ->
      done(err)
    )
