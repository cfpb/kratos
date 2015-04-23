_ = require('underscore')
users = require('../api/users')
auth = require('../validation/validate').auth
Promise = require('pantheon-helpers/lib/promise')
conf = require('../config')

moirai = {}

moirai.moiraiClient = Promise.RestClient({
  url: conf.MOIRAI.URL,
  auth: conf.MOIRAI.ADMIN_CREDENTIALS,
  json: true
})

emptyResolve = () ->
  Promise.resolve()


moirai.setClusterKeys = (clusterId, keys) ->
  url = '/moirai/clusters/'+clusterId+'/keys'
  return moirai.moiraiClient.put({url: url, json: keys, body_only: true})

moirai.getTeamKeys = (team) ->
  adminNames = team.roles.admin.members
  memberNames = team.roles.member.members
  allMemberNames = _.unique(adminNames.concat(memberNames))
  users.get_users_by_name(allMemberNames).then((userList) ->
    keyList = userList.map((user) ->
      return _.findWhere(user.data.publicKeys or [], {name: 'moirai'})
    )
    return Promise.resolve(_.compact(keyList).map((key) -> key.key))
  )

moirai.setTeamKeys = (team) ->
  moirai.getTeamKeys(team).then((keys) ->
    clusters = team.rsrcs.moirai.assets
    clusterIds = _.pluck(clusters, 'cluster_id')
    promisesList = clusterIds.map((clusterId) ->
      moirai.setClusterKeys(clusterId, keys)
    )
    Promise.all(promisesList).then(emptyResolve)
  )

handleAddUser = (event, team) ->
  moirai.setTeamKeys(team)

handleRemoveUser = (event, team) ->
  moirai.setTeamKeys(team)

moirai.removeCluster = (cluster_id) ->
  url = '/moirai/clusters/' + cluster_id
  return moirai.moiraiClient.del(url)

handleRemoveCluster = (event, team) ->
  cluster_id = event.asset.id
  return moirai.removeCluster(cluster_id).then(emptyResolve)

handleAddCluster = (event, team) ->
  cluster_id = event.asset.id
  return moirai.getTeamKeys(team).then((keys) ->
    moirai.setClusterKeys(cluster_id, keys).then(emptyResolve)
  )

handleAddData = (event, team) ->
  moirai.setTeamKeys(team)


getOrCreateAsset = (assetData, team) ->
  url = '/moirai/clusters'
  clusters = team.rsrcs.moirai.assets
  existingClusterWithName = _.findWhere(clusters, {name: assetData.name})
  if existingClusterWithName?
    return Promise.resolve(existingClusterWithName)
  else
    return moirai.moiraiClient.post({url: url, json: assetData, body_only: true}).then((newClusterData) ->
      Promise.resolve({
        cluster_id: newClusterData._id,
        name: newClusterData.name,
      })
    )

module.exports =
  handlers:
    team:
      'u+': handleAddUser
      'u-': handleRemoveUser
      't+': null
      't-': null # if t- is implemented, this action should remove the cluster
      self:
        'a+': handleAddCluster
        'a-': handleRemoveCluster
      other:
        'a+': null
        'a-': null
    user:
      self:
        'r+': null
        'r-': null
      other:
        'r+': null
        'r-': null
      'u+': null
      'u-': null
      'd+': handleAddData
  getOrCreateAsset: getOrCreateAsset
  testing: moirai
