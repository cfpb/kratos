teams = require('../../lib/api').teams
Promise = require('pantheon-helpers').promise

beforeEvery = () ->
  spyOn(teams.testing, 'doAction').andReturn(Promise.resolve('doActionResp'))
  this.doAction = teams.testing.doAction

describe 'createTeam', () ->
  beforeEach beforeEvery

  it 'calls doAction with the passed db, base designdoc, a null docId, and a t+ action with team name', (done) ->
    cut = teams.createTeam

    cut('dbName', 'actorName', 'teamName').then((resp) =>
      expect(this.doAction).toHaveBeenCalledWith('dbName', 'actorName', null, {a: 't+', name: 'teamName'})
      done()
    ).catch(done)
