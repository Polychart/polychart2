(function() {
  var Area, Brewer, Color, Gradient, Gradient2, Identity, Linear, Log, PositionScale, Scale, Shape, aesthetics, poly,
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

  poly.scale = {
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
    },
    identity: function(params) {
      return new Identity(params);
    }
  };

  /*
  Scales here are objects that can construct functions that takes a value from
  the data, and returns another value that is suitable for rendering an
  attribute of that value.
  */

  Scale = (function() {

    function Scale(params) {
      this.f = null;
    }

    Scale.prototype.make = function(domain) {
      this.domain = domain;
      this.sortfn = poly.domain.sortfn(domain);
      switch (domain.type) {
        case 'num':
          return this._makeNum();
        case 'date':
          return this._makeDate();
        case 'cat':
          return this._makeCat();
      }
    };

    Scale.prototype._makeNum = function() {
      throw new poly.NotImplemented("_makeNum is not implemented");
    };

    Scale.prototype._makeDate = function() {
      throw new poly.NotImplemented("_makeDate is not implemented");
    };

    Scale.prototype._makeCat = function() {
      throw new poly.NotImplemented("_makeCat is not implemented");
    };

    Scale.prototype.tickType = function() {
      switch (this.domain.type) {
        case 'num':
          return this._tickNum(this.domain);
        case 'date':
          return this._tickDate(this.domain);
        case 'cat':
          return this._tickCat(this.domain);
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

    Scale.prototype._identityWrapper = function(y) {
      return function(x) {
        if (_.isObject(x) && x.t === 'scalefn') if (x.f === 'identity') return x.v;
        return y(x);
      };
    };

    return Scale;

  })();

  /*
  Position Scales for the x- and y-axes
  */

  PositionScale = (function(_super) {

    __extends(PositionScale, _super);

    function PositionScale(params) {
      this._catWrapper = __bind(this._catWrapper, this);
      this._numWrapper = __bind(this._numWrapper, this);      this.f = null;
      this.finv = null;
    }

    PositionScale.prototype.make = function(domain, range) {
      this.range = range;
      return PositionScale.__super__.make.call(this, domain);
    };

    PositionScale.prototype._numWrapper = function(domain, y) {
      var _this = this;
      return function(value) {
        var space;
        space = 0.001 * (_this.range.max > _this.range.min ? 1 : -1);
        if (_.isObject(value)) {
          if (value.t === 'scalefn') {
            if (value.f === 'identity') return value.v;
            if (value.f === 'upper') return y(value.v + domain.bw) - space;
            if (value.f === 'lower') return y(value.v) + space;
            if (value.f === 'middle') return y(value.v + domain.bw / 2);
            if (value.f === 'max') return _this.range.max + value.v;
            if (value.f === 'min') return _this.range.min + value.v;
          }
          throw new poly.UnexpectedObject("Expected a value instead of an object");
        }
        return y(value);
      };
    };

    PositionScale.prototype._catWrapper = function(step, y) {
      var _this = this;
      return function(value) {
        var space;
        space = 0.001 * (_this.range.max > _this.range.min ? 1 : -1);
        if (_.isObject(value)) {
          if (value.t === 'scalefn') {
            if (value.f === 'identity') return value.v;
            if (value.f === 'upper') return y(value.v) + step - space;
            if (value.f === 'lower') return y(value.v) + space;
            if (value.f === 'middle') return y(value.v) + step / 2;
            if (value.f === 'max') return _this.range.max + value.v;
            if (value.f === 'min') return _this.range.min + value.v;
          }
          throw new poly.UnexpectedObject("wtf is this object?");
        }
        return y(value) + step / 2;
      };
    };

    return PositionScale;

  })(Scale);

  Linear = (function(_super) {

    __extends(Linear, _super);

    function Linear() {
      Linear.__super__.constructor.apply(this, arguments);
    }

    Linear.prototype._makeNum = function() {
      var max, x, y, _ref;
      max = this.domain.max + ((_ref = this.domain.bw) != null ? _ref : 0);
      y = poly.linear(this.domain.min, this.range.min, max, this.range.max);
      x = poly.linear(this.range.min, this.domain.min, this.range.max, max);
      this.f = this._numWrapper(this.domain, y);
      return this.finv = function(y1, y2) {
        var xs;
        xs = [x(y1), x(y2)];
        return {
          ge: _.min(xs),
          le: _.max(xs)
        };
      };
    };

    Linear.prototype._makeDate = function() {
      return this._makeNum();
    };

    Linear.prototype._makeCat = function() {
      var step, x, y,
        _this = this;
      step = (this.range.max - this.range.min) / this.domain.levels.length;
      y = function(x) {
        var i;
        i = _.indexOf(_this.domain.levels, x);
        if (i === -1) {
          return null;
        } else {
          return _this.range.min + i * step;
        }
      };
      x = function(y1, y2) {
        var i1, i2, tmp;
        if (y2 < y1) {
          tmp = y2;
          y2 = y1;
          y1 = tmp;
        }
        i1 = Math.floor(y1 / step);
        i2 = Math.ceil(y2 / step);
        return {
          "in": _this.domain.levels.slice(i1, i2 + 1 || 9e9)
        };
      };
      this.f = this._catWrapper(step, y);
      return this.finv = x;
    };

    return Linear;

  })(PositionScale);

  Log = (function(_super) {

    __extends(Log, _super);

    function Log() {
      Log.__super__.constructor.apply(this, arguments);
    }

    Log.prototype._makeNum = function() {
      var lg, x, ylin, ylininv;
      lg = Math.log;
      ylin = poly.linear(lg(this.domain.min), this.range.min, lg(this.domain.max), this.range.max);
      this.f = this._numWrapper(function(x) {
        return ylin(lg(x));
      });
      ylininv = poly.linear(this.range.min, lg(this.domain.min), this.range.max, lg(this.domain.max));
      x = function(y) {
        return Math.exp(ylininv(y));
      };
      return this.finv = function(y1, y2) {
        var xs;
        xs = [x(y1), x(y2)];
        return {
          ge: _.min(xs),
          le: _.max(xs)
        };
      };
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
      this._makeNum = __bind(this._makeNum, this);
      Area.__super__.constructor.apply(this, arguments);
    }

    Area.prototype._makeNum = function() {
      var min, sq, ylin;
      min = this.domain.min === 0 ? 0 : 1;
      sq = Math.sqrt;
      ylin = poly.linear(sq(this.domain.min), min, sq(this.domain.max), 10);
      return this.f = this._identityWrapper(function(x) {
        return ylin(sq(x));
      });
    };

    return Area;

  })(Scale);

  Color = (function(_super) {

    __extends(Color, _super);

    function Color() {
      this._makeNum = __bind(this._makeNum, this);
      this._makeCat = __bind(this._makeCat, this);
      Color.__super__.constructor.apply(this, arguments);
    }

    Color.prototype._makeCat = function() {
      var h, n,
        _this = this;
      n = this.domain.levels.length;
      h = function(v) {
        return _.indexOf(_this.domain.levels, v) / n + 1 / (2 * n);
      };
      return this.f = function(value) {
        return Raphael.hsl(h(value), 0.5, 0.5);
      };
    };

    Color.prototype._makeNum = function() {
      var h;
      h = poly.linear(this.domain.min, 0, this.domain.max, 1);
      return this.f = function(value) {
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

    Brewer.prototype._makeCat = function() {};

    return Brewer;

  })(Scale);

  Gradient = (function(_super) {

    __extends(Gradient, _super);

    function Gradient(params) {
      this._makeNum = __bind(this._makeNum, this);      this.lower = params.lower, this.upper = params.upper;
    }

    Gradient.prototype._makeNum = function() {
      var b, g, lower, r, upper,
        _this = this;
      lower = Raphael.color(this.lower);
      upper = Raphael.color(this.upper);
      r = poly.linear(this.domain.min, lower.r, this.domain.max, upper.r);
      g = poly.linear(this.domain.min, lower.g, this.domain.max, upper.g);
      b = poly.linear(this.domain.min, lower.b, this.domain.max, upper.b);
      return this.f = this._identityWrapper(function(value) {
        return Raphael.rgb(r(value), g(value), b(value));
      });
    };

    return Gradient;

  })(Scale);

  Gradient2 = (function(_super) {

    __extends(Gradient2, _super);

    function Gradient2(params) {
      this._makeCat = __bind(this._makeCat, this);
      var lower, upper, zero;
      lower = params.lower, zero = params.zero, upper = params.upper;
    }

    Gradient2.prototype._makeCat = function() {};

    return Gradient2;

  })(Scale);

  Shape = (function(_super) {

    __extends(Shape, _super);

    function Shape() {
      Shape.__super__.constructor.apply(this, arguments);
    }

    Shape.prototype._makeCat = function() {};

    return Shape;

  })(Scale);

  Identity = (function(_super) {

    __extends(Identity, _super);

    function Identity() {
      Identity.__super__.constructor.apply(this, arguments);
    }

    Identity.prototype.make = function() {
      this.sortfn = function(x) {
        return x;
      };
      return this.f = this._identityWrapper(function(x) {
        return x;
      });
    };

    return Identity;

  })(Scale);

  /*
  # EXPORT
  */

  this.poly = poly;

}).call(this);
