Robot   = require('hubot').Robot
Adapter = require('hubot').Adapter
TextMessage = require('hubot').TextMessage
EnterMessage = require('hubot').EnterMessage

LCB_PROTOCOL = process.env.HUBOT_LCB_PROTOCOL || 'http'
LCB_HOSTNAME = process.env.HUBOT_LCB_HOSTNAME || 'localhost'
LCB_PORT = process.env.HUBOT_LCB_PORT || 5000
LCB_TOKEN = process.env.HUBOT_LCB_TOKEN
LCB_ROOMS = process.env.HUBOT_LCB_ROOMS.split(',')
HTTP_PROXY = process.env.http_proxy || process.env.HTTP_PROXY

io = require('socket.io-client')
url = require('url')
tunnelAgent = require('tunnel-agent')
http = require('http')
url = require('url')

chatURL = url.format(
  protocol: LCB_PROTOCOL
  hostname: LCB_HOSTNAME
  port: LCB_PORT
  query:
    token: LCB_TOKEN
)

connectOptions = {}
if HTTP_PROXY
  proxyURL = url.parse(HTTP_PROXY)
  connectOptions.agent = tunnelAgent.httpOverHttp
    proxy:
      host: proxyURL.hostname
      port: proxyURL.port

class LCB extends Adapter

  constructor: (@robot) ->
    super @robot

  send: (user, strings...) ->
    console.log 'Sending with user ' + JSON.stringify(user, null, '  ')

    @checkRoomId user.room, (roomid) =>
      for str in strings
        @socket.emit 'messages:create',
          'room': roomid,
          'text': "#{str}"

  reply: (user, strings...) ->
    console.log 'reply!'
    for str in strings
      @socket.emit 'messages:create',
        'room': user.room,
        'text': "@#{user.user.name} #{str}"

  checkRoomId: (room, callback) ->
    if '#'.match(room.charAt(0))
      # strip off the hash as this isn't returned by the Lets Chat API
      slug = room.substr(1)
      console.log 'Got slug ' + slug
      @findIdFromSlug slug, callback
    else
      return callback(room)

  findIdFromSlug: (slug, callback) ->
    chatRoom =
      hostname: LCB_HOSTNAME
      port: LCB_PORT
      path: '/rooms/' + slug
      headers: 'Authorization': 'Bearer ' + LCB_TOKEN

    createRoom = @createRoom
    
    http.get(chatRoom, (res) ->
      console.log 'get of slug ' + slug + ' found status ' + res.statusCode
      if res.statusCode == 404 or res.statusMessage == "Not Found"
        console.log 'not found lets post a new room!'

        accountQuery =
          hostname: LCB_HOSTNAME
          port: LCB_PORT
          path: '/account'
          headers: 'Authorization': 'Bearer ' + LCB_TOKEN

        accountId = null

        http.get(accountQuery, (aRes) ->
          body = ''
          aRes.on 'data', (d) ->
            body += d
          aRes.on 'end', ->
            try
              parsed = JSON.parse(body)
              accountId = parsed.id
            catch e
              console.log 'Got error: ' + e

            createRoom slug, accountId, callback
          ).on 'error', (e) ->
            console.log 'Got error: ' + e.message
            createRoom slug, accountId, callback
      else
        body = ''
        res.on 'data', (d) ->
          body += d
        res.on 'end', ->
          console.log 'parsing room JSON: ' + body
          parsed = JSON.parse(body)
          return callback(parsed.id)
          # we should create the room here if we couldnt find matching slug

    ).on 'error', (e) ->
      console.log 'Got error: ' + e.message
      callback(null)

  createRoom: (slug, accountId, callback) ->
    newRoom =
      slug: slug
      name: slug
      description: 'Description of ' + slug

    if accountId
      newRoom.account = accountId

    json = JSON.stringify(newRoom)

    postOptions =
      hostname: LCB_HOSTNAME
      port: LCB_PORT
      path: '/rooms'
      method: 'POST'
      headers:
        'Content-Type': 'application/json'
        'Authorization': 'Bearer ' + LCB_TOKEN

    req = http.request(postOptions, (res2) ->
      body = ''
      res2.on 'data', (d) ->
        body += d
      res2.on 'end', ->
        console.log 'after posting new room ' + json + ' we got reply: ' + body
        parsed = JSON.parse(body)
        return callback(parsed.id)
      )
    req.on 'error', (e) ->
      console.log 'Got error: ' + e.message
      callback(null)
    req.write(json)
    req.end()

  run: ->
    @socket = io.connect chatURL, connectOptions

    @socket.on 'connect', =>
      console.log 'connected'
      @socket.emit 'account:whoami', (profile) =>
        @robot.name = profile.username

        if !@connected
          @emit 'connected'
          @connected = true

        for slug in LCB_ROOMS
          @checkRoomId '#' + slug, (id) =>
            console.log 'No room id found for slug ' + slug if not id
            console.log 'Joining id ' + id
            @socket.emit 'rooms:join', id, (room) =>
              console.log 'Joined ' + room.name

    @socket.on 'error', (err) =>
      console.log err

    @socket.on 'disconnect', =>
      console.log 'Disconnected!'

    @socket.on 'users:join', (user) =>
      user = @robot.brain.userForId user.id,
        room: user.room,
        name: user.username

      @receive new EnterMessage user, null, user.id

    @socket.on 'messages:new', (message) =>
      user = @robot.brain.userForId message.owner.id,
        room: message.room.id,
        name: message.owner.username
      # Messages coming from Hubot itself must be filtered by the adapter
      unless message.owner.username is @robot.name
        @receive new TextMessage user, message.text

module.exports = (robot) ->
  new LCB robot
