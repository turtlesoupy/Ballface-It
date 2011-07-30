VERSION = 0.1
SAVES_INDEX = 4

#
# Convinience 
#
Array.prototype.dict = ->
  ret = {}
  for e in this
    ret[e[0]] = e[1]
  ret

#Not placing on the object prototype due to serialization concerns
class Base
  getClass: ->
    @constructor

#
# Properties
#
class IntegerProperty extends Base
  constructor:((@name, @get, @set) -> )
  newPropertyListNode: ->
    $("""
    <label for="#{@name}" class="name">#{@name}</label> 
    <input type='text' name="#{@name}" class="value" value="#{@get()}" />
    """).bind 'change', (e) =>
      @set parseInt(e.target.value, 10)
      $(e.target).val @get()

class StringProperty extends Base
  constructor:((@name, @get, @set) -> )
  newPropertyListNode: ->
    $("""
    <label for="#{@name}" class="name">#{@name}</label> 
    <input type='text' name="#{@name}" class="value" value="#{@get()}" />
    """).bind 'change', (e) =>
      @set e.target.value
      $(e.target).val @get()
#
# Widgets
# 
class LevelProperties extends Base
  constructor: (@node, @levelModel) ->
    @$node = $(@node)
    @levelModel.addModelChangeCallback(@redraw)
    @redraw()

  redraw: =>
    @$node.empty()
    for property in @levelModel.gameProperties()
      @$node.append(property.newPropertyListNode()).append("<br />")

class LevelCanvas extends Base
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
        gameObject = new klass(relativeLeft, relativeTop, @levelModel, (obj) =>
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

class LevelListing extends Base
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

class ObjectInspector extends Base
  constructor: (@node, @levelModel) ->
    @$node = $(@node)
    @redraw()
    @levelModel.addModelChangeCallback(@redraw)
    $(".gameObjectProperty .value").live 'change', (e) =>
      gameObject = @levelModel.getObjectById($(e.target).data('id'))
      gameProperty = gameObject.getClass().getGamePropertyByName(e.target.name)
      gameObject[e.target.name] = gameProperty.convertString(e.target.value)
      $(e.target).val gameObject[e.target.name]
      @levelModel.modelChanged()

  redraw: =>
    selected = @levelModel.selectedObject
    if selected == null
      @$node.text "No selection..."
    else
      @$node.empty().append("<h3>#{selected.getClass().name} Properties</h3>")
      for property in selected.gameProperties()
        @$node.append(property.newPropertyListNode()).append("<br />")

class GameObjectSelector extends Base
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

class SavedLister extends Base
  constructor: (@node, @levelModel) ->
    @$node = $(@node)
    @data = []
    @redraw()

  repopulate: ->
    @$node.html "<div class='loader'/>"
    $.get "/list", (data) =>
      @data = data
      console.dir data
      @redraw()

  redraw: ->
    html = for levelData in @data
      saveTime = new Date(levelData.saveTime)
      """
      <li class="levelItem">
        <span class="name">#{levelData.name}</span> @ #{saveTime}
        [<a href="/download/#{levelData.id}">Download</a>]
        [<a href="/delete/#{levelData.id}" class="deleteLevel" data-name="#{levelData.name} @ #{saveTime}">Delete</a>]
      </li>
      """

    @$node.html "<ul>#{html.join("")}</ul>"
    @$node.find(".deleteLevel").click (e) =>
      e.preventDefault()
      if confirm("Are you sure you want to delete #{$(e.target).data('name')}?")
        $.get e.target.href, =>
          @repopulate()

#
# Game objects
# 

class GameObject extends Base
  @name: "Unknown"
  @image: "unknown.png"
  @relativeImage: =>
    "data/game_objects/#{@image}"
  @counter = 0

  constructor: (@x, @y, @levelModel, loaded) ->
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
  
  gameProperties: ->
    @_gameProperties or= [
      new IntegerProperty("x", (=> @x), ((v) =>
        @x = v
        @levelModel.modelChanged()
      ))
      new IntegerProperty("y", (=> @y), ((v) =>
        @y = v
        @levelModel.modelChanged()
      ))
    ]

  hitTest: (x,y) ->
    x >= @x && x <= @x + @width && y >= @y && y <= @y + @height

  serialized: ->
    {
      type: @getClass().name
      x: @x
      y: @y
    }

class Paddle extends GameObject
  @name: "Wooden Paddle"
  @image: "paddle.png"

class GravityBall extends GameObject
  @name: "Gravity Ball"
  @image: "gravityball.png"

class Fish extends GameObject
  @name: "Fish"
  @image: "fishEnemy.png"

#
# -The- level
#

class LevelModel extends Base
  constructor: ->
    @gameObjects = []
    @gameObjectsById = {}
    @selectedObject = null
    @modelChangeCallbacks = []
    @width = 960
    @levelName = "Unnamed level"
    @gameObjectClasses = [Paddle, GravityBall, Fish]
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

  gameProperties: ->
    @_gameProperties or= [
      new StringProperty("levelName", (=> @levelName), (val) => @levelName = val),
      new IntegerProperty("width", (=> @width), ((val) =>
        @width = val
        @modelChanged()
      ))
    ]

  serialized: ->
    {
      levelName: @levelName
      objects: e.serialized() for e in @gameObjects
      width: @width
      editorVersion: VERSION
    }

$(document).ready ->
  levelModel = new LevelModel
  levelCanvas = new LevelCanvas $("#editorCanvas").get(0), levelModel
  levelListing = new LevelListing $("#levelListing").get(0), levelModel
  objectInspetor = new ObjectInspector $("#objectInspector").get(0), levelModel
  levelProperties = new LevelProperties $("#levelProperties").get(0), levelModel
  gameObjectSelector = new GameObjectSelector $("#gameObjects").get(0), levelModel
  savedLister = new SavedLister $("#levelSaves").get(0), levelModel

  $("#objectTabs").tabs().bind 'tabsselect', (e, ui) ->
    if ui.index == SAVES_INDEX
      savedLister.repopulate()

  $("#saveLevel").submit (e) ->
    e.preventDefault()
    $("#saveLevelSubmit").attr 'disabled', true
    $.ajax {
      type: "POST"
      url: "/save"
      data:
        level: levelModel.serialized()
      dataType: "json"
      success: ->
        $("#saveLevelSubmit").attr 'disabled', false
        savedLister.repopulate()
      error: ->
        $("#saveLevelSubmit").attr 'disabled', false
        alert 'Failed to save!'
    }


