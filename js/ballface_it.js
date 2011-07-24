(function() {
  var GameObject, GameObjectSelector, GravityBall, LevelCanvas, LevelListing, LevelModel, LevelProperties, ObjectInspector, Paddle;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  Array.prototype.dict = function() {
    var e, ret, _i, _len;
    ret = {};
    for (_i = 0, _len = this.length; _i < _len; _i++) {
      e = this[_i];
      ret[e[0]] = e[1];
    }
    return ret;
  };
  Array.prototype.set = function() {
    var e, ret, _i, _len;
    ret = {};
    for (_i = 0, _len = this.length; _i < _len; _i++) {
      e = this[_i];
      ret[e[0]] = true;
    }
    return ret;
  };
  Object.prototype.getClass = function() {
    return this.constructor;
  };
  LevelProperties = (function() {
    function LevelProperties(node, levelModel) {
      this.node = node;
      this.levelModel = levelModel;
      $(this.node).html(this.propertyListHTML());
      $(".levelProperty .value").live('change', __bind(function(e) {
        levelModel.setProperty(e.target.name, e.target.value);
        $(e.target).val(levelModel[e.target.name]);
        return this.levelModel.modelChanged();
      }, this));
    }
    LevelProperties.prototype.propertyListHTML = function() {
      var name, ret, val;
      ret = (function() {
        var _i, _len, _ref, _ref2, _results;
        _ref = this.levelModel.properties();
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          _ref2 = _ref[_i], name = _ref2[0], val = _ref2[1];
          _results.push("<div class='levelProperty'>\n  <label for=\"" + name + "\" class=\"name\">" + name + "</label> <input type='text' name=\"" + name + "\" class=\"value\" value=\"" + val + "\" />\n</div>");
        }
        return _results;
      }).call(this);
      return ret.join("");
    };
    return LevelProperties;
  })();
  LevelCanvas = (function() {
    function LevelCanvas(canvas, levelModel) {
      this.canvas = canvas;
      this.levelModel = levelModel;
      this.redraw = __bind(this.redraw, this);
      this.mouseUp = __bind(this.mouseUp, this);
      this.mouseMove = __bind(this.mouseMove, this);
      this.mouseDown = __bind(this.mouseDown, this);
      this.selectedObject = null;
      this.draggingObject = null;
      $(this.canvas).mouseup(this.mouseUp);
      $(this.canvas).mousedown(this.mouseDown);
      $(this.canvas).mousemove(this.mouseMove);
      this.levelModel.addModelChangeCallback(this.redraw);
      $(this.canvas).droppable({
        drop: __bind(function(event, ui) {
          var dPos, gameObject, klass, relativeLeft, relativeTop;
          dPos = $(this.canvas).offset();
          relativeTop = ui.offset.top - dPos.top;
          relativeLeft = ui.offset.left - dPos.left;
          klass = this.levelModel.gameObjectClassByName[ui.draggable.data("gameObjectClass")];
          return gameObject = new klass(relativeLeft, relativeTop, __bind(function(obj) {
            return this.levelModel.addGameObject(gameObject);
          }, this));
        }, this)
      });
    }
    LevelCanvas.prototype.mouseDown = function(e) {
      var hit;
      hit = this.levelModel.hitTest(e.offsetX, e.offsetY);
      if (hit !== null) {
        $(this.canvas).css("cursor", "move");
        this.draggingObject = hit;
        this.dragLastX = e.offsetX;
        this.dragLastY = e.offsetY;
        return this.didDrag = false;
      }
    };
    LevelCanvas.prototype.mouseMove = function(e) {
      if (this.draggingObject === null) {
        return;
      }
      this.didDrag = true;
      this.draggingObject.x += e.offsetX - this.dragLastX;
      this.draggingObject.y += e.offsetY - this.dragLastY;
      this.dragLastX = e.offsetX;
      this.dragLastY = e.offsetY;
      return this.redraw();
    };
    LevelCanvas.prototype.mouseUp = function(e) {
      var hit;
      $(this.canvas).css("cursor", "");
      if (!this.didDrag) {
        hit = this.levelModel.hitTest(e.offsetX, e.offsetY);
        if (hit !== null) {
          this.levelModel.select(hit);
        } else {
          this.levelModel.unselectAll();
        }
      } else {
        this.levelModel.reorder();
      }
      return this.draggingObject = null;
    };
    LevelCanvas.prototype.clear = function() {
      return this.canvas.width = this.levelModel.width;
    };
    LevelCanvas.prototype.redraw = function() {
      var gameObject, _i, _len, _ref, _results;
      this.clear();
      _ref = this.levelModel.gameObjects;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        gameObject = _ref[_i];
        _results.push(gameObject.draw(this.canvas));
      }
      return _results;
    };
    return LevelCanvas;
  })();
  LevelListing = (function() {
    function LevelListing(node, levelModel) {
      this.node = node;
      this.levelModel = levelModel;
      this.redraw = __bind(this.redraw, this);
      this.clear = __bind(this.clear, this);
      this.$node = $(this.node);
      this.$node.html("<li>No objects...</li>");
      this.levelModel.addModelChangeCallback(this.redraw);
      $(".listingObject").live('click', function() {
        return levelModel.select(levelModel.getObjectById($(this).data('id')));
      });
    }
    LevelListing.prototype.clear = function() {
      return this.$node.empty();
    };
    LevelListing.prototype.redraw = function() {
      var gameObject, _i, _len, _ref, _results;
      this.clear();
      _ref = this.levelModel.gameObjects;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        gameObject = _ref[_i];
        _results.push(this.$node.append($("<li class='listingObject" + (gameObject.selected ? ' selected' : '') + "' data-id='" + gameObject.id + "'>" + (gameObject.getClass().name) + " @ " + gameObject.x + "</li>")));
      }
      return _results;
    };
    return LevelListing;
  })();
  ObjectInspector = (function() {
    function ObjectInspector(node, levelModel) {
      this.node = node;
      this.levelModel = levelModel;
      this.redraw = __bind(this.redraw, this);
      this.$node = $(this.node);
      this.redraw();
      this.levelModel.addModelChangeCallback(this.redraw);
      $(".gameObjectProperty .value").live('change', __bind(function(e) {
        var gameObject;
        gameObject = this.levelModel.getObjectById($(e.target).data('id'));
        gameObject.setProperty(e.target.name, e.target.value);
        $(e.target).val(gameObject[e.target.name]);
        return this.levelModel.modelChanged();
      }, this));
    }
    ObjectInspector.prototype.redraw = function() {
      var selected;
      selected = this.levelModel.selectedObject;
      if (selected === null) {
        return this.$node.text("No selection...");
      } else {
        return this.$node.html("<h3>" + (selected.getClass().name) + " Properties</h3>\n" + (this.propertyListHTML(selected)));
      }
    };
    ObjectInspector.prototype.propertyListHTML = function(gameObject) {
      var name, ret, val;
      ret = (function() {
        var _i, _len, _ref, _ref2, _results;
        _ref = gameObject.properties();
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          _ref2 = _ref[_i], name = _ref2[0], val = _ref2[1];
          _results.push("<div class='gameObjectProperty'>\n  <label for=\"" + name + "\" class=\"name\">" + name + "</label> <input data-id=\"" + gameObject.id + "\" type='text' name=\"" + name + "\" class=\"value\" value=\"" + val + "\" />\n</div>");
        }
        return _results;
      })();
      return ret.join("");
    };
    return ObjectInspector;
  })();
  GameObjectSelector = (function() {
    function GameObjectSelector(node, levelModel) {
      var gameObjectClass, html;
      this.node = node;
      this.levelModel = levelModel;
      html = (function() {
        var _i, _len, _ref, _results;
        _ref = this.levelModel.gameObjectClasses;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          gameObjectClass = _ref[_i];
          _results.push("<div class=\"gameObject\">\n  <img src=\"" + (gameObjectClass.relativeImage()) + "\" class=\"gameObjectImage\" data-game-object-class=\"" + gameObjectClass.name + "\"/>\n  <br />\n  <span class=\"gameObjectName\">" + gameObjectClass.name + "</span>\n</div>");
        }
        return _results;
      }).call(this);
      $(this.node).append(html.join(""));
      $(".gameObjectImage").draggable({
        helper: 'clone'
      });
    }
    return GameObjectSelector;
  })();
  GameObject = (function() {
    GameObject.name = "Unknown";
    GameObject.image = "unknown.png";
    GameObject.relativeImage = function() {
      return "data/game_objects/" + this.image;
    };
    GameObject.counter = 0;
    function GameObject(x, y, loaded) {
      this.x = x;
      this.y = y;
      this.GameObject = __bind(this.GameObject, this);
      this.imageObject = new Image();
      this.imageObject.onload = __bind(function() {
        this.width = this.imageObject.width;
        this.height = this.imageObject.height;
        return loaded(this);
      }, this);
      GameObject.counter += 1;
      this.id = GameObject.counter;
      this.imageObject.src = this.constructor.relativeImage();
      this.selected = false;
    }
    GameObject.prototype.integerProperties = function() {
      return ["x", "y"].set();
    };
    GameObject.prototype.draw = function(canvas) {
      var context, extra;
      context = canvas.getContext("2d");
      extra = 2;
      if (this.selected) {
        context.fillStyle = "#00f";
        context.fillRect(this.x - extra, this.y - extra, this.width + 2 * extra, this.height + 2 * extra);
      }
      return context.drawImage(this.imageObject, this.x, this.y, this.width, this.height);
    };
    GameObject.prototype.hitTest = function(x, y) {
      return x >= this.x && x <= this.x + this.width && y >= this.y && y <= this.y + this.height;
    };
    GameObject.prototype.setProperty = function(name, value) {
      if (name in this.integerProperties()) {
        return this[name] = parseInt(value, 10);
      } else {
        return this[name] = value;
      }
    };
    GameObject.prototype.propertyList = function(names) {
      var e, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = names.length; _i < _len; _i++) {
        e = names[_i];
        _results.push([e, this[e]]);
      }
      return _results;
    };
    GameObject.prototype.properties = function() {
      return this.propertyList(["x", "y"]);
    };
    return GameObject;
  })();
  Paddle = (function() {
    __extends(Paddle, GameObject);
    function Paddle() {
      Paddle.__super__.constructor.apply(this, arguments);
    }
    Paddle.name = "Wooden Paddle";
    Paddle.image = "paddle.png";
    return Paddle;
  })();
  GravityBall = (function() {
    __extends(GravityBall, GameObject);
    function GravityBall() {
      GravityBall.__super__.constructor.apply(this, arguments);
    }
    GravityBall.name = "Gravity Ball";
    GravityBall.image = "gravityball.png";
    return GravityBall;
  })();
  LevelModel = (function() {
    function LevelModel() {
      var c;
      this.gameObjects = [];
      this.gameObjectsById = {};
      this.selectedObject = null;
      this.modelChangeCallbacks = [];
      this.width = 960;
      this.gameObjectClasses = [Paddle, GravityBall];
      this.gameObjectClassByName = ((function() {
        var _i, _len, _ref, _results;
        _ref = this.gameObjectClasses;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          c = _ref[_i];
          _results.push([c.name, c]);
        }
        return _results;
      }).call(this)).dict();
    }
    LevelModel.prototype.hitTest = function(x, y) {
      var gameObject, _i, _len, _ref;
      _ref = this.gameObjects;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        gameObject = _ref[_i];
        if (gameObject.hitTest(x, y)) {
          return gameObject;
        }
      }
      return null;
    };
    LevelModel.prototype.select = function(objectName) {
      if (this.selectedObject !== objectName) {
        if (this.selectedObject !== null) {
          this.selectedObject.selected = false;
        }
        this.selectedObject = objectName;
        this.selectedObject.selected = true;
        return this.modelChanged();
      }
    };
    LevelModel.prototype.unselectAll = function() {
      if (this.selectedObject !== null) {
        this.selectedObject.selected = false;
        this.selectedObject = null;
        return this.modelChanged();
      }
    };
    LevelModel.prototype.getObjectById = function(id) {
      return this.gameObjectsById[parseInt(id, 10)];
    };
    LevelModel.prototype.addModelChangeCallback = function(callback) {
      return this.modelChangeCallbacks.push(callback);
    };
    LevelModel.prototype.modelChanged = function() {
      var e, _i, _len, _ref, _results;
      _ref = this.modelChangeCallbacks;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        e = _ref[_i];
        _results.push(e(this));
      }
      return _results;
    };
    LevelModel.prototype.reorder = function() {
      this.gameObjects.sort(function(a, b) {
        return a.x - b.x;
      });
      return this.modelChanged();
    };
    LevelModel.prototype.addGameObject = function(gameObject) {
      this.gameObjects.push(gameObject);
      this.gameObjectsById[gameObject.id] = gameObject;
      return this.reorder();
    };
    LevelModel.prototype.setProperty = function(name, value) {
      return this[name] = parseInt(value, 10);
    };
    LevelModel.prototype.propertyList = function(names) {
      var e, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = names.length; _i < _len; _i++) {
        e = names[_i];
        _results.push([e, this[e]]);
      }
      return _results;
    };
    LevelModel.prototype.properties = function() {
      return this.propertyList(["width"]);
    };
    return LevelModel;
  })();
  $(document).ready(function() {
    var canvas, gameObjectSelector, levelCanvas, levelListing, levelModel, levelProperties, objectInspetor;
    $("#objectTabs").tabs();
    canvas = $("#editorCanvas").get(0);
    levelModel = new LevelModel;
    levelCanvas = new LevelCanvas(canvas, levelModel);
    levelListing = new LevelListing($("#levelListing").get(0), levelModel);
    objectInspetor = new ObjectInspector($("#objectInspector").get(0), levelModel);
    levelProperties = new LevelProperties($("#levelProperties").get(0), levelModel);
    return gameObjectSelector = new GameObjectSelector($("#gameObjects").get(0), levelModel);
  });
}).call(this);
