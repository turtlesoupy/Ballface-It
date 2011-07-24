#Helpers
Array::dict = ->
  ret = {}
  for e in this
    ret[e[0]] = e[1]
  ret

Array::set = ->
  ret = {}
  for e in this
    ret[e[0]] = yes
  ret

Object::getClass = ->
  @constructor

#
# Widgets
# 
class LevelProperties
  constructor: (@node, @levelModel) ->
    $(@node).html(@propertyListHTML())
    $(".levelProperty .value").live 'change', (e) =>
      levelModel.setProperty e.target.name, e.target.value
      $(e.target).val levelModel[e.target.name]
      @levelModel.modelChanged()

  propertyListHTML: ->
    ret = for [name, val] in @levelModel.properties()
      """
      <div class='levelProperty'>
        <label for="#{name}" class="name">#{name}</label> <input type='text' name="#{name}" class="value" value="#{val}" />
      </div>
      """
    ret.join("")

class LevelCanvas
  constructor: (@canvas, @levelModel) ->
    @selectedObject = null
    @draggingObject = null
    $(@canvas).mouseup @mouseUp
    $(@canvas).mousedown @mouseDown
    $(@canvas).mousemove @mouseMove
    @levelModel.addModelChangeCallback(@redraw)
    $(@canvas).droppable {
      drop: (event,ui) =>
        dPos = $(@canvas).offset()
        relativeTop = ui.offset.top - dPos.top
        relativeLeft = ui.offset.left - dPos.left
        klass = @levelModel.gameObjectClassByName[ui.draggable.data("gameObjectClass")]
        gameObject = new klass(relativeLeft, relativeTop, (obj) =>
          @levelModel.addGameObject gameObject)
    }

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

  clear: ->
    @canvas.width = @levelModel.width

  redraw: =>
    @clear()
    for gameObject in @levelModel.gameObjects
      gameObject.draw @canvas

class LevelListing
  constructor: (@node, @levelModel) ->
    @$node = $(@node)
    @$node.html "<li>No objects...</li>"
    @levelModel.addModelChangeCallback(@redraw)
    $(".listingObject").live 'click', ->
      levelModel.select(levelModel.getObjectById($(this).data('id')))

  clear: =>
    @$node.empty()

  redraw: =>
    @clear()
    for gameObject in @levelModel.gameObjects
      @$node.append($("<li class='listingObject#{if gameObject.selected then' selected' else ''}' data-id='#{gameObject.id}'>#{gameObject.getClass().name} @ #{gameObject.x}</li>"))

class ObjectInspector
  constructor: (@node, @levelModel) ->
    @$node = $(@node)
    @redraw()
    @levelModel.addModelChangeCallback(@redraw)
    $(".gameObjectProperty .value").live 'change', (e) =>
      gameObject = @levelModel.getObjectById($(e.target).data('id'))
      gameObject.setProperty e.target.name, e.target.value
      $(e.target).val gameObject[e.target.name]
      @levelModel.modelChanged()

  redraw: =>
    selected = @levelModel.selectedObject
    if selected == null
      @$node.text "No selection..."
    else
      @$node.html """
        <h3>#{selected.getClass().name} Properties</h3>
        #{@propertyListHTML(selected)}
      """

  propertyListHTML: (gameObject) ->
    ret = for [name, val] in gameObject.properties()
      """
      <div class='gameObjectProperty'>
        <label for="#{name}" class="name">#{name}</label> <input data-id="#{gameObject.id}" type='text' name="#{name}" class="value" value="#{val}" />
      </div>
      """
    ret.join("")

class GameObjectSelector
  constructor: (@node, @levelModel) ->
    html = for gameObjectClass in @levelModel.gameObjectClasses
      """
        <div class="gameObject">
          <img src="#{gameObjectClass.relativeImage()}" class="gameObjectImage" data-game-object-class="#{gameObjectClass.name}"/>
          <br />
          <span class="gameObjectName">#{gameObjectClass.name}</span>
        </div>
      """

    $(@node).append html.join("")
    $(".gameObjectImage" ).draggable {helper: 'clone'}

#
# Game objects
# 
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

  integerProperties: ->
    ["x","y"].set()

  draw: (canvas) ->
    context = canvas.getContext "2d"
    extra = 2
    if @selected
      context.fillStyle = "#00f"
      context.fillRect @x - extra,@y - extra,@width + 2*extra,@height + 2*extra
    context.drawImage @imageObject, @x, @y, @width, @height

  hitTest: (x,y) ->
    x >= @x && x <= @x + @width && y >= @y && y <= @y + @height

  setProperty: (name, value) ->
    if name of @integerProperties()
      this[name] = parseInt(value, 10)
    else
      this[name] = value

  propertyList: (names) ->
    [e, this[e]] for e in names

  properties: ->
    @propertyList [
      "x", "y"
    ]

class Paddle extends GameObject
  @name: "Wooden Paddle"
  @image: "paddle.png"

class GravityBall extends GameObject
  @name: "Gravity Ball"
  @image: "gravityball.png"

#
# -The- level
#

class LevelModel
  constructor: ->
    @gameObjects = []
    @gameObjectsById = {}
    @selectedObject = null
    @modelChangeCallbacks = []
    @width = 960
    @gameObjectClasses = [Paddle, GravityBall]
    @gameObjectClassByName = ([c.name,c] for c in @gameObjectClasses).dict()

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

  setProperty: (name, value) ->
    this[name] = parseInt value, 10

  propertyList: (names) ->
    [e, this[e]] for e in names

  properties: ->
    @propertyList [
      "width"
    ]

$(document).ready ->
  $("#objectTabs").tabs()

  canvas = $("#editorCanvas").get(0)
  levelModel = new LevelModel
  levelCanvas = new LevelCanvas canvas, levelModel
  levelListing = new LevelListing $("#levelListing").get(0), levelModel
  objectInspetor = new ObjectInspector $("#objectInspector").get(0), levelModel
  levelProperties = new LevelProperties $("#levelProperties").get(0), levelModel
  gameObjectSelector = new GameObjectSelector $("#gameObjects").get(0), levelModel
