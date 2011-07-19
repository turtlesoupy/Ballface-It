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
    @selected = false

  draw: (canvas) ->
    context = canvas.getContext "2d"
    extra = 2
    if @selected
      context.fillStyle = "#00f"
      context.fillRect @x - extra,@y - extra,@width + 2*extra,@height + 2*extra
    context.drawImage @imageObject, @x, @y, @width, @height

  hitTest: (x,y) ->
    x >= @x && x <= @x + @width && y >= @y && y <= @y + @height


class Paddle extends GameObject
  @name: "Wooden Paddle"
  @image: "paddle.png"

class GravityBall extends GameObject
  @name: "Gravity Ball"
  @image: "gravityball.png"

class LevelCanvas
  constructor: (@canvas) ->
    @gameObjects = []
    @selectedObject = null
    @draggingObject = null
    $(@canvas).mouseup @mouseUp
    $(@canvas).mousedown @mouseDown
    $(@canvas).mousemove @mouseMove

  mouseDown: (e) =>
    hit = @hitTest(e.offsetX, e.offsetY)
    if hit != null
      @draggingObject = hit
      console.log "Dragging!"
      @dragLastX = e.offsetX
      @dragLastY = e.offsetY
      @didDrag = false

  mouseMove: (e) =>
    if @draggingObject == null
      return

    @didDrag = true
    @draggingObject.x += e.offsetX - @dragLastX
    @draggingObject.y += e.offsetY - @dragLastY
    @dragLastX = e.offsetX
    @dragLastY = e.offsetY
    @redraw()

  mouseUp: (e) =>
    if !@didDrag
      oldSelection = @selectedObject
      if @selectedObject != null
        @selectedObject.selected = false
        @selectedObject = null

      hit = @hitTest(e.offsetX, e.offsetY)
      if hit != null && hit != oldSelection
        hit.selected = true
        @selectedObject = hit

    @draggingObject = null
    @redraw()

  setWidth:(@width) ->
    @width = width
    @canvas.width = width

  addGameObject: (gameObject) ->
    @gameObjects.push(gameObject)

  hitTest: (x,y) ->
    for gameObject in @gameObjects
      if gameObject.hitTest x,y
        return gameObject
    null 

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
