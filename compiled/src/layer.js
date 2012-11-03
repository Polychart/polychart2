(function() {
  var Layer, Point, aesthetics, defaults, makeLayer, mark_circle, poly, toStrictMode,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  poly = this.poly || {};

  aesthetics = ['x', 'y', 'color', 'size', 'opacity', 'shape', 'id'];

  defaults = {
    'x': {
      v: null,
      f: 'null'
    },
    'y': {
      v: null,
      f: 'null'
    },
    'color': 'steelblue',
    'size': 1,
    'opacity': 0.7,
    'shape': 1
  };

  toStrictMode = function(spec) {
    _.each(aesthetics, function(aes) {
      if (spec[aes] && _.isString(spec[aes])) {
        return spec[aes] = {
          "var": spec[aes]
        };
      }
    });
    return spec;
  };

  Layer = (function() {

    function Layer(layerSpec, statData) {
      var aes, _i, _len;
      this.spec = toStrictMode(layerSpec);
      this.mapping = {};
      this.consts = {};
      for (_i = 0, _len = aesthetics.length; _i < _len; _i++) {
        aes = aesthetics[_i];
        if (this.spec[aes]) {
          if (this.spec[aes]["var"]) this.mapping[aes] = this.spec[aes]["var"];
          if (this.spec[aes]["const"]) this.consts[aes] = this.spec[aes]["const"];
        }
      }
      this.defaults = defaults;
      this.precalc = statData;
      this.postcalc = null;
      this.geoms = null;
    }

    Layer.prototype.calculate = function() {
      this.layerDataCalc();
      return this.geomCalc();
    };

    Layer.prototype.layerDataCalc = function() {
      return this.postcalc = this.precalc;
    };

    Layer.prototype.geomCalc = function() {
      return this.geoms = {};
    };

    Layer.prototype.getValue = function(item, aes) {
      if (this.mapping[aes]) return item[this.mapping[aes]];
      if (this.consts[aes]) return this.consts[aes];
      return this.defaults[aes];
    };

    return Layer;

  })();

  Point = (function(_super) {

    __extends(Point, _super);

    function Point() {
      Point.__super__.constructor.apply(this, arguments);
    }

    Point.prototype.geomCalc = function() {
      var getGeom,
        _this = this;
      getGeom = mark_circle(this);
      return this.geoms = _.map(this.postcalc, function(item) {
        return {
          geom: getGeom(item),
          evtData: _this.getEvtData(item)
        };
      });
    };

    Point.prototype.getEvtData = function(item) {
      var evtData;
      evtData = {};
      _.each(item, function(v, k) {
        return evtData[k] = {
          "in": [v]
        };
      });
      return evtData;
    };

    return Point;

  })(Layer);

  mark_circle = function(layer) {
    return function(item) {
      return {
        type: 'point',
        x: layer.getValue(item, 'x'),
        y: layer.getValue(item, 'y'),
        color: layer.getValue(item, 'color'),
        color: layer.getValue(item, 'color')
      };
    };
  };

  makeLayer = function(layerSpec, statData) {
    switch (layerSpec.type) {
      case 'point':
        return new Point(layerSpec, statData);
    }
  };

  poly.layer = {
    toStrictMode: toStrictMode,
    makeLayer: makeLayer
  };

  this.poly = poly;

}).call(this);
