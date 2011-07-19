#Helpers
Array.prototype.dict = ->
  ret = {}
  for e in this
    ret[e[0]] = e[1]
  ret

#Start implementation

class GameObject
  @name: "Unknown"
  @image: "unknown.png"
  @relativeImage: =>
    "data/game_objects/#{@image}"
  
  constructor: (@x, @y, loaded) ->
    @imageObject = new Image()
    @imageObject.onload = =>
      @width = @imageObject.width
      @height = @imageObject.height
      loaded(this)
    @imageObject.src = @constructor.relativeImage()

  draw: (canvas) ->
    context = canvas.getContext "2d"
    context.drawImage @imageObject, @x, @y, @width, @height

class Paddle extends GameObject
  @name: "Wooden Paddle"
  @image: "paddle.png"

class GravityBall extends GameObject
  @name: "Gravity Ball"
  @image: "gravityball.png"

class LevelCanvas
  constructor: (@canvas) ->
    @gameObjects = []

  setWidth:(@width) ->
    @width = width
    @canvas.width = width

  addGameObject: (gameObject) ->
    @gameObjects.push(gameObject)

  clear: ->
    @canvas.width = @canvas.width

  redraw: ->
    @clear()
    for gameObject in @gameObjects
      gameObject.draw @canvas

#Some globals
gameObjectClasses = [
  Paddle,
  GravityBall
]
gameObjectClassByName = ([c.name,c] for c in gameObjectClasses).dict()

layoutGameObjects = ->
  for gameObjectClass in gameObjectClasses
    $("#gameObjects").append($("""
      <div class="gameObject">
        <img src="#{gameObjectClass.relativeImage()}" class="gameObjectImage" data-game-object-class="#{gameObjectClass.name}"/>
        <br />
        <span class="gameObjectName">#{gameObjectClass.name}</span>
      </div>
    """))


$(document).ready ->
  layoutGameObjects()
  iphoneWidth = 480

  canvas = $("#editorCanvas").get(0)
  levelCanvas = new LevelCanvas(canvas)

  $("#editorMode").buttonset()

  $("#levelWidth").change ->
    width = parseFloat($(this).val(), 10)
    $("#levelWidthIPhones").text((width / iphoneWidth).toFixed(1))

    
  $("#levelWidthCommit").click ->
    intWidth = parseInt($("#levelWidth").val(), 10)
    levelCanvas.setWidth intWidth

  $("#levelWidth").val(iphoneWidth * 2)
  $("#levelWidth").change()
  $("#levelWidthCommit").click()

  $(".gameObjectImage" ).draggable {
    helper: 'clone'
  }

  $("#editorCanvas").droppable {
    drop: (event,ui) ->
      dPos = $(this).offset()
      relativeTop = ui.offset.top - dPos.top
      relativeLeft = ui.offset.left - dPos.left
      klass = gameObjectClassByName[ui.draggable.data("gameObjectClass")]
      levelCanvas.addGameObject new klass(relativeLeft, relativeTop, (obj) ->
        levelCanvas.redraw())
  }
