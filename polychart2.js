(function() {
  var Box, Count, Data, Group, Lm, Mean, Statistic, Sum, Uniq, backendProcess, constraintFunc, extractDataSpec, filterFactory, frontendProcess, processData, trans_bin, trans_lag, transformFactory,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

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

  Group = (function() {

    function Group(groupSpec) {
      this.groupSepc = groupSpec;
    }

    Group.prototype.compute = function(data) {
      return data;
    };

    return Group;

  })();

  Statistic = (function() {

    function Statistic(statSpec) {
      this.statSpec = statSpec;
    }

    Statistic.prototype.compute = function(data) {
      return item;
    };

    return Statistic;

  })();

  Sum = (function(_super) {

    __extends(Sum, _super);

    function Sum() {
      Sum.__super__.constructor.apply(this, arguments);
    }

    Sum.prototype.compute = function(data) {
      return _.sum(data);
    };

    return Sum;

  })(Statistic);

  Mean = (function(_super) {

    __extends(Mean, _super);

    function Mean() {
      Mean.__super__.constructor.apply(this, arguments);
    }

    Mean.prototype.compute = function(data) {
      return data;
    };

    return Mean;

  })(Statistic);

  Uniq = (function(_super) {

    __extends(Uniq, _super);

    function Uniq() {
      Uniq.__super__.constructor.apply(this, arguments);
    }

    Uniq.prototype.compute = function(data) {
      return data;
    };

    return Uniq;

  })(Statistic);

  Count = (function(_super) {

    __extends(Count, _super);

    function Count() {
      Count.__super__.constructor.apply(this, arguments);
    }

    Count.prototype.compute = function(data) {
      return data;
    };

    return Count;

  })(Statistic);

  Lm = (function(_super) {

    __extends(Lm, _super);

    function Lm() {
      Lm.__super__.constructor.apply(this, arguments);
    }

    Lm.prototype.compute = function(data) {
      return data;
    };

    return Lm;

  })(Statistic);

  Box = (function(_super) {

    __extends(Box, _super);

    function Box() {
      Box.__super__.constructor.apply(this, arguments);
    }

    Box.prototype.compute = function(data) {
      return data;
    };

    return Box;

  })(Statistic);

  extractDataSpec = function(layerSpec) {
    return dataSpec;
  };

  frontendProcess = function(dataSpec, rawData, callback) {
    var data;
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
