(function() {
  var Data, DataProcess, backendProcess, calculateMeta, calculateStats, extractDataSpec, filterFactory, filters, frontendProcess, poly, statistics, statsFactory, transformFactory, transforms,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  poly = this.poly || {};

  /*
  # GLOBALS
  */

  /*
  Generalized data object that either contains JSON format of a dataset,
  or knows how to retrieve data from some source.
  */

  Data = (function() {

    function Data(params) {
      this.url = params.url, this.json = params.json;
      this.frontEnd = !this.url;
    }

    return Data;

  })();

  poly.Data = Data;

  /*
  Wrapper around the data processing piece that keeps track of the kind of
  data processing to be done.
  */

  DataProcess = (function() {

    function DataProcess(layerSpec, strictmode) {
      this.dataObj = layerSpec.data;
      this.dataSpec = extractDataSpec(layerSpec);
      this.strictmode = strictmode;
      this.statData = null;
      this.metaData = {};
    }

    DataProcess.prototype.process = function(callback) {
      var wrappedCallback,
        _this = this;
      wrappedCallback = function(data, metaData) {
        _this.statData = data;
        _this.metaData = metaData;
        return callback(_this.statData, _this.metaData);
      };
      if (this.dataObj.frontEnd) {
        if (this.strictmode) {
          return wrappedCallback(this.dataObj.json, {});
        } else {
          return frontendProcess(this.dataSpec, this.dataObj.json, wrappedCallback);
        }
      } else {
        if (this.strictmode) {
          return console.log('wtf, cant use strict mode here');
        } else {
          return backendProcess(this.dataSpec, this.dataObj, wrappedCallback);
        }
      }
    };

    DataProcess.prototype.reprocess = function(newlayerSpec, callback) {
      var newDataSpec;
      newDataSpec = extractDataSpec(newlayerSpec);
      if (_.isEqual(this.dataSpec, newDataSpec)) {
        callback(this.statData, this.metaData);
      }
      this.dataSpec = newDataSpec;
      return this.process(callback);
    };

    return DataProcess;

  })();

  poly.DataProcess = DataProcess;

  /*
  Temporary
  */

  poly.data = {};

  poly.data.process = function(dataObj, layerSpec, strictmode, callback) {
    var d;
    d = new DataProcess(layerSpec, strictmode);
    d.process(callback);
    return d;
  };

  /*
  TRANSFORMS
  ----------
  Key:value pair of available transformations to a function that creates that
  transformation. Also, a metadata description of the transformation is returned
  when appropriate. (e.g for binning)
  */

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

  /*
  Helper function to figures out which transformation to create, then creates it
  */

  transformFactory = function(key, transSpec) {
    return transforms[transSpec.trans](key, transSpec);
  };

  /*
  FILTERS
  ----------
  Key:value pair of available filtering operations to filtering function. The
  filtering function returns true iff the data item satisfies the filtering 
  criteria.
  */

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

  /*
  Helper function to figures out which filter to create, then creates it
  */

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

  /*
  STATISTICS
  ----------
  Key:value pair of available statistics operations to a function that creates
  the appropriate statistical function given the spec. Each statistics function
  produces one atomic value for each group of data.
  */

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
    },
    min: function(spec) {
      return function(values) {
        return _.min(values);
      };
    },
    max: function(spec) {
      return function(values) {
        return _.max(values);
      };
    },
    median: function(spec) {
      return function(values) {
        debugger;
        var mid;
        mid = values.length / 2;
        if (mid % 1 !== 0) return values[Math.floor(mid)];
        return (values[mid - 1] + values[mid]) / 2;
      };
    }
  };

  /*
  Helper function to figures out which statistics to create, then creates it
  */

  statsFactory = function(statSpec) {
    return statistics[statSpec.stat](statSpec);
  };

  /*
  Calculate statistics
  */

  calculateStats = function(data, statSpecs) {
    var groupedData, statFuncs;
    statFuncs = {};
    _.each(statSpecs.stats, function(statSpec) {
      var key, name, statFn;
      key = statSpec.key, name = statSpec.name;
      statFn = statsFactory(statSpec);
      return statFuncs[name] = function(data) {
        return statFn(_.pluck(data, key));
      };
    });
    groupedData = poly.groupBy(data, statSpecs.group);
    return _.map(groupedData, function(data) {
      var rep;
      rep = {};
      _.each(statSpecs.group, function(g) {
        return rep[g] = data[0][g];
      });
      _.each(statFuncs, function(stats, name) {
        return rep[name] = stats(data);
      });
      return rep;
    });
  };

  /*
  META
  ----
  Calculations of meta properties including sorting and limiting based on the
  values of statistical calculations
  */

  calculateMeta = function(key, metaSpec, data) {
    var asc, comparator, limit, multiplier, sort, stat, statSpec, values;
    sort = metaSpec.sort, stat = metaSpec.stat, limit = metaSpec.limit, asc = metaSpec.asc;
    if (stat) {
      statSpec = {
        stats: [stat],
        group: [key]
      };
      data = calculateStats(data, statSpec);
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

  /*
  GENERAL PROCESSING
  ------------------
  Coordinating the actual work being done
  */

  /*
  Given a layer spec, extract the data calculations that needs to be done.
  */

  extractDataSpec = function(layerSpec) {
    return {};
  };

  /*
  Perform the necessary computation in the front end
  */

  frontendProcess = function(dataSpec, rawData, callback) {
    var addMeta, additionalFilter, data, metaData;
    data = _.clone(rawData);
    metaData = {};
    addMeta = function(key, meta) {
      var _ref;
      return _.extend((_ref = metaData[key]) != null ? _ref : {}, meta);
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
    if (dataSpec.stats) data = calculateStats(data, dataSpec.stats);
    return callback(data, metaData);
  };

  /*
  Perform the necessary computation in the backend
  */

  backendProcess = function(dataSpec, rawData, callback) {
    return console.log('backendProcess');
  };

  /*
  For debug purposes only
  */

  poly.data.frontendProcess = frontendProcess;

  /*
  # EXPORT
  */

  this.poly = poly;

}).call(this);
