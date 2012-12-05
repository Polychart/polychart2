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
    'size': 2,
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
    var aes, _i, _len;
    for (_i = 0, _len = aesthetics.length; _i < _len; _i++) {
      aes = aesthetics[_i];
      if (spec[aes] && _.isString(spec[aes])) {
        spec[aes] = {
          "var": spec[aes]
        };
      }
    }
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

    Layer.prototype.defaults = _.extend(defaults, {
      'size': 7
    });

    function Layer(layerSpec, strict) {
      this._makeMappings = __bind(this._makeMappings, this);
      this.render = __bind(this.render, this);
      this.reset = __bind(this.reset, this);      this.initialSpec = poly.layer.toStrictMode(layerSpec);
      this.prevSpec = null;
      this.dataprocess = new poly.DataProcess(this.initialSpec, strict);
      this.pts = {};
    }

    Layer.prototype.reset = function() {
      return this.make(this.initialSpec);
    };

    Layer.prototype.make = function(layerSpec, callback) {
      var spec,
        _this = this;
      spec = poly.layer.toStrictMode(layerSpec);
      this._makeMappings(spec);
      this.dataprocess.make(spec, function(statData, metaData) {
        _this.statData = statData;
        _this.meta = metaData;
        _this._calcGeoms();
        return callback();
      });
      return this.prevSpec = spec;
    };

    Layer.prototype._calcGeoms = function() {
      return this.geoms = {};
    };

    Layer.prototype.render = function(render) {
      var added, deleted, id, kept, newpts, _i, _j, _k, _len, _len2, _len3, _ref;
      newpts = {};
      _ref = poly.compare(_.keys(this.pts), _.keys(this.geoms)), deleted = _ref.deleted, kept = _ref.kept, added = _ref.added;
      for (_i = 0, _len = deleted.length; _i < _len; _i++) {
        id = deleted[_i];
        this._delete(render, this.pts[id]);
      }
      for (_j = 0, _len2 = added.length; _j < _len2; _j++) {
        id = added[_j];
        newpts[id] = this._add(render, this.geoms[id]);
      }
      for (_k = 0, _len3 = kept.length; _k < _len3; _k++) {
        id = kept[_k];
        newpts[id] = this._modify(render, this.pts[id], this.geoms[id]);
      }
      return this.pts = newpts;
    };

    Layer.prototype._delete = function(render, points) {
      var id2, pt, _results;
      _results = [];
      for (id2 in points) {
        pt = points[id2];
        _results.push(render.remove(pt));
      }
      return _results;
    };

    Layer.prototype._modify = function(render, points, geom) {
      var id2, mark, objs, _ref;
      objs = {};
      _ref = geom.marks;
      for (id2 in _ref) {
        mark = _ref[id2];
        objs[id2] = render.animate(points[id2], mark, geom.evtData);
      }
      return objs;
    };

    Layer.prototype._add = function(render, geom) {
      var id2, mark, objs, _ref;
      objs = {};
      _ref = geom.marks;
      for (id2 in _ref) {
        mark = _ref[id2];
        objs[id2] = render.add(mark, geom.evtData);
      }
      return objs;
    };

    Layer.prototype._makeMappings = function(spec) {
      var aes, _i, _len, _results;
      this.mapping = {};
      this.consts = {};
      _results = [];
      for (_i = 0, _len = aesthetics.length; _i < _len; _i++) {
        aes = aesthetics[_i];
        if (spec[aes]) {
          if (spec[aes]["var"]) this.mapping[aes] = spec[aes]["var"];
          if (spec[aes]["const"]) {
            _results.push(this.consts[aes] = spec[aes]["const"]);
          } else {
            _results.push(void 0);
          }
        } else {
          _results.push(void 0);
        }
      }
      return _results;
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
      var evtData, idfn, item, k, v, _i, _len, _ref, _results;
      idfn = this._getIdFunc();
      this.geoms = {};
      _ref = this.statData;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        evtData = {};
        for (k in item) {
          v = item[k];
          evtData[k] = {
            "in": [v]
          };
        }
        _results.push(this.geoms[idfn(item)] = {
          marks: {
            0: {
              type: 'circle',
              x: this._getValue(item, 'x'),
              y: this._getValue(item, 'y'),
              color: this._getValue(item, 'color'),
              size: this._getValue(item, 'size')
            }
          },
          evtData: evtData
        });
      }
      return _results;
    };

    return Point;

  })(Layer);

  Line = (function(_super) {

    __extends(Line, _super);

    function Line() {
      Line.__super__.constructor.apply(this, arguments);
    }

    Line.prototype._calcGeoms = function() {
      var data, datas, evtData, group, idfn, item, k, key, sample, _i, _len, _results;
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
      _results = [];
      for (k in datas) {
        data = datas[k];
        sample = data[0];
        evtData = {};
        for (_i = 0, _len = group.length; _i < _len; _i++) {
          key = group[_i];
          evtData[key] = {
            "in": [sample[key]]
          };
        }
        _results.push(this.geoms[idfn(sample)] = {
          marks: {
            0: {
              type: 'line',
              x: (function() {
                var _j, _len2, _results2;
                _results2 = [];
                for (_j = 0, _len2 = data.length; _j < _len2; _j++) {
                  item = data[_j];
                  _results2.push(this._getValue(item, 'x'));
                }
                return _results2;
              }).call(this),
              y: (function() {
                var _j, _len2, _results2;
                _results2 = [];
                for (_j = 0, _len2 = data.length; _j < _len2; _j++) {
                  item = data[_j];
                  _results2.push(this._getValue(item, 'y'));
                }
                return _results2;
              }).call(this),
              color: this._getValue(sample, 'color')
            }
          },
          evtData: evtData
        });
      }
      return _results;
    };

    return Line;

  })(Layer);

  Bar = (function(_super) {

    __extends(Bar, _super);

    function Bar() {
      Bar.__super__.constructor.apply(this, arguments);
    }

    Bar.prototype._calcGeoms = function() {
      var data, datas, evtData, group, idfn, item, k, key, tmp, v, yval, _i, _j, _len, _len2, _ref, _results,
        _this = this;
      group = this.mapping.x != null ? [this.mapping.x] : [];
      datas = poly.groupBy(this.statData, group);
      for (key in datas) {
        data = datas[key];
        tmp = 0;
        yval = this.mapping.y != null ? (function(item) {
          return item[_this.mapping.y];
        }) : function(item) {
          return 0;
        };
        for (_i = 0, _len = data.length; _i < _len; _i++) {
          item = data[_i];
          item.$lower = tmp;
          tmp += yval(item);
          item.$upper = tmp;
        }
      }
      idfn = this._getIdFunc();
      this.geoms = {};
      _ref = this.statData;
      _results = [];
      for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
        item = _ref[_j];
        evtData = {};
        for (k in item) {
          v = item[k];
          if (k !== 'y') {
            evtData[k] = {
              "in": [v]
            };
          }
        }
        _results.push(this.geoms[idfn(item)] = {
          marks: {
            0: {
              type: 'rect',
              x: [sf.lower(this._getValue(item, 'x')), sf.upper(this._getValue(item, 'x'))],
              y: [item.$lower, item.$upper],
              color: this._getValue(item, 'color')
            }
          }
        });
      }
      return _results;
    };

    return Bar;

  })(Layer);

  /*
  # EXPORT
  */

  this.poly = poly;

}).call(this);
