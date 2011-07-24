(function() {
  var Fish, GameObject, GameObjectSelector, GravityBall, IntegerProperty, LevelCanvas, LevelListing, LevelModel, LevelProperties, ObjectInspector, Paddle, _class;
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
  Object.prototype.getClass = function() {
    return this.constructor;
  };
  IntegerProperty = (function() {
    function IntegerProperty() {
      _class.apply(this, arguments);
    }
    _class = (function(name, get, set) {
      this.name = name;
      this.get = get;
      this.set = set;
    });
    IntegerProperty.prototype.newPropertyListNode = function() {
      return $("<label for=\"" + this.name + "\" class=\"name\">" + this.name + "</label> \n<input type='text' name=\"" + this.name + "\" class=\"value\" value=\"" + (this.get()) + "\" />").bind('change', __bind(function(e) {
        this.set(parseInt(e.target.value, 10));
        return $(e.target).val(this.get());
      }, this));
    };
    return IntegerProperty;
  })();
  LevelProperties = (function() {
    function LevelProperties(node, levelModel) {
      this.node = node;
      this.levelModel = levelModel;
      this.redraw = __bind(this.redraw, this);
      this.$node = $(this.node);
      this.levelModel.addModelChangeCallback(this.redraw);
      this.redraw();
    }
    LevelProperties.prototype.redraw = function() {
      var property, _i, _len, _ref, _results;
      this.$node.empty();
      _ref = this.levelModel.gameProperties();
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        property = _ref[_i];
        _results.push(this.$node.append(property.newPropertyListNode()).append("<br />"));
      }
      return _results;
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
          return gameObject = new klass(relativeLeft, relativeTop, this.levelModel, __bind(function(obj) {
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
        var gameObject, gameProperty;
        gameObject = this.levelModel.getObjectById($(e.target).data('id'));
        gameProperty = gameObject.getClass().getGamePropertyByName(e.target.name);
        gameObject[e.target.name] = gameProperty.convertString(e.target.value);
        $(e.target).val(gameObject[e.target.name]);
        return this.levelModel.modelChanged();
      }, this));
    }
    ObjectInspector.prototype.redraw = function() {
      var property, selected, _i, _len, _ref, _results;
      selected = this.levelModel.selectedObject;
      if (selected === null) {
        return this.$node.text("No selection...");
      } else {
        this.$node.empty().append("<h3>" + (selected.getClass().name) + " Properties</h3>");
        _ref = selected.gameProperties();
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          property = _ref[_i];
          _results.push(this.$node.append(property.newPropertyListNode()).append("<br />"));
        }
        return _results;
      }
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
    function GameObject(x, y, levelModel, loaded) {
      this.x = x;
      this.y = y;
      this.levelModel = levelModel;
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
    GameObject.prototype.gameProperties = function() {
      return this._gameProperties || (this._gameProperties = [
        new IntegerProperty("x", (__bind(function() {
          return this.x;
        }, this)), (__bind(function(v) {
          this.x = v;
          return this.levelModel.modelChanged();
        }, this))), new IntegerProperty("y", (__bind(function() {
          return this.y;
        }, this)), (__bind(function(v) {
          this.y = v;
          return this.levelModel.modelChanged();
        }, this)))
      ]);
    };
    GameObject.prototype.hitTest = function(x, y) {
      return x >= this.x && x <= this.x + this.width && y >= this.y && y <= this.y + this.height;
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
  Fish = (function() {
    __extends(Fish, GameObject);
    function Fish() {
      Fish.__super__.constructor.apply(this, arguments);
    }
    Fish.name = "Fish";
    Fish.image = "fishEnemy.png";
    return Fish;
  })();
  LevelModel = (function() {
    function LevelModel() {
      var c;
      this.gameObjects = [];
      this.gameObjectsById = {};
      this.selectedObject = null;
      this.modelChangeCallbacks = [];
      this.width = 960;
      this.gameObjectClasses = [Paddle, GravityBall, Fish];
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
    LevelModel.prototype.gameProperties = function() {
      return this._gameProperties || (this._gameProperties = [
        new IntegerProperty("width", (__bind(function() {
          return this.width;
        }, this)), (__bind(function(val) {
          this.width = val;
          return this.modelChanged();
        }, this)))
      ]);
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
