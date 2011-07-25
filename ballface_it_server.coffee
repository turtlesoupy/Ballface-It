express = require 'express'
jade = require 'jade'

app = express.createServer()
app.use app.router
app.use express.static(__dirname + '/public')

app.get '/', (req, res) ->
  res.render 'index.jade', {layout: false}

app.listen 3000
