(function() {
  var Area, Axis, Brewer, Gradient, Gradient2, Identity, Linear, Log, Scale, Shape, aesthetics, poly,
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

  poly.scale.make = function(guideSpec, domains, range) {
    var axis, scales;
    scales = {};
    axis = {};
    if (domains.x) {
      axis.s = poly.scale.linear();
      scales.x = axis.s.make(domains.x, range.x);
    }
    if (domains.y) {
      axis.s = poly.scale.linear();
      scales.y = axis.s.make(domains.y, range.y);
    }
    return [axis, scales];
  };

  /*
  # CLASSES
  */

  Scale = (function() {

    function Scale(params) {}

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

    return Scale;

  })();

  Axis = (function(_super) {

    __extends(Axis, _super);

    function Axis() {
      Axis.__super__.constructor.apply(this, arguments);
    }

    Axis.prototype.make = function(domain, range) {
      this.originalDomain = domain;
      this.range = range;
      return this.construct(domain);
    };

    Axis.prototype.remake = function(domain) {
      return this.construct(domain);
    };

    Axis.prototype.wrapper = function(y) {
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

    return Axis;

  })(Scale);

  Linear = (function(_super) {

    __extends(Linear, _super);

    function Linear() {
      Linear.__super__.constructor.apply(this, arguments);
    }

    Linear.prototype._constructNum = function(domain) {
      return this.wrapper(poly.linear(domain.min, this.range.min, domain.max, this.range.max));
    };

    return Linear;

  })(Axis);

  Log = (function(_super) {

    __extends(Log, _super);

    function Log() {
      Log.__super__.constructor.apply(this, arguments);
    }

    Log.prototype._constructNum = function(domain) {
      var lg, ylin;
      lg = Math.log;
      ylin = poly.linear(lg(domain.min), this.range.min, lg(domain.max), this.range.max);
      return this.wrapper(function(x) {
        return ylin(lg(x));
      });
    };

    return Log;

  })(Axis);

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
