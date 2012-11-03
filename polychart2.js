(function() {
  var Data, backendProcess, extractDataSpec, filterFactory, filters, frontendProcess, groupByFunc, processData, statisticFactory, statistics, transformFactory, transforms,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  Data = (function() {

    function Data(params) {
      this.url = params.url, this.json = params.json;
      this.frontEnd = !!this.url;
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

  groupByFunc = function(group) {
    return function(item) {
      var concat;
      concat = function(memo, g) {
        return "" + memo + g + ":" + item[g] + ";";
      };
      return _.reduceRight(group, concat, "");
    };
  };

  statistics = {
    sum: function(spec) {
      return function(values) {
        return _.sum(values);
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

  extractDataSpec = function(layerSpec) {
    return dataSpec;
  };

  frontendProcess = function(dataSpec, rawData, callback) {
    var data, groupedData;
    data = _.clone(rawData);
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
    if (dataSpec.stats) {
      groupedData = _.groupBy(data, groupByFunc(dataSpec.stats.group));
      data = _.map(groupedData, statisticFactory(dataSpec.stats));
    }
    return callback(data);
  };

  backendProcess = function(dataSpec, rawData, callback) {
    return callback(statData);
  };

  processData = function(dataObj, layerSpec, callback) {
    var dataSpec;
    dataSpec = extractDataSpec(layerSpec);
    if (dataObj.frontEnd) {
      return frontendProcess(dataSpec, layerSpec, callback);
    } else {
      return backendProcess(dataSpec, layerSpec, callback);
    }
  };

  this.frontendProcess = frontendProcess;

  this.processData = processData;

  this.Data = Data;

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
  var Graph, Layer;

  Graph = (function() {

    function Graph(input) {
      var graphSpec;
      graphSpec = spec;
    }

    return Graph;

  })();

  Layer = (function() {

    function Layer(layerSpec, statData) {
      this.spec = layerSpec;
      this.precalc = statData;
    }

    Layer.prototype.calculate = function(statData) {
      return layerData;
    };

    return Layer;

  })();

}).call(this);
