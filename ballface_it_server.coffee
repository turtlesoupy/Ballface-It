express = require 'express'
jade = require 'jade'

app = express.createServer()
app.use express.bodyParser()
app.use express.methodOverride()
app.use app.router

publicDir = __dirname + "/public"
app.use express.compiler(src: publicDir, dest: publicDir, enable: ['coffeescript'])
app.use express.static(publicDir)

levels = []
levelIdToLevel = {}
levelIds = 0

app.get '/', (req, res) ->
  res.render 'index.jade', {layout: false}

app.post '/save', (req, res) ->
  level = req.body.level
  console.log "Got a save request!"
  console.log level
  level = {
    id: levelIds
    saveTime: new Date(),
    name: req.body.level.levelName
    level: req.body.level
  }
  levels.push level
  levelIdToLevel[levelIds] = level
  levelIds += 1
  res.contentType('json')
  res.send JSON.stringify({ok: true})

app.get '/list', (req, res) ->
  res.contentType('json')
  res.send JSON.stringify({id: e.id, saveTime: e.saveTime, name: e.name} for e in levels)

app.get '/delete/:id', (req, res) ->
  id = parseInt req.params.id, 10
  delete levelIdToLevel[id]
  levels = (e for e in levels when e.id != id)

  res.contentType('json')
  res.send JSON.stringify({ok: true})

app.get '/download/:id', (req, res) ->
  level = levelIdToLevel[req.params.id]
  res.contentType 'json'
  if level
    res.attachment "#{level.name}.json"
  res.send JSON.stringify(level)

app.listen 31337
