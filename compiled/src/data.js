(function() {
  var Data, backendProcess, constraintFunc, extractDataSpec, filterFactory, frontendProcess, groupByFunc, processData, singleStatsFunc, stat_count, stat_sum, stat_uniq, statisticFactory, trans_bin, trans_lag, transformFactory,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  Data = (function() {

    function Data(params) {
      this.url = params.url, this.json = params.json;
      this.frontEnd = !!this.url;
    }

    return Data;

  })();

  trans_bin = function(key, transSpec) {
    var binwidth, name;
    name = transSpec.name;
    binwidth = transSpec.binwidth;
    if (_.isNumber(binwidth)) {
      return function(item) {
        return item[name] = binwidth * Math.floor(item[key] / binwidth);
      };
    }
  };

  trans_lag = function(key, transSpec) {
    var i, lag, lastn, name;
    name = transSpec.name;
    lag = transSpec.lag;
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
  };

  transformFactory = function(key, transSpec) {
    switch (transSpec.trans) {
      case "bin":
        return trans_bin(key, transSpec);
      case "lag":
        return trans_lag(key, transSpec);
    }
  };

  filterFactory = function(filterSpec) {
    var filterFuncs;
    filterFuncs = [];
    _.each(filterSpec, function(spec, key) {
      return _.each(spec, function(value, predicate) {
        return filterFuncs.push(constraintFunc(predicate, value, key));
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

  constraintFunc = function(predicate, value, key) {
    switch (predicate) {
      case 'lt':
        return function(x) {
          return x[key] < value;
        };
      case 'le':
        return function(x) {
          return x[key] <= value;
        };
      case 'gt':
        return function(x) {
          return x[key] > value;
        };
      case 'ge':
        return function(x) {
          return x[key] >= value;
        };
      case 'in':
        return function(x) {
          var _ref;
          return _ref = x[key], __indexOf.call(value, _ref) >= 0;
        };
    }
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

  statisticFactory = function(statSpecs) {
    var group, statistics;
    group = statSpecs.group;
    statistics = [];
    _.each(statSpecs.stats, function(statSpec, key) {
      return statistics.push(singleStatsFunc(key, statSpec, group));
    });
    return function(data) {
      var rep;
      rep = {};
      _.each(group, function(g) {
        return rep[g] = data[0][g];
      });
      _.each(statistics, function(stats) {
        return stats(data, rep);
      });
      return rep;
    };
  };

  singleStatsFunc = function(key, statSpec, group) {
    var name, stat;
    name = statSpec.name;
    stat = (function() {
      switch (statSpec.stat) {
        case 'sum':
          return stat_sum(key, statSpec, group);
        case 'count':
          return stat_count(key, statSpec, group);
        case 'uniq':
          return stat_uniq(key, statSpec, group);
      }
    })();
    return function(data, rep) {
      return rep[name] = stat(_.pluck(data, key));
    };
  };

  stat_sum = function(key, spec, group) {
    return function(values) {
      return _.sum(values);
    };
  };

  stat_count = function(key, spec, group) {
    return function(values) {
      return values.length;
    };
  };

  stat_uniq = function(key, spec, group) {
    return function(values) {
      return (_.uniq(values)).length;
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
