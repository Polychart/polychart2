(function() {
  var Area, Brewer, Color, Gradient, Gradient2, Identity, Linear, Log, PositionScale, Scale, ScaleSet, Shape, aesthetics, poly,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
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
      this._makeAxes = __bind(this._makeAxes, this);
      this._getparams = __bind(this._getparams, this);
      var specScale, _ref, _ref2, _ref3, _ref4;
      specScale = function(a) {
        if (guideSpec && (guideSpec[a] != null) && (guideSpec[a].scale != null)) {
          return guideSpec.x.scale;
        }
        return null;
      };
      this.guideSpec = guideSpec;
      this.factory = {
        x: (_ref = specScale('x')) != null ? _ref : poly.scale.linear(),
        y: (_ref2 = specScale('y')) != null ? _ref2 : poly.scale.linear()
      };
      if (domains.color != null) {
        if (domains.color.type === 'cat') {
          this.factory.color = (_ref3 = specScale('color')) != null ? _ref3 : poly.scale.color();
        } else {
          this.factory.color = (_ref4 = specScale('color')) != null ? _ref4 : poly.scale.gradient({
            upper: 'steelblue',
            lower: 'red'
          });
        }
      }
      if (domains.size != null) {
        this.factory.size = specScale('size') || poly.scale.area();
      }
      this.ranges = ranges;
      this.scales = {};
      this.setDomains(domains);
    }

    ScaleSet.prototype.setDomains = function(domains) {
      this.domains = domains;
      this.domainx = this.domains.x;
      return this.domainy = this.domains.y;
    };

    ScaleSet.prototype.setRanges = function(ranges) {
      return this.ranges = ranges;
    };

    ScaleSet.prototype.setXDomain = function(d) {
      return this.domainx = d;
    };

    ScaleSet.prototype.setYDomain = function(d) {
      return this.domainy = d;
    };

    ScaleSet.prototype.resetDomains = function() {
      this.domainx = this.domains.x;
      return this.domainy = this.domains.y;
    };

    ScaleSet.prototype.getScaleFns = function() {
      if (this.domainx) {
        this.scales.x = this.factory.x.construct(this.domainx, this.ranges.x);
      }
      if (this.domainy) {
        this.scales.y = this.factory.y.construct(this.domainy, this.ranges.y);
      }
      if (this.domains.color && !(this.scales.color != null)) {
        this.scales.color = this.factory.color.construct(this.domains.color);
      }
      if (this.domains.size && !(this.scales.size != null)) {
        this.scales.size = this.factory.size.construct(this.domains.size);
      }
      return this.scales;
    };

    ScaleSet.prototype.getAxes = function() {
      var _this = this;
      this.getScaleFns();
      if (this.axes != null) {
        _.each(this.axes, function(axis, a) {
          return axis.make(_this._getparams(a));
        });
      } else {
        this.axes = this._makeAxes();
      }
      return this.axes;
    };

    ScaleSet.prototype._getparams = function(a) {
      return {
        domain: this.domains[a],
        factory: this.factory[a],
        scale: this.scales[a],
        guideSpec: this.guideSpec && this.guideSpec[a] ? this.guideSpec[a] : {}
      };
    };

    ScaleSet.prototype._makeAxes = function() {
      var axes, params;
      axes = {};
      if (this.factory.x && this.domainx) {
        params = this._getparams('x');
        params.domain = this.domainx;
        params.type = 'x';
        axes.x = poly.guide.axis(params);
      }
      if (this.factory.y && this.domainy) {
        params = this._getparams('y');
        params.domain = this.domainy;
        params.type = 'y';
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
      throw new poly.NotImplemented("_constructNum is not implemented");
    };

    Scale.prototype._constructDate = function(domain) {
      throw new poly.NotImplemented("_constructDate is not implemented");
    };

    Scale.prototype._constructCat = function(domain) {
      throw new poly.NotImplemented("_constructCat is not implemented");
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
      return function(value) {
        var space;
        space = 2;
        if (_.isObject(value)) {
          if (value.t === 'scalefn') {
            if (value.f === 'identity') return value.v;
            if (value.f === 'upper') return y(value.v + domain.bw) - space;
            if (value.f === 'lower') return y(value.v) + space;
            if (value.f === 'middle') return y(value.v + domain.bw / 2);
          }
          throw new poly.UnexpectedObject("Expected a value instead of an object");
        }
        return y(value);
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

    Linear.prototype._wrapper2 = function(step, y) {
      return function(value) {
        var space;
        space = 2;
        if (_.isObject(value)) {
          if (value.t === 'scalefn') {
            if (value.f === 'identity') return value.v;
            if (value.f === 'upper') return y(value.v) + step - space;
            if (value.f === 'lower') return y(value.v) + space;
            if (value.f === 'middle') return y(value.v) + step / 2;
          }
          throw new poly.UnexpectedObject("wtf is this object?");
        }
        return y(value) + step / 2;
      };
    };

    Linear.prototype._constructCat = function(domain) {
      var step, y,
        _this = this;
      step = (this.range.max - this.range.min) / domain.levels.length;
      y = function(x) {
        var i;
        i = _.indexOf(domain.levels, x);
        if (i === -1) {
          return null;
        } else {
          return _this.range.min + i * step;
        }
      };
      return this._wrapper2(step, y);
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
      var min, sq, ylin;
      min = domain.min === 0 ? 0 : 1;
      sq = Math.sqrt;
      ylin = poly.linear(sq(domain.min), min, sq(domain.max), 10);
      return function(x) {
        return ylin(sq(x));
      };
    };

    return Area;

  })(Scale);

  Color = (function(_super) {

    __extends(Color, _super);

    function Color() {
      Color.__super__.constructor.apply(this, arguments);
    }

    Color.prototype._constructCat = function(domain) {
      var h, n;
      n = domain.levels.length;
      h = function(v) {
        return _.indexOf(domain.levels, v) / n + 1 / (2 * n);
      };
      return function(value) {
        return Raphael.hsl(h(value), 0.5, 0.5);
      };
    };

    Color.prototype._constructNum = function(domain) {
      var h;
      h = poly.linear(domain.min, 0, domain.max, 1);
      return function(value) {
        return Raphael.hsl(0.5, h(value), 0.5);
      };
    };

    return Color;

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
      this._constructNum = __bind(this._constructNum, this);      this.lower = params.lower, this.upper = params.upper;
    }

    Gradient.prototype._constructNum = function(domain) {
      var b, g, lower, r, upper,
        _this = this;
      lower = Raphael.color(this.lower);
      upper = Raphael.color(this.upper);
      r = poly.linear(domain.min, lower.r, domain.max, upper.r);
      g = poly.linear(domain.min, lower.g, domain.max, upper.g);
      b = poly.linear(domain.min, lower.b, domain.max, upper.b);
      return function(value) {
        return Raphael.rgb(r(value), g(value), b(value));
      };
    };

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

  poly.scale = _.extend(poly.scale, {
    linear: function(params) {
      return new Linear(params);
    },
    log: function(params) {
      return new Log(params);
    },
    area: function(params) {
      return new Area(params);
    },
    color: function(params) {
      return new Color(params);
    },
    gradient: function(params) {
      return new Gradient(params);
    }
  });

  /*
  # EXPORT
  */

  this.poly = poly;

}).call(this);
