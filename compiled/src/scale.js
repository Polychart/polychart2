(function() {
  var Area, Brewer, Color, Gradient, Gradient2, Identity, Linear, Log, PositionScale, Scale, ScaleSet, Shape, aesthetics, poly,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

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

    function ScaleSet(tmpRanges) {
      this.axes = {
        x: poly.guide.axis('x'),
        y: poly.guide.axis('y')
      };
      this.ranges = tmpRanges;
      this.legends = [];
      this.deletedLegends = [];
    }

    ScaleSet.prototype.make = function(guideSpec, domains, layers) {
      this.guideSpec = guideSpec;
      this.layers = layers;
      this.domains = domains;
      this.domainx = this.domains.x;
      this.domainy = this.domains.y;
      this.factory = this._makeFactory(guideSpec, domains, this.ranges);
      return this.scales = this.getScaleFns();
    };

    ScaleSet.prototype.setRanges = function(ranges) {
      this.ranges = ranges;
      return this.scales = this.getScaleFns();
    };

    ScaleSet.prototype.setXDomain = function(d) {
      this.domainx = d;
      return this.scales.x = this._makeXScale();
    };

    ScaleSet.prototype.setYDomain = function(d) {
      this.domainy = d;
      return this.scales.y = this._makeYScale();
    };

    ScaleSet.prototype.resetDomains = function() {
      this.domainx = this.domains.x;
      this.domainy = this.domains.y;
      this.scales.x = this._makeXScale();
      return this.scales.y = this._makeYScale();
    };

    ScaleSet.prototype.getScaleFns = function() {
      var scales,
        _this = this;
      scales = {};
      if (this.domainx) scales.x = this._makeXScale();
      if (this.domainy) scales.y = this._makeYScale();
      _.each(['color', 'size'], function(aes) {
        if (_this.domains[aes]) return scales[aes] = _this._makeScale(aes);
      });
      return scales;
    };

    ScaleSet.prototype._makeXScale = function() {
      return this.factory.x.construct(this.domainx, this.ranges.x);
    };

    ScaleSet.prototype._makeYScale = function() {
      return this.factory.y.construct(this.domainy, this.ranges.y);
    };

    ScaleSet.prototype._makeScale = function(aes) {
      return this.factory[aes].construct(this.domains[aes]);
    };

    ScaleSet.prototype.getSpec = function(a) {
      if ((this.guideSpec != null) && (this.guideSpec[a] != null)) {
        return this.guideSpec[a];
      } else {
        return {};
      }
    };

    ScaleSet.prototype.makeAxes = function() {
      this.axes.x.make({
        domain: this.domainx,
        type: this.factory.x.tickType(this.domainx),
        guideSpec: this.getSpec('x'),
        titletext: poly.getLabel(this.layers, 'x')
      });
      this.axes.y.make({
        domain: this.domainy,
        type: this.factory.y.tickType(this.domainy),
        guideSpec: this.getSpec('y'),
        titletext: poly.getLabel(this.layers, 'y')
      });
      return this.axes;
    };

    ScaleSet.prototype.renderAxes = function(dims, renderer) {
      this.axes.x.render(dims, renderer);
      return this.axes.y.render(dims, renderer);
    };

    ScaleSet.prototype._mapLayers = function(layers) {
      var aes, obj;
      obj = {};
      for (aes in this.domains) {
        if (aes === 'x' || aes === 'y') continue;
        obj[aes] = _.map(layers, function(layer) {
          if (layer.mapping[aes] != null) {
            return {
              type: 'map',
              value: layer.mapping[aes]
            };
          } else if (layer.consts[aes] != null) {
            return {
              type: 'const',
              value: layer["const"][aes]
            };
          } else {
            return layer.defaults[aes];
          }
        });
      }
      return obj;
    };

    ScaleSet.prototype._mergeAes = function(layers) {
      var aes, m, mapped, merged, merging, _i, _len;
      merging = [];
      for (aes in this.domains) {
        if (aes === 'x' || aes === 'y' || aes === 'id') continue;
        mapped = _.map(layers, function(layer) {
          return layer.mapping[aes];
        });
        if (!_.all(mapped, _.isUndefined)) {
          merged = false;
          for (_i = 0, _len = merging.length; _i < _len; _i++) {
            m = merging[_i];
            if (_.isEqual(m.mapped, mapped)) {
              m.aes.push(aes);
              merged = true;
              break;
            }
          }
          if (!merged) {
            merging.push({
              aes: [aes],
              mapped: mapped
            });
          }
        }
      }
      return _.pluck(merging, 'aes');
    };

    ScaleSet.prototype.makeLegends = function(mapping) {
      var aes, aesGroups, i, idx, layerMapping, legend, legenddeleted, _i, _j, _len, _len2, _ref;
      layerMapping = this._mapLayers(this.layers);
      aesGroups = this._mergeAes(this.layers);
      idx = 0;
      while (idx < this.legends.length) {
        legend = this.legends[idx];
        legenddeleted = true;
        i = 0;
        while (i < aesGroups.length) {
          aes = aesGroups[i];
          if (_.isEqual(aes, legend.aes)) {
            aesGroups.splice(i, 1);
            legenddeleted = false;
            break;
          }
          i++;
        }
        if (legenddeleted) {
          this.deletedLegends.push(legend);
          this.legends.splice(idx, 1);
        } else {
          idx++;
        }
      }
      for (_i = 0, _len = aesGroups.length; _i < _len; _i++) {
        aes = aesGroups[_i];
        this.legends.push(poly.guide.legend(aes));
      }
      _ref = this.legends;
      for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
        legend = _ref[_j];
        aes = legend.aes[0];
        legend.make({
          domain: this.domains[aes],
          guideSpec: this.getSpec(aes),
          type: this.factory[aes].tickType(this.domains[aes]),
          mapping: layerMapping,
          titletext: poly.getLabel(this.layers, aes)
        });
      }
      return this.legends;
    };

    ScaleSet.prototype.renderLegends = function(dims, renderer) {
      var legend, maxheight, maxwidth, newdim, offset, _i, _j, _len, _len2, _ref, _ref2, _results;
      _ref = this.deletedLegends;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        legend = _ref[_i];
        legend.remove(renderer);
      }
      this.deletedLegends = [];
      offset = {
        x: 0,
        y: 0
      };
      maxwidth = 0;
      maxheight = dims.height - dims.guideTop - dims.paddingTop;
      _ref2 = this.legends;
      _results = [];
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        legend = _ref2[_j];
        newdim = legend.getDimension();
        if (newdim.height + offset.y > maxheight) {
          offset.x += maxwidth + 5;
          offset.y = 0;
          maxwidth = 0;
        }
        if (newdim.width > maxwidth) maxwidth = newdim.width;
        legend.render(dims, renderer, offset);
        _results.push(offset.y += newdim.height);
      }
      return _results;
    };

    ScaleSet.prototype._makeFactory = function(guideSpec, domains, ranges) {
      var factory, specScale, _ref, _ref2, _ref3, _ref4;
      specScale = function(a) {
        if (guideSpec && (guideSpec[a] != null) && (guideSpec[a].scale != null)) {
          return guideSpec.x.scale;
        }
        return null;
      };
      factory = {
        x: (_ref = specScale('x')) != null ? _ref : poly.scale.linear(),
        y: (_ref2 = specScale('y')) != null ? _ref2 : poly.scale.linear()
      };
      if (domains.color != null) {
        if (domains.color.type === 'cat') {
          factory.color = (_ref3 = specScale('color')) != null ? _ref3 : poly.scale.color();
        } else {
          factory.color = (_ref4 = specScale('color')) != null ? _ref4 : poly.scale.gradient({
            upper: 'steelblue',
            lower: 'red'
          });
        }
      }
      if (domains.size != null) {
        factory.size = specScale('size') || poly.scale.area();
      }
      return factory;
    };

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
        if (_.isObject(x) && x.t === 'scalefn') if (x.f === 'identity') return x.v;
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
