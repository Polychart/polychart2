(function() {
  var Bin, Box, Count, Data, Filter, Group, Lag, Lm, Mean, Statistic, Sum, Transform, Uniq, backendProcess, extractDataSpec, filterFactory, frontendProcess, processData, transformFactory,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  Data = (function() {

    function Data(params) {
      this.url = params.url, this.json = params.json;
      this.frontEnd = !!this.url;
    }

    return Data;

  })();

  Transform = (function() {

    function Transform(key, transSpec) {
      this.getMutateFunction = __bind(this.getMutateFunction, this);      this.key = key;
      this.name = transSpec.name;
      this.transSpec = transSpec;
      this.mutate = this.getMutateFunction();
    }

    Transform.prototype.getMutateFunction = function() {};

    return Transform;

  })();

  Bin = (function(_super) {

    __extends(Bin, _super);

    function Bin() {
      this.getMutateFunction = __bind(this.getMutateFunction, this);
      Bin.__super__.constructor.apply(this, arguments);
    }

    Bin.prototype.getMutateFunction = function() {
      this.binwidth = this.transSpec.binwidth;
      if (_.isNumber(this.binwidth)) {
        return function(item) {
          return item[this.name] = this.binwidth * Math.floor(item[this.key] / this.binwidth);
        };
      }
    };

    return Bin;

  })(Transform);

  Lag = (function(_super) {

    __extends(Lag, _super);

    function Lag() {
      this.getMutateFunction = __bind(this.getMutateFunction, this);
      Lag.__super__.constructor.apply(this, arguments);
    }

    Lag.prototype.getMutateFunction = function() {
      var i;
      this.lag = this.transSpec.lag;
      this.lastn = (function() {
        var _ref, _results;
        _results = [];
        for (i = 1, _ref = this.lag; 1 <= _ref ? i <= _ref : i >= _ref; 1 <= _ref ? i++ : i--) {
          _results.push(void 0);
        }
        return _results;
      }).call(this);
      return function(item) {
        this.lastn.push(item[this.key]);
        return item[this.name] = this.lastn.shift();
      };
    };

    return Lag;

  })(Transform);

  transformFactory = function(key, transSpec) {
    switch (transSpec.trans) {
      case "bin":
        return new Bin(key, transSpec);
      case "lag":
        return new Lag(key, transSpec);
    }
  };

  filterFactory = function(filterSpec) {
    return idontknow;
  };

  Filter = (function() {

    function Filter(filterSpec) {
      this.filterSpec = filterSpec;
    }

    Filter.prototype.mutate = function(data) {
      return data;
    };

    return Filter;

  })();

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
    _.each(dataSpec.trans, function(transSpec, key) {
      var trans;
      trans = transformFactory(key, transSpec);
      return _.each(rawData, function(d) {
        return trans.mutate(d);
      });
    });
    /*
      # filter
      filter = filterFactory(dataSpec.filter)
      rawData = filter(rawData)
      # groupby
      groupeData = groupby(filterSpec, rawData)
    */
    return callback(rawData);
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
