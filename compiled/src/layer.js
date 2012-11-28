(function() {
  var Bar, Layer, Line, Point, aesthetics, defaults, poly, sf,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  poly = this.poly || {};

  aesthetics = poly["const"].aes;

  sf = poly["const"].scaleFns;

  defaults = {
    'x': sf.novalue(),
    'y': sf.novalue(),
    'color': 'steelblue',
    'size': 1,
    'opacity': 0.7,
    'shape': 1
  };

  poly.layer = {};

  /*
  Turns a 'non-strict' layer spec to a strict one. Specifically, the function
  (1) wraps aes mapping defined by a string in an object: "col" -> {var: "col"}
  (2) puts all the level/min/max filtering into the "filter" group
  See the layer spec definition for more information.
  */

  poly.layer.toStrictMode = function(spec) {
    _.each(aesthetics, function(aes) {
      if (spec[aes] && _.isString(spec[aes])) {
        return spec[aes] = {
          "var": spec[aes]
        };
      }
    });
    return spec;
  };

  /*
  Public interface to making different layer types.
  */

  poly.layer.make = function(layerSpec, strictmode) {
    switch (layerSpec.type) {
      case 'point':
        return new Point(layerSpec, strictmode);
      case 'line':
        return new Line(layerSpec, strictmode);
      case 'bar':
        return new Bar(layerSpec, strictmode);
    }
  };

  /*
  Base class for all layers
  */

  Layer = (function() {

    function Layer(layerSpec, strict) {
      this.render = __bind(this.render, this);
      this.calculate = __bind(this.calculate, this);
      var aes, _i, _len;
      this.strict = strict;
      this.spec = poly.layer.toStrictMode(layerSpec);
      this.defaults = defaults;
      this.mapping = {};
      this.consts = {};
      for (_i = 0, _len = aesthetics.length; _i < _len; _i++) {
        aes = aesthetics[_i];
        if (this.spec[aes]) {
          if (this.spec[aes]["var"]) this.mapping[aes] = this.spec[aes]["var"];
          if (this.spec[aes]["const"]) this.consts[aes] = this.spec[aes]["const"];
        }
      }
    }

    Layer.prototype.calculate = function(callback) {
      var _this = this;
      this.dataprocess = new poly.DataProcess(this.spec);
      return this.dataprocess.process(function(statData, metaData) {
        _this.statData = statData;
        _this.meta = metaData;
        _this._calcGeoms();
        return callback();
      });
    };

    Layer.prototype.render = function(paper, render) {
      paper.setStart();
      _.each(this.geoms, function(geom) {
        return _.each(geom.marks, function(mark) {
          return render(mark, geom.evtData);
        });
      });
      return this.objects = paper.setFinish();
    };

    Layer.prototype._calcGeoms = function() {
      return this.geoms = {};
    };

    Layer.prototype._getValue = function(item, aes) {
      if (this.mapping[aes]) return item[this.mapping[aes]];
      if (this.consts[aes]) return sf.identity(this.consts[aes]);
      return sf.identity(this.defaults[aes]);
    };

    Layer.prototype._getIdFunc = function() {
      var _this = this;
      if (this.mapping['id'] != null) {
        return function(item) {
          return _this._getValue(item, 'id');
        };
      } else {
        return poly.counter();
      }
    };

    return Layer;

  })();

  Point = (function(_super) {

    __extends(Point, _super);

    function Point() {
      Point.__super__.constructor.apply(this, arguments);
    }

    Point.prototype._calcGeoms = function() {
      var idfn,
        _this = this;
      idfn = this._getIdFunc();
      this.geoms = {};
      return _.each(this.statData, function(item) {
        var evtData;
        evtData = {};
        _.each(item, function(v, k) {
          return evtData[k] = {
            "in": [v]
          };
        });
        return _this.geoms[idfn(item)] = {
          marks: [
            {
              type: 'point',
              x: _this._getValue(item, 'x'),
              y: _this._getValue(item, 'y'),
              color: _this._getValue(item, 'color')
            }
          ],
          evtData: evtData
        };
      });
    };

    return Point;

  })(Layer);

  Line = (function(_super) {

    __extends(Line, _super);

    function Line() {
      Line.__super__.constructor.apply(this, arguments);
    }

    Line.prototype._calcGeoms = function() {
      var datas, group, idfn, k,
        _this = this;
      group = (function() {
        var _i, _len, _ref, _results;
        _ref = _.without(_.keys(this.mapping), 'x', 'y');
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          k = _ref[_i];
          _results.push(this.mapping[k]);
        }
        return _results;
      }).call(this);
      datas = poly.groupBy(this.statData, group);
      idfn = this._getIdFunc();
      this.geoms = {};
      return _.each(datas, function(data) {
        var evtData, item, sample;
        sample = data[0];
        evtData = {};
        _.each(group, function(key) {
          return evtData[key] = {
            "in": [sample[key]]
          };
        });
        return _this.geoms[idfn(sample)] = {
          marks: [
            {
              type: 'line',
              x: (function() {
                var _i, _len, _results;
                _results = [];
                for (_i = 0, _len = data.length; _i < _len; _i++) {
                  item = data[_i];
                  _results.push(this._getValue(item, 'x'));
                }
                return _results;
              }).call(_this),
              y: (function() {
                var _i, _len, _results;
                _results = [];
                for (_i = 0, _len = data.length; _i < _len; _i++) {
                  item = data[_i];
                  _results.push(this._getValue(item, 'y'));
                }
                return _results;
              }).call(_this),
              color: _this._getValue(sample, 'color')
            }
          ],
          evtData: evtData
        };
      });
    };

    return Line;

  })(Layer);

  Bar = (function(_super) {

    __extends(Bar, _super);

    function Bar() {
      Bar.__super__.constructor.apply(this, arguments);
    }

    Bar.prototype._calcGeoms = function() {
      var datas, group, idfn,
        _this = this;
      group = this.mapping.x != null ? [this.mapping.x] : [];
      datas = poly.groupBy(this.statData, group);
      _.each(datas, function(data) {
        var tmp, yval;
        tmp = 0;
        yval = _this.mapping.y != null ? (function(item) {
          return item[_this.mapping.y];
        }) : function(item) {
          return 0;
        };
        return _.each(data, function(item) {
          item.$lower = tmp;
          tmp += yval(item);
          return item.$upper = tmp;
        });
      });
      idfn = this._getIdFunc();
      this.geoms = {};
      return _.each(this.statData, function(item) {
        var evtData;
        evtData = {};
        _.each(item, function(v, k) {
          if (k !== 'y') {
            return evtData[k] = {
              "in": [v]
            };
          }
        });
        return _this.geoms[idfn(item)] = {
          marks: [
            {
              type: 'rect',
              x1: sf.lower(_this._getValue(item, 'x')),
              x2: sf.upper(_this._getValue(item, 'x')),
              y1: item.$lower,
              y2: item.$upper,
              fill: _this._getValue(item, 'color')
            }
          ]
        };
      });
    };

    return Bar;

  })(Layer);

  /*
  # EXPORT
  */

  this.poly = poly;

}).call(this);
