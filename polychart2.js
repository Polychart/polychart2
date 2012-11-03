(function() {
  var poly;

  poly = this.poly || {};

  poly.groupBy = function(data, group) {
    return _.groupBy(data, function(item) {
      var concat;
      concat = function(memo, g) {
        return "" + memo + g + ":" + item[g] + ";";
      };
      return _.reduce(group, concat, "");
    });
  };

  this.poly = poly;

}).call(this);
(function() {
  var Data, backendProcess, calculateMeta, extractDataSpec, filterFactory, filters, frontendProcess, poly, processData, statisticFactory, statistics, transformFactory, transforms,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  poly = this.poly || {};

  Data = (function() {

    function Data(params) {
      this.url = params.url, this.json = params.json;
      this.frontEnd = !this.url;
    }

    return Data;

  })();

  transforms = {
    'bin': function(key, transSpec) {
      var binwidth, name;
      name = transSpec.name, binwidth = transSpec.binwidth;
      if (_.isNumber(binwidth)) {
        return function(item) {
          return item[name] = binwidth * Math.floor(item[key] / binwidth);
        };
      }
    },
    'lag': function(key, transSpec) {
      var i, lag, lastn, name;
      name = transSpec.name, lag = transSpec.lag;
      lastn = (function() {
        var _results;
        _results = [];
        for (i = 1; 1 <= lag ? i <= lag : i >= lag; 1 <= lag ? i++ : i--) {
          _results.push(void 0);
        }
        return _results;
      })();
      return function(item) {
        lastn.push(item[key]);
        return item[name] = lastn.shift();
      };
    }
  };

  transformFactory = function(key, transSpec) {
    return transforms[transSpec.trans](key, transSpec);
  };

  filters = {
    'lt': function(x, value) {
      return x < value;
    },
    'le': function(x, value) {
      return x <= value;
    },
    'gt': function(x, value) {
      return x > value;
    },
    'ge': function(x, value) {
      return x >= value;
    },
    'in': function(x, value) {
      return __indexOf.call(value, x) >= 0;
    }
  };

  filterFactory = function(filterSpec) {
    var filterFuncs;
    filterFuncs = [];
    _.each(filterSpec, function(spec, key) {
      return _.each(spec, function(value, predicate) {
        var filter;
        filter = function(item) {
          return filters[predicate](item[key], value);
        };
        return filterFuncs.push(filter);
      });
    });
    return function(item) {
      var f, _i, _len;
      for (_i = 0, _len = filterFuncs.length; _i < _len; _i++) {
        f = filterFuncs[_i];
        if (!f(item)) return false;
      }
      return true;
    };
  };

  statistics = {
    sum: function(spec) {
      return function(values) {
        var memo, v, _i, _len;
        memo = 0;
        for (_i = 0, _len = values.length; _i < _len; _i++) {
          v = values[_i];
          memo += v;
        }
        return memo;
      };
    },
    count: function(spec) {
      return function(values) {
        return values.length;
      };
    },
    uniq: function(spec) {
      return function(values) {
        return (_.uniq(values)).length;
      };
    }
  };

  statisticFactory = function(statSpecs) {
    var group, statFuncs;
    group = statSpecs.group;
    statFuncs = {};
    _.each(statSpecs.stats, function(statSpec) {
      var key, name, stat, statFn;
      stat = statSpec.stat, key = statSpec.key, name = statSpec.name;
      statFn = statistics[stat](statSpec);
      return statFuncs[name] = function(data) {
        return statFn(_.pluck(data, key));
      };
    });
    return function(data) {
      var rep;
      rep = {};
      _.each(group, function(g) {
        return rep[g] = data[0][g];
      });
      _.each(statFuncs, function(stats, name) {
        return rep[name] = stats(data);
      });
      return rep;
    };
  };

  calculateMeta = function(key, metaSpec, data) {
    var asc, comparator, groupedData, limit, multiplier, sort, stat, statSpec, values;
    sort = metaSpec.sort, stat = metaSpec.stat, limit = metaSpec.limit, asc = metaSpec.asc;
    if (stat) {
      statSpec = {
        stats: [stat],
        group: [key]
      };
      groupedData = poly.groupBy(data, statSpec.group);
      data = _.map(groupedData, statisticFactory(statSpec));
    }
    multiplier = asc ? 1 : -1;
    comparator = function(a, b) {
      if (a[sort] === b[sort]) return 0;
      if (a[sort] >= b[sort]) return 1 * multiplier;
      return -1 * multiplier;
    };
    data.sort(comparator);
    if (limit) data = data.slice(0, (limit - 1) + 1 || 9e9);
    values = _.uniq(_.pluck(data, key));
    return {
      meta: {
        levels: values,
        sorted: true
      },
      filter: {
        "in": values
      }
    };
  };

  extractDataSpec = function(layerSpec) {
    return {};
  };

  frontendProcess = function(dataSpec, rawData, callback) {
    var additionalFilter, data, groupedData, metaData;
    data = _.clone(rawData);
    metaData = {};
    if (dataSpec.trans) {
      _.each(dataSpec.trans, function(transSpec, key) {
        var trans;
        trans = transformFactory(key, transSpec);
        return _.each(data, function(d) {
          return trans(d);
        });
      });
    }
    if (dataSpec.filter) data = _.filter(data, filterFactory(dataSpec.filter));
    if (dataSpec.meta) {
      additionalFilter = {};
      _.each(dataSpec.meta, function(metaSpec, key) {
        var filter, meta, _ref;
        _ref = calculateMeta(key, metaSpec, data), meta = _ref.meta, filter = _ref.filter;
        metaData[key] = meta;
        return additionalFilter[key] = filter;
      });
      data = _.filter(data, filterFactory(additionalFilter));
    }
    if (dataSpec.stats) {
      groupedData = poly.groupBy(data, dataSpec.stats.group);
      data = _.map(groupedData, statisticFactory(dataSpec.stats));
    }
    return callback(data, metaData);
  };

  backendProcess = function(dataSpec, rawData, callback) {
    return console.log('backendProcess');
  };

  processData = function(dataObj, layerSpec, callback) {
    var dataSpec;
    dataSpec = extractDataSpec(layerSpec);
    if (dataObj.frontEnd) {
      return frontendProcess(dataSpec, dataObj.json, callback);
    } else {
      return backendProcess(dataSpec, dataObj, callback);
    }
  };

  poly.Data = Data;

  poly.data = {
    frontendProcess: frontendProcess,
    processData: processData
  };

  this.poly = poly;

}).call(this);
(function() {
  var NotImplemented,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  NotImplemented = (function(_super) {

    __extends(NotImplemented, _super);

    function NotImplemented() {
      NotImplemented.__super__.constructor.apply(this, arguments);
    }

    return NotImplemented;

  })(Error);

}).call(this);
(function() {
  var Graph, poly;

  poly = this.poly || {};

  Graph = (function() {

    function Graph(spec) {
      var graphSpec;
      graphSpec = spec;
    }

    return Graph;

  })();

  poly.chart = function(spec) {
    var layers;
    layers = [];
    spec.layers = spec.layers || [];
    _.each(spec.layers, function(layerSpec) {
      return poly.data.processData(layerSpec.data, layerSpec, function(statData, meta) {
        var layerObj;
        layerObj = poly.layer.makeLayer(layerSpec, statData);
        layerObj.calculate();
        return layers.push(layerObj);
      });
    });
    return layers;
    /*
      # domain calculation and guide merging
      _.each layers (layerObj) ->
        makeGuides layerObj
      mergeGuides
    */
  };

  this.poly = poly;

}).call(this);
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
(function() {
  var poly;

  poly = this.poly || {};

  poly.groupBy = function(data, group) {
    return _.groupBy(data, function(item) {
      var concat;
      concat = function(memo, g) {
        return "" + memo + g + ":" + item[g] + ";";
      };
      return _.reduce(group, concat, "");
    });
  };

  this.poly = poly;

}).call(this);
