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

    Coordinate.prototype.clipping = function() {
      var gb, gl, gt, h, pl, pt, w;
      pl = this.dims.paddingLeft;
      gl = this.dims.guideLeft;
      pt = this.dims.paddingTop;
      gt = this.dims.guideTop;
      gb = this.dims.guideBottom;
      w = this.dims.chartWidth;
      h = this.dims.chartHeight;
      return [pl + gl, pt + gt, w, h];
    };

    Coordinate.prototype.ranges = function() {};

    return Coordinate;

  })();

  Cartesian = (function(_super) {

    __extends(Cartesian, _super);

    function Cartesian() {
      Cartesian.__super__.constructor.apply(this, arguments);
    }

    Cartesian.prototype.type = 'cartesian';

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

    Polar.prototype.type = 'polar';

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
        max: Math.min(this.dims.chartWidth, this.dims.chartHeight) / 2 - 10
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
      var getpos, i, ident, points, r, radius, t, theta, x, xpos, y, ypos, _getx, _gety, _len, _len2, _ref, _ref2, _ref3, _ref4,
        _this = this;
      _getx = function(radius, theta) {
        return _this.cx + radius * Math.cos(theta - Math.PI / 2);
      };
      _gety = function(radius, theta) {
        return _this.cy + radius * Math.sin(theta - Math.PI / 2);
      };
      _ref = [this.x, this.y], r = _ref[0], t = _ref[1];
      if (mayflip) {
        if (_.isArray(mark[r])) {
          points = {
            x: [],
            y: [],
            r: [],
            t: []
          };
          _ref2 = mark[r];
          for (i = 0, _len = _ref2.length; i < _len; i++) {
            radius = _ref2[i];
            radius = scales[r](radius);
            theta = scales[t](mark[t][i]);
            points.x.push(_getx(radius, theta));
            points.y.push(_gety(radius, theta));
            points.r.push(radius);
            points.t.push(theta);
          }
          return points;
        }
        radius = scales[r](mark[r]);
        theta = scales[t](mark[t]);
        return {
          x: _getx(radius, theta),
          y: _gety(radius, theta),
          r: radius,
          t: theta
        };
      }
      ident = function(obj) {
        return _.isObject(obj) && obj.t === 'scalefn' && obj.f === 'identity';
      };
      getpos = function(x, y) {
        var identx, identy;
        identx = ident(x);
        identy = ident(y);
        if (identx && !identy) {
          return {
            x: x.v,
            y: _gety(scales[r](y), 0)
          };
        } else if (identx && identy) {
          return {
            x: x.v,
            y: y.v
          };
        } else if (!identx && identy) {
          return {
            y: y.v,
            x: _gety(scales[t](x), 0)
          };
        } else {
          radius = scales[r](y);
          theta = scales[t](x);
          return {
            x: _getx(radius, theta),
            y: _gety(radius, theta)
          };
        }
      };
      if (_.isArray(mark.x)) {
        points = {
          x: [],
          y: []
        };
        _ref3 = mark.x;
        for (i = 0, _len2 = _ref3.length; i < _len2; i++) {
          xpos = _ref3[i];
          ypos = mark.y[i];
          _ref4 = getpos(xpos, ypos), x = _ref4.x, y = _ref4.y;
          points.x.push(x);
          points.y.push(y);
        }
        return points;
      }
      return getpos(mark.x, mark.y);
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
