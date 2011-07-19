#Helpers
Array.prototype.dict = ->
  ret = {}
  for e in this
    ret[e[0]] = e[1]
  ret

Object.prototype.getClass = ->
  @constructor

#Start implementation

class GameObject
  @name: "Unknown"
  @image: "unknown.png"
  @relativeImage: =>
    "data/game_objects/#{@image}"
  @counter = 0
  
  constructor: (@x, @y, loaded) ->
    @imageObject = new Image()
    @imageObject.onload = =>
      @width = @imageObject.width
      @height = @imageObject.height
      loaded(this)
    GameObject.counter += 1
    @id = GameObject.counter
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

class LevelModel
  constructor: ->
    @gameObjects = []
    @gameObjectsById = {}
    @selectedObject = null
    @modelChangeCallbacks = []

  hitTest: (x,y) ->
    for gameObject in @gameObjects
      if gameObject.hitTest x,y
        return gameObject
    null

  select: (objectName) ->
    if @selectedObject != objectName
      if @selectedObject != null
        @selectedObject.selected = false
      @selectedObject = objectName
      @selectedObject.selected = true
      @modelChanged()

  unselectAll: ->
    if @selectedObject != null
      @selectedObject.selected = false
      @selectedObject = null
      @modelChanged()

  getObjectById: (id) ->
    @gameObjectsById[parseInt id, 10]

  addModelChangeCallback: (callback) ->
    @modelChangeCallbacks.push callback

  modelChanged: ->
    e(this) for e in @modelChangeCallbacks

  reorder: ->
    @gameObjects.sort (a,b) -> a.x - b.x
    @modelChanged()

  addGameObject:(gameObject) ->
    @gameObjects.push(gameObject)
    @gameObjectsById[gameObject.id] = gameObject
    @reorder()

class LevelListing
  constructor: (@dom, @levelModel) ->
    @$dom = $(@dom)
    $(@dom).html "<li>No objects...</li>"
    @levelModel.addModelChangeCallback(@redraw)

  clear: =>
    $(@dom).empty()

  redraw: =>
    @clear()
    for gameObject in @levelModel.gameObjects
      @$dom.append($("<li class='listingObject#{if gameObject.selected then' selected' else ''}' data-id='#{gameObject.id}'>#{gameObject.getClass().name} @ #{gameObject.x}</li>"))


class LevelCanvas
  constructor: (@canvas, @levelModel) ->
    @selectedObject = null
    @draggingObject = null
    $(@canvas).mouseup @mouseUp
    $(@canvas).mousedown @mouseDown
    $(@canvas).mousemove @mouseMove
    @levelModel.addModelChangeCallback(@redraw)

  mouseDown: (e) =>
    hit = @levelModel.hitTest(e.offsetX, e.offsetY)
    if hit != null
      $(@canvas).css "cursor", "move"
      @draggingObject = hit
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
    $(@canvas).css "cursor", ""
    if !@didDrag
      hit = @levelModel.hitTest(e.offsetX, e.offsetY)
      if hit != null
        @levelModel.select hit
      else
        @levelModel.unselectAll()
    else
      @levelModel.reorder()

    @draggingObject = null

  setWidth:(@width) ->
    @width = width
    @canvas.width = width

  clear: ->
    @canvas.width = @canvas.width

  redraw: =>
    @clear()
    for gameObject in @levelModel.gameObjects
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
  levelModel = new LevelModel
  levelCanvas = new LevelCanvas canvas, levelModel
  levelListing = new LevelListing $("#levelListing").get(0), levelModel
  $(".listingObject").live 'click', ->
    levelModel.select(levelModel.getObjectById($(this).data('id')))

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
      gameObject = new klass(relativeLeft, relativeTop, (obj) ->
        levelModel.addGameObject gameObject)
  }
