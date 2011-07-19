(function() {
  var GameObject, GravityBall, LevelCanvas, Paddle, c, gameObjectClassByName, gameObjectClasses, layoutGameObjects;
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
  GameObject = (function() {
    GameObject.name = "Unknown";
    GameObject.image = "unknown.png";
    GameObject.relativeImage = function() {
      return "data/game_objects/" + this.image;
    };
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
      this.imageObject.src = this.constructor.relativeImage();
    }
    GameObject.prototype.draw = function(canvas) {
      var context;
      context = canvas.getContext("2d");
      return context.drawImage(this.imageObject, this.x, this.y, this.width, this.height);
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
  LevelCanvas = (function() {
    function LevelCanvas(canvas) {
      this.canvas = canvas;
      this.gameObjects = [];
    }
    LevelCanvas.prototype.setWidth = function(width) {
      this.width = width;
      this.width = width;
      return this.canvas.width = width;
    };
    LevelCanvas.prototype.addGameObject = function(gameObject) {
      return this.gameObjects.push(gameObject);
    };
    LevelCanvas.prototype.clear = function() {
      return this.canvas.width = this.canvas.width;
    };
    LevelCanvas.prototype.redraw = function() {
      var gameObject, _i, _len, _ref, _results;
      this.clear();
      _ref = this.gameObjects;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        gameObject = _ref[_i];
        _results.push(gameObject.draw(this.canvas));
      }
      return _results;
    };
    return LevelCanvas;
  })();
  gameObjectClasses = [Paddle, GravityBall];
  gameObjectClassByName = ((function() {
    var _i, _len, _results;
    _results = [];
    for (_i = 0, _len = gameObjectClasses.length; _i < _len; _i++) {
      c = gameObjectClasses[_i];
      _results.push([c.name, c]);
    }
    return _results;
  })()).dict();
  layoutGameObjects = function() {
    var gameObjectClass, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = gameObjectClasses.length; _i < _len; _i++) {
      gameObjectClass = gameObjectClasses[_i];
      _results.push($("#gameObjects").append($("<div class=\"gameObject\">\n  <img src=\"" + (gameObjectClass.relativeImage()) + "\" class=\"gameObjectImage\" data-game-object-class=\"" + gameObjectClass.name + "\"/>\n  <br />\n  <span class=\"gameObjectName\">" + gameObjectClass.name + "</span>\n</div>")));
    }
    return _results;
  };
  $(document).ready(function() {
    var canvas, iphoneWidth, levelCanvas;
    layoutGameObjects();
    iphoneWidth = 480;
    canvas = $("#editorCanvas").get(0);
    levelCanvas = new LevelCanvas(canvas);
    $("#editorMode").buttonset();
    $("#levelWidth").change(function() {
      var width;
      width = parseFloat($(this).val(), 10);
      return $("#levelWidthIPhones").text((width / iphoneWidth).toFixed(1));
    });
    $("#levelWidthCommit").click(function() {
      var intWidth;
      intWidth = parseInt($("#levelWidth").val(), 10);
      return levelCanvas.setWidth(intWidth);
    });
    $("#levelWidth").val(iphoneWidth * 2);
    $("#levelWidth").change();
    $("#levelWidthCommit").click();
    $(".gameObjectImage").draggable({
      helper: 'clone'
    });
    return $("#editorCanvas").droppable({
      drop: function(event, ui) {
        var dPos, klass, relativeLeft, relativeTop;
        dPos = $(this).offset();
        relativeTop = ui.offset.top - dPos.top;
        relativeLeft = ui.offset.left - dPos.left;
        klass = gameObjectClassByName[ui.draggable.data("gameObjectClass")];
        return levelCanvas.addGameObject(new klass(relativeLeft, relativeTop, function(obj) {
          return levelCanvas.redraw();
        }));
      }
    });
  });
}).call(this);
