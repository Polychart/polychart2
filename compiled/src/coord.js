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

    Coordinate.prototype.make = function(dims) {
      return this.dims = dims;
    };

    Coordinate.prototype.ranges = function() {};

    return Coordinate;

  })();

  Cartesian = (function(_super) {

    __extends(Cartesian, _super);

    function Cartesian() {
      Cartesian.__super__.constructor.apply(this, arguments);
    }

    Cartesian.prototype.ranges = function() {
      var ranges;
      ranges = {};
      ranges[this.x] = {
        min: this.dims.paddingLeft + this.dims.guideLeft,
        max: this.dims.paddingLeft + this.dims.guideLeft + this.dims.chartWidth
      };
      ranges[this.y] = {
        min: this.dims.paddingTop + this.dims.guideTop + this.dims.chartHeight,
        max: this.dims.paddingTop + this.dims.guideTop
      };
      return ranges;
    };

    Cartesian.prototype.axisType = function(aes) {
      return this[aes];
    };

    Cartesian.prototype.getXY = function(mayflip, scales, mark) {
      var point, scalex, scaley;
      if (mayflip) {
        point = {
          x: _.isArray(mark.x) ? _.map(mark.x, scales.x) : scales.x(mark.x),
          y: _.isArray(mark.y) ? _.map(mark.y, scales.y) : scales.y(mark.y)
        };
        return {
          x: point[this.x],
          y: point[this.y]
        };
      } else {
        scalex = scales[this.x];
        scaley = scales[this.y];
        return {
          x: _.isArray(mark.x) ? _.map(mark.x, scalex) : scalex(mark.x),
          y: _.isArray(mark.y) ? _.map(mark.y, scaley) : scaley(mark.y)
        };
      }
    };

    return Cartesian;

  })(Coordinate);

  Polar = (function(_super) {

    __extends(Polar, _super);

    function Polar() {
      Polar.__super__.constructor.apply(this, arguments);
    }

    Polar.prototype.make = function(dims) {
      this.dims = dims;
      this.cx = this.dims.paddingLeft + this.dims.guideLeft + this.dims.chartWidth / 2;
      return this.cy = this.dims.paddingTop + this.dims.guideTop + this.dims.chartHeight / 2;
    };

    Polar.prototype.ranges = function() {
      var r, ranges, t, _ref;
      _ref = [this.x, this.y], r = _ref[0], t = _ref[1];
      ranges = {};
      ranges[t] = {
        min: 0,
        max: 2 * Math.PI
      };
      ranges[r] = {
        min: 0,
        max: Math.min(this.dims.chartWidth, this.dims.chartHeight) / 2
      };
      return ranges;
    };

    Polar.prototype.axisType = function(aes) {
      if (this[aes] === 'x') {
        return 'r';
      } else {
        return 't';
      }
    };

    Polar.prototype.getXY = function(mayflip, scales, mark) {
      var i, point, points, r, radius, t, theta, _getxy, _len, _ref, _ref2,
        _this = this;
      _ref = [this.x, this.y], r = _ref[0], t = _ref[1];
      _getxy = function(radius, theta) {
        return {
          x: _this.cx + radius * Math.cos(theta - Math.PI / 2),
          y: _this.cy + radius * Math.sin(theta - Math.PI / 2)
        };
      };
      points = {
        x: [],
        y: []
      };
      if (_.isArray(mark[r])) {
        _ref2 = mark[r];
        for (i = 0, _len = _ref2.length; i < _len; i++) {
          radius = _ref2[i];
          radius = scales[r](radius);
          theta = scales[t](mark[t][i]);
          point = _getxy(radius, theta);
          points.x.push(point.x);
          points.y.push(point.y);
        }
      } else {
        points = _getxy(scales[r](mark[r]), scales[t](mark[t]));
      }
      return points;
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
