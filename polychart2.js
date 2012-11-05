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
  var poly;

  poly = this.poly || {};

  poly["const"] = {
    aes: ['x', 'y', 'color', 'size', 'opacity', 'shape', 'id'],
    scaleFns: {
      novalue: function() {
        return {
          v: null,
          f: 'novalue',
          t: 'scalefn'
        };
      },
      upper: function(v) {
        return {
          v: v,
          f: 'upper',
          t: 'scalefn'
        };
      },
      lower: function(v) {
        return {
          v: v,
          f: 'lower',
          t: 'scalefn'
        };
      },
      middle: function(v) {
        return {
          v: v,
          f: 'middle',
          t: 'scalefn'
        };
      },
      jitter: function(v) {
        return {
          v: v,
          f: 'jitter',
          t: 'scalefn'
        };
      },
      identity: function(v) {
        return {
          v: v,
          f: 'identity',
          t: 'scalefn'
        };
      }
    }
  };

  this.poly = poly;

}).call(this);
(function() {
  var poly;

  poly = this.poly || {};

  poly["const"] = {
    aes: ['x', 'y', 'color', 'size', 'opacity', 'shape', 'id'],
    scaleFns: {
      novalue: function() {
        return {
          v: null,
          f: 'novalue',
          t: 'scalefn'
        };
      },
      upper: function(v) {
        return {
          v: v,
          f: 'upper',
          t: 'scalefn'
        };
      },
      lower: function(v) {
        return {
          v: v,
          f: 'lower',
          t: 'scalefn'
        };
      },
      middle: function(v) {
        return {
          v: v,
          f: 'middle',
          t: 'scalefn'
        };
      },
      jitter: function(v) {
        return {
          v: v,
          f: 'jitter',
          t: 'scalefn'
        };
      },
      identity: function(v) {
        return {
          v: v,
          f: 'identity',
          t: 'scalefn'
        };
      }
    }
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
      var binFn, binwidth, name;
      name = transSpec.name, binwidth = transSpec.binwidth;
      if (_.isNumber(binwidth)) {
        binFn = function(item) {
          return item[name] = binwidth * Math.floor(item[key] / binwidth);
        };
        return {
          trans: binFn,
          meta: {
            bw: binwidth,
            binned: true
          }
        };
      }
    },
    'lag': function(key, transSpec) {
      var i, lag, lagFn, lastn, name;
      name = transSpec.name, lag = transSpec.lag;
      lastn = (function() {
        var _results;
        _results = [];
        for (i = 1; 1 <= lag ? i <= lag : i >= lag; 1 <= lag ? i++ : i--) {
          _results.push(void 0);
        }
        return _results;
      })();
      lagFn = function(item) {
        lastn.push(item[key]);
        return item[name] = lastn.shift();
      };
      return {
        trans: lagFn,
        meta: void 0
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
        return _.reduce(values, (function(v, m) {
          return v + m;
        }), 0);
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
    var addMeta, additionalFilter, data, groupedData, metaData;
    data = _.clone(rawData);
    metaData = {};
    addMeta = function(key, meta) {
      if (metaData[key] == null) metaData[key] = {};
      return _.extend(metaData[key], meta);
    };
    if (dataSpec.trans) {
      _.each(dataSpec.trans, function(transSpec, key) {
        var meta, trans, _ref;
        _ref = transformFactory(key, transSpec), trans = _ref.trans, meta = _ref.meta;
        _.each(data, function(d) {
          return trans(d);
        });
        return addMeta(transSpec.name, meta);
      });
    }
    if (dataSpec.filter) data = _.filter(data, filterFactory(dataSpec.filter));
    if (dataSpec.meta) {
      additionalFilter = {};
      _.each(dataSpec.meta, function(metaSpec, key) {
        var filter, meta, _ref;
        _ref = calculateMeta(key, metaSpec, data), meta = _ref.meta, filter = _ref.filter;
        additionalFilter[key] = filter;
        return addMeta(key, meta);
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

  processData = function(dataObj, layerSpec, strictmode, callback) {
    var dataSpec;
    dataSpec = extractDataSpec(layerSpec);
    if (dataObj.frontEnd) {
      if (strictmode) {
        return callback(dataObj.json, layerSpec);
      } else {
        return frontendProcess(dataSpec, dataObj.json, callback);
      }
    } else {
      if (strictmode) {
        return console.log('wtf, cant use strict mode here');
      } else {
        return backendProcess(dataSpec, dataObj, callback);
      }
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
    var guides, layers;
    if (spec.strict == null) spec.strict = false;
    layers = [];
    if (spec.layers == null) spec.layers = [];
    _.each(spec.layers, function(layerSpec) {
      var callback;
      callback = function(statData, metaData) {
        var layerObj;
        layerObj = poly.layer.makeLayer(layerSpec, statData, metaData);
        layerObj.calculate();
        return layers.push(layerObj);
      };
      return poly.data.processData(layerSpec.data, layerSpec, spec.strict, callback);
    });
    guides = {};
    if (spec.guides) {
      if (spec.guides == null) spec.guides = {};
      guides = poly.guide.makeGuides(layers, spec.guides, spec.strict);
    }
    return {
      layers: layers,
      guides: guides
    };
  };

  this.poly = poly;

}).call(this);
(function() {
  var CategoricalDomain, DateDomain, NumericDomain, aesthetics, makeDomain, makeDomainSet, makeGuides, mergeDomainSets, mergeDomains, poly;

  poly = this.poly || {};

  aesthetics = poly["const"].aes;

  makeGuides = function(layers, guideSpec, strictmode) {
    var domainSets;
    domainSets = [];
    _.each(layers, function(layerObj) {
      return domainSets.push(makeDomainSet(layerObj, guideSpec, strictmode));
    });
    return mergeDomainSets(domainSets);
  };

  makeDomainSet = function(layerObj, guideSpec, strictmode) {
    var domain;
    domain = {};
    _.each(_.keys(layerObj.mapping), function(aes) {
      if (strictmode) return domain[aes] = makeDomain(guideSpec[aes]);
    });
    return domain;
  };

  mergeDomainSets = function(domainSets) {
    var merged;
    merged = {};
    _.each(aesthetics, function(aes) {
      var domains;
      domains = _.without(_.pluck(domainSets, aes), void 0);
      if (domains.length > 0) return merged[aes] = mergeDomains(domains);
    });
    return merged;
  };

  NumericDomain = (function() {

    function NumericDomain(params) {
      this.type = params.type, this.min = params.min, this.max = params.max, this.bw = params.bw;
    }

    return NumericDomain;

  })();

  DateDomain = (function() {

    function DateDomain(params) {
      this.type = params.type, this.min = params.min, this.max = params.max, this.bw = params.bw;
    }

    return DateDomain;

  })();

  CategoricalDomain = (function() {

    function CategoricalDomain(params) {
      this.type = params.type, this.levels = params.levels, this.sorted = params.sorted;
    }

    return CategoricalDomain;

  })();

  makeDomain = function(params) {
    switch (params.type) {
      case 'num':
        return new NumericDomain(params);
      case 'date':
        return new DateDomain(params);
      case 'cat':
        return new CategoricalDomain(params);
    }
  };

  mergeDomains = function(domains) {
    var bw, levels, max, min, sortedLevels, types, unsortedLevels;
    types = _.uniq(_.map(domains, function(d) {
      return d.type;
    }));
    if (types.length > 1) console.log('wtf');
    if (types[0] === 'num' || types[0] === 'date') {
      bw = _.uniq(_.map(domains, function(d) {
        return d.bw;
      }));
      if (bw.length > 1) console.log('wtf');
      bw = bw[0] != null ? bw[0] : void 0;
      min = _.min(_.map(domains, function(d) {
        return d.min;
      }));
      max = _.max(_.map(domains, function(d) {
        return d.max;
      }));
      return makeDomain({
        type: types[0],
        min: min,
        max: max,
        bw: bw
      });
    }
    if (types[0] === 'cat') {
      sortedLevels = _.chain(domains).filter(function(d) {
        return d.sorted;
      }).map(function(d) {
        return d.levels;
      }).value();
      unsortedLevels = _.chain(domains).filter(function(d) {
        return !d.sorted;
      }).map(function(d) {
        return d.levels;
      }).value();
      debugger;
      if (sortedLevels.length > 0 && _.intersection.apply(this, sortedLevels)) {
        console.log('wtf');
      }
      sortedLevels = [_.flatten(sortedLevels, true)];
      levels = _.union.apply(this, sortedLevels.concat(unsortedLevels));
      return makeDomain({
        type: 'cat',
        levels: levels,
        sorted: true
      });
    }
  };

  poly.guide = {
    makeGuides: makeGuides
  };

  this.poly = poly;

}).call(this);
(function() {
  var Bar, Layer, Line, Point, aesthetics, defaults, makeLayer, poly, sf, toStrictMode,
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

    function Layer(layerSpec, statData, metaData) {
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
      this.meta = metaData;
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
      if (this.consts[aes]) return sf.identity(this.consts[aes]);
      return sf.identity(this.defaults[aes]);
    };

    return Layer;

  })();

  Point = (function(_super) {

    __extends(Point, _super);

    function Point() {
      Point.__super__.constructor.apply(this, arguments);
    }

    Point.prototype.geomCalc = function() {
      var _this = this;
      return this.geoms = _.map(this.postcalc, function(item) {
        var evtData;
        evtData = {};
        _.each(item, function(v, k) {
          return evtData[k] = {
            "in": [v]
          };
        });
        return {
          geoms: [
            {
              type: 'point',
              x: _this.getValue(item, 'x'),
              y: _this.getValue(item, 'y'),
              color: _this.getValue(item, 'color')
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

    Line.prototype.layerDataCalc = function() {
      this.ys = this.mapping['y'] ? _.uniq(_.pluck(this.precalc, this.mapping['y'])) : [];
      return this.postcalc = _.clone(this.precalc);
    };

    Line.prototype.geomCalc = function() {
      var datas, group, k,
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
      datas = poly.groupBy(this.postcalc, group);
      return this.geoms = _.map(datas, function(data) {
        var evtData, item;
        evtData = {};
        _.each(group, function(key) {
          return evtData[key] = {
            "in": [data[0][key]]
          };
        });
        return {
          geoms: [
            {
              type: 'line',
              x: (function() {
                var _i, _len, _results;
                _results = [];
                for (_i = 0, _len = data.length; _i < _len; _i++) {
                  item = data[_i];
                  _results.push(this.getValue(item, 'x'));
                }
                return _results;
              }).call(_this),
              y: (function() {
                var _i, _len, _results;
                _results = [];
                for (_i = 0, _len = data.length; _i < _len; _i++) {
                  item = data[_i];
                  _results.push(this.getValue(item, 'y'));
                }
                return _results;
              }).call(_this),
              color: _this.getValue(data[0], 'color')
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

    Bar.prototype.layerDataCalc = function() {
      var datas, group,
        _this = this;
      this.postcalc = _.clone(this.precalc);
      group = this.mapping.x != null ? [this.mapping.x] : [];
      datas = poly.groupBy(this.postcalc, group);
      return _.each(datas, function(data) {
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
    };

    Bar.prototype.geomCalc = function() {
      var _this = this;
      return this.geoms = _.map(this.postcalc, function(item) {
        var evtData;
        evtData = {};
        _.each(item, function(v, k) {
          if (k !== 'y') {
            return evtData[k] = {
              "in": [v]
            };
          }
        });
        return {
          geoms: [
            {
              type: 'rect',
              x1: sf.lower(_this.getValue(item, 'x')),
              x2: sf.upper(_this.getValue(item, 'x')),
              y1: item.$lower,
              y2: item.$upper,
              fill: _this.getValue(item, 'color')
            }
          ]
        };
      });
    };

    return Bar;

  })(Layer);

  makeLayer = function(layerSpec, statData) {
    switch (layerSpec.type) {
      case 'point':
        return new Point(layerSpec, statData);
      case 'line':
        return new Line(layerSpec, statData);
      case 'bar':
        return new Bar(layerSpec, statData);
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
