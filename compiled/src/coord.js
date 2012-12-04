(function() {
  var Cartesian, Coordinate, Polar, poly,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  poly = this.poly || {};

  Coordinate = (function() {

    function Coordinate(params) {
      var _ref, _ref2;
      if (params == null) params = {};
      this.flip = (_ref = params.flip) != null ? _ref : false;
      _ref2 = this.flip ? ['y', 'x'] : ['x', 'y'], this.x = _ref2[0], this.y = _ref2[1];
    }

    Coordinate.prototype.ranges = function(dim) {};

    return Coordinate;

  })();

  Cartesian = (function(_super) {

    __extends(Cartesian, _super);

    function Cartesian() {
      Cartesian.__super__.constructor.apply(this, arguments);
    }

    Cartesian.prototype.make = function(dim) {
      return this.dim = dim;
    };

    Cartesian.prototype.ranges = function(dim) {
      var ranges;
      ranges = {};
      ranges[this.x] = {
        min: dim.paddingLeft + dim.guideLeft,
        max: dim.paddingLeft + dim.guideLeft + dim.chartWidth
      };
      ranges[this.y] = {
        min: dim.paddingTop + dim.guideTop + dim.chartHeight,
        max: dim.paddingTop + dim.guideTop
      };
      console.log(ranges);
      return ranges;
    };

    return Cartesian;

  })(Coordinate);

  Polar = (function(_super) {

    __extends(Polar, _super);

    function Polar() {
      Polar.__super__.constructor.apply(this, arguments);
    }

    Polar.prototype.make = function(dim) {
      return this.dim = dim;
    };

    Polar.prototype.ranges = function(dim) {
      var r, ranges, t, _ref;
      _ref = [this.x, this.y], r = _ref[0], t = _ref[1];
      ranges = {};
      ranges[t] = {
        min: 0,
        max: 2 * Math.PI
      };
      ranges[r] = {
        min: 0,
        max: Math.min(dim.chartWidth, dim.chartHeight) / 2
      };
      return ranges;
    };

    return Polar;

  })(Coordinate);

  poly.coord = {
    cartesian: function(params) {
      return new Cartesian(params);
    },
    polar: function(params) {
      return new Polar(params);
    }
  };

}).call(this);
