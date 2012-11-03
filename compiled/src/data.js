(function() {
  var Data, backendProcess, calculateMeta, extractDataSpec, filterFactory, filters, frontendProcess, groupByFunc, processData, statisticFactory, statistics, transformFactory, transforms,
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
      return _.reduce(group, concat, "");
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
      groupedData = _.groupBy(data, groupByFunc(statSpec.group));
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
    return dataSpec;
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
