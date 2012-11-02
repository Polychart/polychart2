(function() {
  var Foo;

  Foo = (function() {

    function Foo() {}

    return Foo;

  })();

}).call(this);
(function() {
  var Bin, Box, Count, Data, Filter, Graph, Group, Lag, Layer, Lm, Mean, NotImplemented, Statistic, Sum, Transform, Uniq, backendProcess, extractDataSpec, filterFactory, frontendProcess, transformFactory,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  NotImplemented = (function(_super) {

    __extends(NotImplemented, _super);

    function NotImplemented() {
      NotImplemented.__super__.constructor.apply(this, arguments);
    }

    return NotImplemented;

  })(Error);

  Graph = (function() {

    function Graph(input) {
      var graphSpec;
      graphSpec = spec;
    }

    return Graph;

  })();

  Data = (function() {

    function Data(input) {
      this.input = input;
    }

    return Data;

  })();

  this.Data = Data;

  transformFactory = function(transSpec) {
    return trans;
  };

  Transform = (function() {

    function Transform(transSpec) {
      this.transSpec = transSpec;
    }

    Transform.prototype.mutate = function(item) {
      return item;
    };

    return Transform;

  })();

  Bin = (function(_super) {

    __extends(Bin, _super);

    function Bin() {
      Bin.__super__.constructor.apply(this, arguments);
    }

    Bin.prototype.mutate = function(item) {
      return item;
    };

    return Bin;

  })(Transform);

  Lag = (function(_super) {

    __extends(Lag, _super);

    function Lag() {
      Lag.__super__.constructor.apply(this, arguments);
    }

    Lag.prototype.mutate = function(item) {
      return item;
    };

    return Lag;

  })(Transform);

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
    var filter, groupeData;
    _.each(dataSpec.trans, function(transSpec, key) {
      var trans;
      trans = transformFactory(transSpec);
      return _.each(rawData(function(d) {
        return trans.mutate(d);
      }));
    });
    filter = filterFactory(dataSpec.filter);
    rawData = filter(rawData);
    groupeData = groupby(filterSpec, rawData);
    return callback(statData);
  };

  backendProcess = function(dataSpec, rawData, callback) {
    return callback(statData);
  };

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
