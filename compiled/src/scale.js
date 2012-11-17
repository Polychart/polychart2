(function() {
  var Area, Brewer, Gradient, Gradient2, Identity, Linear, Log, PositionScale, Scale, ScaleSet, Shape, aesthetics, poly,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  poly = this.poly || {};

  /*
  # CONSTANTS
  */

  aesthetics = poly["const"].aes;

  /*
  # GLOBALS
  */

  poly.scale = {};

  poly.scale.make = function(guideSpec, domains, ranges) {
    return new ScaleSet(guideSpec, domains, ranges);
  };

  ScaleSet = (function() {

    function ScaleSet(guideSpec, domains, ranges) {
      var inspec;
      inspec = function(a) {
        return guideSpec && (guideSpec[a] != null) && (guideSpec[a].scale != null);
      };
      this.guideSpec = guideSpec;
      this.factory = {
        x: inspec('x') ? guideSpec.x.scale : poly.scale.linear(),
        y: inspec('y') ? guideSpec.y.scale : poly.scale.linear()
      };
      this.domains = domains;
      this.domainx = this.domains.x;
      this.domainy = this.domains.y;
      this.ranges = ranges;
    }

    ScaleSet.prototype.setRanges = function(ranges) {
      return this.ranges = ranges;
    };

    ScaleSet.prototype.getScaleFns = function() {
      this.scales = {};
      if (this.domainx) {
        this.scales.x = this.factory.x.construct(this.domainx, this.ranges.x);
      }
      if (this.domainy) {
        this.scales.y = this.factory.y.construct(this.domainy, this.ranges.y);
      }
      return this.scales;
    };

    ScaleSet.prototype.setXDomain = function(d) {
      this.domainx = d;
      return this.getScaleFns();
    };

    ScaleSet.prototype.setYDomain = function(d) {
      this.domainy = d;
      return this.getScaleFns();
    };

    ScaleSet.prototype.resetDomains = function() {
      this.domainx = this.domains.x;
      return this.domainy = this.domains.y;
    };

    ScaleSet.prototype.getAxes = function() {
      var axes, getparams, params,
        _this = this;
      this.getScaleFns();
      axes = {};
      getparams = function(a) {
        return {
          domain: _this.domains[a],
          factory: _this.factory[a],
          scale: _this.scales[a],
          guideSpec: _this.guideSpec && _this.guideSpec[a] ? _this.guideSpec[a] : {}
        };
      };
      if (this.factory.x && this.domainx) {
        params = getparams('x');
        params.domain = this.domainx;
        axes.x = poly.guide.axis(params);
      }
      if (this.factory.y && this.domainy) {
        params = getparams('y');
        params.domain = this.domainy;
        axes.y = poly.guide.axis(params);
      }
      return axes;
    };

    ScaleSet.prototype.getLegends = function() {};

    return ScaleSet;

  })();

  /*
  # CLASSES
  */

  /*
  Scales here are objects that can construct functions that takes a value from
  the data, and returns another value that is suitable for rendering an
  attribute of that value.
  */

  Scale = (function() {

    function Scale(params) {}

    Scale.prototype.guide = function() {};

    Scale.prototype.construct = function(domain) {
      switch (domain.type) {
        case 'num':
          return this._constructNum(domain);
        case 'date':
          return this._constructDate(domain);
        case 'cat':
          return this._constructCat(domain);
      }
    };

    Scale.prototype._constructNum = function(domain) {
      return console.log('wtf not impl');
    };

    Scale.prototype._constructDate = function(domain) {
      return console.log('wtf not impl');
    };

    Scale.prototype._constructCat = function(domain) {
      return console.log('wtf not impl');
    };

    Scale.prototype.tickType = function(domain) {
      switch (domain.type) {
        case 'num':
          return this._tickNum(domain);
        case 'date':
          return this._tickDate(domain);
        case 'cat':
          return this._tickCat(domain);
      }
    };

    Scale.prototype._tickNum = function() {
      return 'num';
    };

    Scale.prototype._tickDate = function() {
      return 'date';
    };

    Scale.prototype._tickCat = function() {
      return 'cat';
    };

    return Scale;

  })();

  /*
  Position Scales for the x- and y-axes
  */

  PositionScale = (function(_super) {

    __extends(PositionScale, _super);

    function PositionScale() {
      PositionScale.__super__.constructor.apply(this, arguments);
    }

    PositionScale.prototype.construct = function(domain, range) {
      this.range = range;
      return PositionScale.__super__.construct.call(this, domain);
    };

    PositionScale.prototype._wrapper = function(y) {
      return function(val) {
        var space;
        space = 2;
        if (_.isObject(val)) {
          if (value.t === 'scalefn') {
            if (value.f === 'upper') return y(val + domain.bw) - space;
            if (value.f === 'lower') return y(val) + space;
            if (value.f === 'middle') return y(val + domain.bw / 2);
          }
          console.log('wtf');
        }
        return y(val);
      };
    };

    return PositionScale;

  })(Scale);

  Linear = (function(_super) {

    __extends(Linear, _super);

    function Linear() {
      Linear.__super__.constructor.apply(this, arguments);
    }

    Linear.prototype._constructNum = function(domain) {
      return this._wrapper(poly.linear(domain.min, this.range.min, domain.max, this.range.max));
    };

    Linear.prototype._constructCat = function(domain) {
      return function(x) {
        return 20;
      };
    };

    return Linear;

  })(PositionScale);

  Log = (function(_super) {

    __extends(Log, _super);

    function Log() {
      Log.__super__.constructor.apply(this, arguments);
    }

    Log.prototype._constructNum = function(domain) {
      var lg, ylin;
      lg = Math.log;
      ylin = poly.linear(lg(domain.min), this.range.min, lg(domain.max), this.range.max);
      return this._wrapper(function(x) {
        return ylin(lg(x));
      });
    };

    Log.prototype._tickNum = function() {
      return 'num-log';
    };

    return Log;

  })(PositionScale);

  /*
  Other, legend-type scales for the x- and y-axes
  */

  Area = (function(_super) {

    __extends(Area, _super);

    function Area() {
      Area.__super__.constructor.apply(this, arguments);
    }

    Area.prototype._constructNum = function(domain) {
      var ylin;
      ylin = linear(Math.sqrt(domain.max, Math.sqrt(domain.min)));
      return wrapper(function(x) {
        return ylin(Math.sqrt(x));
      });
    };

    return Area;

  })(Scale);

  Brewer = (function(_super) {

    __extends(Brewer, _super);

    function Brewer() {
      Brewer.__super__.constructor.apply(this, arguments);
    }

    Brewer.prototype._constructCat = function(domain) {};

    return Brewer;

  })(Scale);

  Gradient = (function(_super) {

    __extends(Gradient, _super);

    function Gradient(params) {
      var lower, upper;
      lower = params.lower, upper = params.upper;
    }

    Gradient.prototype._constructCat = function(domain) {};

    return Gradient;

  })(Scale);

  Gradient2 = (function(_super) {

    __extends(Gradient2, _super);

    function Gradient2(params) {
      var lower, upper, zero;
      lower = params.lower, zero = params.zero, upper = params.upper;
    }

    Gradient2.prototype._constructCat = function(domain) {};

    return Gradient2;

  })(Scale);

  Shape = (function(_super) {

    __extends(Shape, _super);

    function Shape() {
      Shape.__super__.constructor.apply(this, arguments);
    }

    Shape.prototype._constructCat = function(domain) {};

    return Shape;

  })(Scale);

  Identity = (function(_super) {

    __extends(Identity, _super);

    function Identity() {
      Identity.__super__.constructor.apply(this, arguments);
    }

    Identity.prototype.construct = function(domain) {
      return function(x) {
        return x;
      };
    };

    return Identity;

  })(Scale);

  poly.scale.linear = function(params) {
    return new Linear(params);
  };

  poly.scale.log = function(params) {
    return new Log(params);
  };

  /*
  # EXPORT
  */

  this.poly = poly;

}).call(this);
