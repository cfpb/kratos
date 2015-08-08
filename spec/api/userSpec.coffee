{user, users} = require('../../lib/api')

describe 'handleGetUser', () ->
  it 'calls users.getUser with the logged in user and pipes the response to the resp obj.', () ->
    getUserResp = {pipe: jasmine.createSpy('pipe')}
    spyOn(users, 'getUser').andReturn(getUserResp)
    req = {
      couch: 'couchClient'
      session: {
        user: 'userName'
      }
    }

    cut = user.handleGetUser

    cut(req, 'resp')

    expect(users.getUser).toHaveBeenCalledWith('couchClient', 'userName')
    expect(getUserResp.pipe).toHaveBeenCalledWith('resp')
