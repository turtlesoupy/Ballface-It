express = require 'express'
async = require 'async'
jade = require 'jade'
fs = require 'fs'

Array.prototype.dict = ->
  ret = {}
  for e in this
    ret[e[0]] = e[1]
  ret

app = express.createServer()
app.use express.bodyParser()
app.use express.methodOverride()
app.use app.router

publicDir = __dirname + "/public"
app.use express.compiler(src: publicDir, dest: publicDir, enable: ['coffeescript'])
app.use express.static(publicDir)

saveDirectory = __dirname + "/data"
escapeFilename = (filename) ->
  filename.replace("/", "_")

glb =
  levels: []
  levelIdToLevel: {}
  levelIds: 0
  port: 31337

readLevel = (filename, callback) ->
  fs.readFile "#{saveDirectory}/#{filename}", 'UTF-8', (err, data) ->
    if err
      callback(err, null)
      return
    
    level = JSON.parse data
    level.filename = filename #In case we get out of sync
    callback(null, level)

deleteLevel = (level, callback) ->
  fs.unlink "#{saveDirectory}/#{level.filename}", callback

writeLevel = (level, callback) ->
  fs.writeFile "#{saveDirectory}/#{level.filename}", JSON.stringify(level, null, 4), callback

scanLevels = (callback) ->
  fs.readdir saveDirectory, (err, filenames) ->
    if err
      callback(err, null)
      return

    levelFilenames = (e for e in filenames when /\.json$/.test(e))
    console.log "Reading levels from #{levelFilenames}" if levelFilenames.length > 0

    async.map levelFilenames, readLevel, (err, levels) ->
      if err
        callback(err, null)
        return

      #Trash the actual level data
      for level in levels
        delete level["level"]

      glb.levels = levels
      glb.levelIdToLevel = ([e.id,e] for e in levels).dict()
      glb.levelIds = if levels.length == 0 then 0 else Math.max((e.id for e in levels)...) + 1
      callback(null, levels)

app.get '/', (req, res) ->
  res.render 'index.jade', {layout: false}

app.post '/save', (req, res) ->
  level = req.body.level
  console.log "Got a save request!"
  console.log level
  filename = escapeFilename("#{req.body.level.levelName}-#{glb.levelIds}.json")
  level = {
    id: glb.levelIds
    filename: filename
    saveTime: new Date()
    name: req.body.level.levelName
    level: req.body.level
  }
  glb.levelIds += 1

  res.contentType('json')
  writeLevel level, (err) ->
    if err
      console.log "Error saving level: #{err}"
      res.send JSON.stringify({ok: false})
      return

    scanLevels (err, levels) ->
      if err
        console.log "Error saving level: #{err}"
        res.send JSON.stringify({ok: false})
        return

      res.send JSON.stringify({ok: true})

app.get '/list', (req, res) ->
  res.contentType('json')
  res.send JSON.stringify(glb.levels)

app.get '/delete/:id', (req, res) ->
  id = parseInt req.params.id, 10
  level = glb.levelIdToLevel[id]
  res.contentType('json')
  unless level
    res.send JSON.stringify({ok: true})
    return

  deleteLevel level, (err) ->
    if err
      console.log err
    console.log "Deleted #{level.filename}"
    scanLevels (err, files) ->
      res.send JSON.stringify({ok: true})

app.get '/download/:id', (req, res) ->
  level = glb.levelIdToLevel[req.params.id]
  readLevel level.filename, (err, level) ->
    if err
      console.log "Error downloading level: #{err}"
      res.send JSON.stringify({})
      return

    res.contentType 'json'
    res.attachment level.filename
    res.send JSON.stringify(level)

scanLevels (err, files) ->
  if err
    console.log err
    return

  app.listen glb.port
  console.log "Listening on port #{glb.port}"
