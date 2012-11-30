(function() {
  var poly;

  poly = this.poly || {};

  /*
  Group an array of data items by the value of certain columns.
  
  Input:
  - `data`: an array of data items
  - `group`: an array of column keys, to group by
  Output:
  - an associate array of key: array of data, with the appropriate grouping
    the `key` is a string of format "columnKey:value;colunmKey2:value2;..."
  */

  poly.groupBy = function(data, group) {
    return _.groupBy(data, function(item) {
      var concat;
      concat = function(memo, g) {
        return "" + memo + g + ":" + item[g] + ";";
      };
      return _.reduce(group, concat, "");
    });
  };

  /*
  Produces a linear function that passes through two points.
  Input:
  - `x1`: x coordinate of the first point
  - `y1`: y coordinate of the first point
  - `x2`: x coordinate of the second point
  - `y2`: y coordinate of the second point
  Output:
  - A function that, given the x-coord, returns the y-coord
  */

  poly.linear = function(x1, y1, x2, y2) {
    return function(x) {
      return (y2 - y1) / (x2 - x1) * (x - x1) + y1;
    };
  };

  /*
  given a sorted list and a midpoint calculate the median
  */

  poly.median = function(values, sorted) {
    var mid;
    if (sorted == null) sorted = false;
    if (!sorted) {
      values = _.sortBy(values, function(x) {
        return x;
      });
    }
    mid = values.length / 2;
    if (mid % 1 !== 0) return values[Math.floor(mid)];
    return (values[mid - 1] + values[mid]) / 2;
  };

  this.poly = poly;

  /*
  Produces a function that counts how many times it has been called
  */

  poly.counter = function() {
    var i;
    i = 0;
    return function() {
      return i++;
    };
  };

  /*
  Given an OLD array and NEW array, split the points in (OLD union NEW) into
  three sets: 
    - deleted
    - kept
    - added
  TODO: make this a one-pass algorithm
  */

  poly.compare = function(oldarr, newarr) {
    return {
      deleted: _.difference(oldarr, newarr),
      kept: _.intersection(newarr, oldarr),
      added: _.difference(newarr, oldarr)
    };
  };

  /*
  Given an aesthetic mapping in the "geom" object, flatten it and extract only
  the values from it
  
  TODO: handles the "novalue" case (when x or y has no mapping)
  */

  poly.flatten = function(values) {
    var flat;
    flat = [];
    if (values != null) {
      if (_.isObject(values)) {
        if (values.t === 'scalefn') {
          flat.push(values.v);
        } else {
          _.each(values, function(v) {
            return flat = flat.concat(poly.flatten(v));
          });
        }
      } else if (_.isArray(values)) {
        _.each(values, function(v) {
          return flat = flat.concat(poly.flatten(v));
        });
      } else {
        flat.push(values);
      }
    }
    return flat;
  };

}).call(this);
(function() {
  var poly;

  poly = this.poly || {};

  /*
  CONSTANTS
  ---------
  These are constants that are referred to throughout the coebase
  */

  poly["const"] = {
    aes: ['x', 'y', 'color', 'size', 'opacity', 'shape', 'id'],
    scaleFns: {
      novalue: function() {
        return {
          v: null,
          f: 'novalue',
          t: 'scalefn'
        };
      },
      upper: function(v) {
        return {
          v: v,
          f: 'upper',
          t: 'scalefn'
        };
      },
      lower: function(v) {
        return {
          v: v,
          f: 'lower',
          t: 'scalefn'
        };
      },
      middle: function(v) {
        return {
          v: v,
          f: 'middle',
          t: 'scalefn'
        };
      },
      jitter: function(v) {
        return {
          v: v,
          f: 'jitter',
          t: 'scalefn'
        };
      },
      identity: function(v) {
        return {
          v: v,
          f: 'identity',
          t: 'scalefn'
        };
      }
    },
    epsilon: Math.pow(10, -7)
  };

  this.poly = poly;

}).call(this);
(function() {
  var LengthError, NotImplemented, StrictModeError, UnexpectedObject, UnknownError, poly,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  poly = this.poly || {};

  NotImplemented = (function(_super) {

    __extends(NotImplemented, _super);

    function NotImplemented(message) {
      this.message = message != null ? message : "Not implemented";
      this.name = "NotImplemented";
    }

    return NotImplemented;

  })(Error);

  poly.NotImplemented = NotImplemented;

  UnexpectedObject = (function(_super) {

    __extends(UnexpectedObject, _super);

    function UnexpectedObject(message) {
      this.message = message != null ? message : "Unexpected Object";
      this.name = "UnexpectedObject";
    }

    return UnexpectedObject;

  })(Error);

  poly.UnexpectedObject = UnexpectedObject;

  StrictModeError = (function(_super) {

    __extends(StrictModeError, _super);

    function StrictModeError(message) {
      this.message = message != null ? message : "Can't use strict mode here";
      this.name = "StrictModeError";
    }

    return StrictModeError;

  })(Error);

  poly.StrictModeError = StrictModeError;

  LengthError = (function(_super) {

    __extends(LengthError, _super);

    function LengthError(message) {
      this.message = message != null ? message : "Unexpected length";
      this.name = "LengthError";
    }

    return LengthError;

  })(Error);

  poly.LengthError = LengthError;

  UnknownError = (function(_super) {

    __extends(UnknownError, _super);

    function UnknownError(message) {
      this.message = message != null ? message : "Unknown error";
      this.name = "UnknownError";
    }

    return UnknownError;

  })(Error);

  poly.UnknownError = UnknownError;

}).call(this);
(function() {
  var CategoricalDomain, DateDomain, NumericDomain, aesthetics, domainMerge, flattenGeoms, makeDomain, makeDomainSet, mergeDomainSets, mergeDomains, poly;

  poly = this.poly || {};

  /*
  # CONSTANTS
  */

  aesthetics = poly["const"].aes;

  /*
  # GLOBALS
  */

  poly.domain = {};

  /*
  Produce a domain set for each layer based on both the information in each
  layer and the specification of the guides, then merge them into one domain
  set.
  */

  poly.domain.make = function(layers, guideSpec, strictmode) {
    var domainSets;
    domainSets = [];
    _.each(layers, function(layerObj) {
      return domainSets.push(makeDomainSet(layerObj, guideSpec, strictmode));
    });
    return mergeDomainSets(domainSets);
  };

  /*
  # CLASSES & HELPER
  */

  /*
  Domain classes
  */

  NumericDomain = (function() {

    function NumericDomain(params) {
      this.type = params.type, this.min = params.min, this.max = params.max, this.bw = params.bw;
    }

    return NumericDomain;

  })();

  DateDomain = (function() {

    function DateDomain(params) {
      this.type = params.type, this.min = params.min, this.max = params.max, this.bw = params.bw;
    }

    return DateDomain;

  })();

  CategoricalDomain = (function() {

    function CategoricalDomain(params) {
      this.type = params.type, this.levels = params.levels, this.sorted = params.sorted;
    }

    return CategoricalDomain;

  })();

  /*
  Public-ish interface for making different domain types
  */

  makeDomain = function(params) {
    switch (params.type) {
      case 'num':
        return new NumericDomain(params);
      case 'date':
        return new DateDomain(params);
      case 'cat':
        return new CategoricalDomain(params);
    }
  };

  /*
  Make a domain set. A domain set is an associate array of domains, with the
  keys being aesthetics
  */

  makeDomainSet = function(layerObj, guideSpec, strictmode) {
    var domain;
    domain = {};
    _.each(_.keys(layerObj.mapping), function(aes) {
      var values;
      values = flattenGeoms(layerObj.geoms, aes);
      console.log(values);
      if (strictmode) return domain[aes] = makeDomain(guideSpec[aes]);
    });
    return domain;
  };

  flattenGeoms = function(geoms, aes) {
    var values;
    values = [];
    _.each(geoms, function(geom) {
      return _.each(geom.marks, function(mark) {
        return values = values.concat(poly.flatten(mark[aes]));
      });
    });
    return values;
  };

  /*
  Merge an array of domain sets: i.e. merge all the domains that shares the
  same aesthetics.
  */

  mergeDomainSets = function(domainSets) {
    var merged;
    merged = {};
    _.each(aesthetics, function(aes) {
      var domains;
      domains = _.without(_.pluck(domainSets, aes), void 0);
      if (domains.length > 0) return merged[aes] = mergeDomains(domains);
    });
    return merged;
  };

  /*
  Helper for merging domains of the same type. Two domains of the same type
  can be merged if they share the same properties:
   - For numeric/date variables all domains must have the same binwidth parameter
   - For categorial variables, sorted domains must have any categories in common
  */

  domainMerge = {
    'num': function(domains) {
      var bw, max, min, _ref;
      bw = _.uniq(_.map(domains, function(d) {
        return d.bw;
      }));
      if (bw.length > 1) {
        throw new poly.LengthError("All binwidths are not of the same length");
      }
      bw = (_ref = bw[0]) != null ? _ref : void 0;
      min = _.min(_.map(domains, function(d) {
        return d.min;
      }));
      max = _.max(_.map(domains, function(d) {
        return d.max;
      }));
      return makeDomain({
        type: 'num',
        min: min,
        max: max,
        bw: bw
      });
    },
    'cat': function(domains) {
      var levels, sortedLevels, unsortedLevels;
      sortedLevels = _.chain(domains).filter(function(d) {
        return d.sorted;
      }).map(function(d) {
        return d.levels;
      }).value();
      unsortedLevels = _.chain(domains).filter(function(d) {
        return !d.sorted;
      }).map(function(d) {
        return d.levels;
      }).value();
      if (sortedLevels.length > 0 && _.intersection.apply(this, sortedLevels)) {
        throw new poly.UnknownError();
      }
      sortedLevels = [_.flatten(sortedLevels, true)];
      levels = _.union.apply(this, sortedLevels.concat(unsortedLevels));
      return makeDomain({
        type: 'cat',
        levels: levels,
        sorted: true
      });
    }
  };

  /*
  Merge an array of domains: Two domains can be merged if they are of the
  same type, and they share certain properties.
  */

  mergeDomains = function(domains) {
    var types;
    types = _.uniq(_.map(domains, function(d) {
      return d.type;
    }));
    if (types.length > 1) {
      throw new poly.TypeError("Not all domains are of the same type");
    }
    return domainMerge[types[0]](domains);
  };

  /*
  # EXPORT
  */

  this.poly = poly;

}).call(this);
(function() {
  var Tick, getStep, poly, tickFactory, tickValues;

  poly = this.poly || {};

  /*
  # GLOBALS
  */

  poly.tick = {};

  /*
  Produce an associate array of aesthetics to tick objects.
  */

  poly.tick.make = function(domain, guideSpec, type) {
    var formatter, numticks, tickfn, tickobjs, ticks, _ref;
    if (guideSpec.ticks != null) {
      ticks = guideSpec.ticks;
    } else {
      numticks = (_ref = guideSpec.numticks) != null ? _ref : 5;
      ticks = tickValues[type](domain, numticks);
    }
    formatter = function(x) {
      return x;
    };
    if (guideSpec.labels) {
      formatter = function(x) {
        var _ref2;
        return (_ref2 = guideSpec.labels[x]) != null ? _ref2 : x;
      };
    } else if (guideSpec.formatter) {
      formatter = guideSpec.formatter;
    }
    tickobjs = {};
    tickfn = tickFactory(formatter);
    _.each(ticks, function(t) {
      return tickobjs[t] = tickfn(t);
    });
    return tickobjs;
  };

  /*
  # CLASSES & HELPERS
  */

  /*
  Tick Object.
  */

  Tick = (function() {

    function Tick(params) {
      this.location = params.location, this.value = params.value;
    }

    return Tick;

  })();

  /*
  Helper function for creating a function that creates ticks
  */

  tickFactory = function(formatter) {
    return function(value) {
      return new Tick({
        location: value,
        value: formatter(value)
      });
    };
  };

  /*
  Helper function for determining the size of each "step" (distance between
  ticks) for numeric scales
  */

  getStep = function(span, numticks) {
    var error, step;
    step = Math.pow(10, Math.floor(Math.log(span / numticks) / Math.LN10));
    error = numticks / span * step;
    if (error < 0.15) {
      step *= 10;
    } else if (error <= 0.35) {
      step *= 5;
    } else if (error <= 0.75) {
      step *= 2;
    }
    return step;
  };

  /*
  Function for calculating the location of ticks.
  */

  tickValues = {
    'cat': function(domain, numticks) {
      return domain.levels;
    },
    'num': function(domain, numticks) {
      var max, min, step, ticks, tmp;
      min = domain.min, max = domain.max;
      step = getStep(max - min, numticks);
      tmp = Math.ceil(min / step) * step;
      ticks = [];
      while (tmp < max) {
        ticks.push(tmp);
        tmp += step;
      }
      return ticks;
    },
    'num-log': function(domain, numticks) {
      var exp, lg, lgmax, lgmin, max, min, num, step, tmp;
      min = domain.min, max = domain.max;
      lg = function(v) {
        return Math.log(v) / Math.LN10;
      };
      exp = function(v) {
        return Math.exp(v * Math.LN10);
      };
      lgmin = Math.max(lg(min), 0);
      lgmax = lg(max);
      step = getStep(lgmax - lgmin, numticks);
      tmp = Math.ceil(lgmin / step) * step;
      while (tmp < (lgmax + poly["const"].epsilon)) {
        if (tmp % 1 !== 0 && tmp % 1 <= 0.1) {
          tmp += step;
          continue;
        } else if (tmp % 1 > poly["const"].epsilon) {
          num = Math.floor(tmp) + lg(10 * (tmp % 1));
          if (num % 1 === 0) {
            tmp += step;
            continue;
          }
        }
        num = exp(num);
        if (num < min || num > max) {
          tmp += step;
          continue;
        }
        ticks.push(num);
      }
      return ticks;
    },
    'date': function(domain, numticks) {
      return 2;
    }
  };

  /*
  # EXPORT
  */

  this.poly = poly;

}).call(this);
(function() {
  var Axis, Guide, Legend, poly, sf,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  poly = this.poly || {};

  sf = poly["const"].scaleFns;

  Guide = (function() {

    function Guide(params) {
      this.scales = params.scales, this.guideSpec = params.guideSpec;
      this.position = 'right';
      this.ticks = [];
    }

    Guide.prototype.getWidth = function() {};

    Guide.prototype.getHeight = function() {};

    Guide.prototype.render = function(paper, render, scales) {
      throw new poly.NotImplemented("render is not implemented");
    };

    return Guide;

  })();

  Axis = (function(_super) {

    __extends(Axis, _super);

    function Axis(params) {
      this._tickToTextFn = __bind(this._tickToTextFn, this);
      this._tickToGeomFn = __bind(this._tickToGeomFn, this);
      this.render = __bind(this.render, this);
      this._renderline = __bind(this._renderline, this);
      this.make = __bind(this.make, this);      this.type = params.type;
      this.position = this.type === 'x' ? 'bottom' : 'left';
      this.oldticks = null;
      this.rendered = false;
      this.ticks = {};
      this.pts = {};
      this.make(params);
    }

    Axis.prototype.make = function(params) {
      this.domain = params.domain, this.factory = params.factory, this.scale = params.scale, this.guideSpec = params.guideSpec;
      this.oldticks = this.ticks;
      return this.ticks = poly.tick.make(this.domain, this.guideSpec, this.factory.tickType(this.domain));
    };

    Axis.prototype._renderline = function(renderer, axisDim) {
      var x, x1, x2, y, y1, y2;
      if (this.type === 'x') {
        y = sf.identity(axisDim.bottom);
        x1 = sf.identity(axisDim.left);
        x2 = sf.identity(axisDim.left + axisDim.width);
        return renderer.add({
          type: 'line',
          y: [y, y],
          x: [x1, x2]
        });
      } else {
        x = sf.identity(axisDim.left);
        y1 = sf.identity(axisDim.top);
        y2 = sf.identity(axisDim.top + axisDim.height);
        return renderer.add({
          type: 'line',
          x: [x, x],
          y: [y1, y2]
        });
      }
    };

    Axis.prototype.render = function(dim, renderer) {
      var added, axisDim, deleted, geomfn, kept, newpts, textfn, _ref,
        _this = this;
      axisDim = {
        top: dim.paddingTop + dim.guideTop,
        left: dim.paddingLeft + dim.guideLeft,
        bottom: dim.paddingTop + dim.guideTop + dim.chartHeight,
        width: dim.chartWidth,
        height: dim.chartHeight
      };
      if (!this.rendered) this._renderline(renderer, axisDim);
      _ref = poly.compare(_.keys(this.pts), _.keys(this.ticks)), deleted = _ref.deleted, kept = _ref.kept, added = _ref.added;
      geomfn = this._tickToGeomFn(axisDim);
      textfn = this._tickToTextFn(axisDim);
      newpts = {};
      _.each(kept, function(t) {
        return newpts[t] = _this._modify(renderer, _this.pts[t], _this.ticks[t], geomfn, textfn);
      });
      _.each(added, function(t) {
        return newpts[t] = _this._add(renderer, _this.ticks[t], geomfn, textfn);
      });
      _.each(deleted, function(t) {
        return _this._delete(renderer, _this.pts[t]);
      });
      this.pts = newpts;
      return this.rendered = true;
    };

    Axis.prototype._tickToGeomFn = function(axisDim) {
      if (this.type === 'x') {
        return function(tick) {
          return {
            type: 'line',
            x: [tick.location, tick.location],
            y: [sf.identity(axisDim.bottom), sf.identity(axisDim.bottom + 5)]
          };
        };
      }
      return function(tick) {
        return {
          type: 'line',
          x: [sf.identity(axisDim.left), sf.identity(axisDim.left - 5)],
          y: [tick.location, tick.location]
        };
      };
    };

    Axis.prototype._tickToTextFn = function(axisDim) {
      if (this.type === 'x') {
        return function(tick) {
          return {
            type: 'text',
            x: tick.location,
            y: sf.identity(axisDim.bottom + 15),
            text: tick.value,
            'text-anchor': 'middle'
          };
        };
      }
      return function(tick) {
        return {
          type: 'text',
          x: sf.identity(axisDim.left - 7),
          y: tick.location,
          text: tick.value,
          'text-anchor': 'end'
        };
      };
    };

    Axis.prototype._add = function(renderer, tick, geomfn, textfn) {
      var obj;
      obj = {};
      obj.tick = renderer.add(geomfn(tick));
      obj.text = renderer.add(textfn(tick));
      return obj;
    };

    Axis.prototype._delete = function(renderer, pt) {
      renderer.remove(pt.tick);
      return renderer.remove(pt.text);
    };

    Axis.prototype._modify = function(renderer, pt, tick, geomfn, textfn) {
      var obj;
      obj = [];
      obj.tick = renderer.animate(pt.tick, geomfn(tick));
      obj.text = renderer.animate(pt.text, textfn(tick));
      return obj;
    };

    return Axis;

  })(Guide);

  Legend = (function() {

    function Legend() {}

    Legend.prototype.render = function(paper, render, scales) {};

    return Legend;

  })();

  poly.guide = {};

  poly.guide.axis = function(params) {
    return new Axis(params);
  };

  this.poly = poly;

}).call(this);
(function() {
  var Area, Brewer, Gradient, Gradient2, Identity, Linear, Log, PositionScale, Scale, ScaleSet, Shape, aesthetics, poly,
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
      var inspec;
      inspec = function(a) {
        return guideSpec && (guideSpec[a] != null) && (guideSpec[a].scale != null);
      };
      this.guideSpec = guideSpec;
      this.factory = {
        x: inspec('x') ? guideSpec.x.scale : poly.scale.linear(),
        y: inspec('y') ? guideSpec.y.scale : poly.scale.linear()
      };
      this.ranges = ranges;
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
      this.scales = {};
      if (this.domainx) {
        this.scales.x = this.factory.x.construct(this.domainx, this.ranges.x);
      }
      if (this.domainy) {
        this.scales.y = this.factory.y.construct(this.domainy, this.ranges.y);
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
(function() {
  var Data, DataProcess, backendProcess, calculateMeta, calculateStats, extractDataSpec, filterFactory, filters, frontendProcess, poly, statistics, statsFactory, transformFactory, transforms,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  poly = this.poly || {};

  /*
  # GLOBALS
  */

  /*
  Generalized data object that either contains JSON format of a dataset,
  or knows how to retrieve data from some source.
  */

  Data = (function() {

    function Data(params) {
      this.url = params.url, this.json = params.json;
      this.frontEnd = !this.url;
    }

    Data.prototype.update = function(json) {
      return this.json = json;
    };

    return Data;

  })();

  poly.Data = Data;

  /*
  Wrapper around the data processing piece that keeps track of the kind of
  data processing to be done.
  */

  DataProcess = (function() {

    function DataProcess(layerSpec, strictmode) {
      this._wrap = __bind(this._wrap, this);      this.dataObj = layerSpec.data;
      this.initialSpec = extractDataSpec(layerSpec);
      this.prevSpec = null;
      this.strictmode = strictmode;
      this.statData = null;
      this.metaData = {};
    }

    DataProcess.prototype.reset = function(callback) {
      return this.make(this.initialSpec, callback);
    };

    DataProcess.prototype.make = function(spec, callback) {
      var dataSpec, wrappedCallback;
      dataSpec = extractDataSpec(spec);
      wrappedCallback = this._wrap(callback);
      if (this.dataObj.frontEnd) {
        if (this.strictmode) {
          return wrappedCallback(this.dataObj.json, {});
        } else {
          return frontendProcess(dataSpec, this.dataObj.json, wrappedCallback);
        }
      } else {
        if (this.strictmode) {
          throw new poly.StrictModeError();
        } else {
          return backendProcess(dataSpec, this.dataObj, wrappedCallback);
        }
      }
    };

    DataProcess.prototype._wrap = function(callback) {
      var _this = this;
      return function(data, metaData) {
        _this.statData = data;
        _this.metaData = metaData;
        return callback(_this.statData, _this.metaData);
      };
    };

    return DataProcess;

  })();

  poly.DataProcess = DataProcess;

  /*
  Temporary
  */

  poly.data = {};

  poly.data.process = function(dataObj, layerSpec, strictmode, callback) {
    var d;
    d = new DataProcess(layerSpec, strictmode);
    d.process(callback);
    return d;
  };

  /*
  TRANSFORMS
  ----------
  Key:value pair of available transformations to a function that creates that
  transformation. Also, a metadata description of the transformation is returned
  when appropriate. (e.g for binning)
  */

  transforms = {
    'bin': function(key, transSpec) {
      var binFn, binwidth, name;
      name = transSpec.name, binwidth = transSpec.binwidth;
      if (_.isNumber(binwidth)) {
        binFn = function(item) {
          return item[name] = binwidth * Math.floor(item[key] / binwidth);
        };
        return {
          trans: binFn,
          meta: {
            bw: binwidth,
            binned: true
          }
        };
      }
    },
    'lag': function(key, transSpec) {
      var i, lag, lagFn, lastn, name;
      name = transSpec.name, lag = transSpec.lag;
      lastn = (function() {
        var _results;
        _results = [];
        for (i = 1; 1 <= lag ? i <= lag : i >= lag; 1 <= lag ? i++ : i--) {
          _results.push(void 0);
        }
        return _results;
      })();
      lagFn = function(item) {
        lastn.push(item[key]);
        return item[name] = lastn.shift();
      };
      return {
        trans: lagFn,
        meta: void 0
      };
    }
  };

  /*
  Helper function to figures out which transformation to create, then creates it
  */

  transformFactory = function(key, transSpec) {
    return transforms[transSpec.trans](key, transSpec);
  };

  /*
  FILTERS
  ----------
  Key:value pair of available filtering operations to filtering function. The
  filtering function returns true iff the data item satisfies the filtering
  criteria.
  */

  filters = {
    'lt': function(x, value) {
      return x < value;
    },
    'le': function(x, value) {
      return x <= value;
    },
    'gt': function(x, value) {
      return x > value;
    },
    'ge': function(x, value) {
      return x >= value;
    },
    'in': function(x, value) {
      return __indexOf.call(value, x) >= 0;
    }
  };

  /*
  Helper function to figures out which filter to create, then creates it
  */

  filterFactory = function(filterSpec) {
    var filterFuncs;
    filterFuncs = [];
    _.each(filterSpec, function(spec, key) {
      return _.each(spec, function(value, predicate) {
        var filter;
        filter = function(item) {
          return filters[predicate](item[key], value);
        };
        return filterFuncs.push(filter);
      });
    });
    return function(item) {
      var f, _i, _len;
      for (_i = 0, _len = filterFuncs.length; _i < _len; _i++) {
        f = filterFuncs[_i];
        if (!f(item)) return false;
      }
      return true;
    };
  };

  /*
  STATISTICS
  ----------
  Key:value pair of available statistics operations to a function that creates
  the appropriate statistical function given the spec. Each statistics function
  produces one atomic value for each group of data.
  */

  statistics = {
    sum: function(spec) {
      return function(values) {
        return _.reduce(_.without(values, void 0, null), (function(v, m) {
          return v + m;
        }), 0);
      };
    },
    count: function(spec) {
      return function(values) {
        return _.without(values, void 0, null).length;
      };
    },
    uniq: function(spec) {
      return function(values) {
        return (_.uniq(_.without(values, void 0, null))).length;
      };
    },
    min: function(spec) {
      return function(values) {
        return _.min(values);
      };
    },
    max: function(spec) {
      return function(values) {
        return _.max(values);
      };
    },
    median: function(spec) {
      return function(values) {
        return poly.median(values);
      };
    },
    box: function(spec) {
      return function(values) {
        var iqr, len, lowerBound, mid, q2, q4, quarter, sortedValues, splitValues, upperBound;
        len = values.length;
        mid = len / 2;
        sortedValues = _.sortBy(values, function(x) {
          return x;
        });
        quarter = Math.ceil(mid) / 2;
        if (quarter % 1 !== 0) {
          quarter = Math.floor(quarter);
          q2 = sortedValues[quarter];
          q4 = sortedValues[(len - 1) - quarter];
        } else {
          q2 = (sortedValues[quarter] + sortedValues[quarter - 1]) / 2;
          q4 = (sortedValues[len - quarter] + sortedValues[(len - quarter) - 1]) / 2;
        }
        iqr = q4 - q2;
        lowerBound = q2 - (1.5 * iqr);
        upperBound = q4 + (1.5 * iqr);
        splitValues = _.groupBy(sortedValues, function(v) {
          return v >= lowerBound && v <= upperBound;
        });
        return {
          q1: _.min(splitValues["true"]),
          q2: q2,
          q3: poly.median(sortedValues, true),
          q4: q4,
          q5: _.max(splitValues["true"]),
          outliers: splitValues["false"]
        };
      };
    }
  };

  /*
  Helper function to figures out which statistics to create, then creates it
  */

  statsFactory = function(statSpec) {
    return statistics[statSpec.stat](statSpec);
  };

  /*
  Calculate statistics
  */

  calculateStats = function(data, statSpecs) {
    var groupedData, statFuncs;
    statFuncs = {};
    _.each(statSpecs.stats, function(statSpec) {
      var key, name, statFn;
      key = statSpec.key, name = statSpec.name;
      statFn = statsFactory(statSpec);
      return statFuncs[name] = function(data) {
        return statFn(_.pluck(data, key));
      };
    });
    groupedData = poly.groupBy(data, statSpecs.group);
    return _.map(groupedData, function(data) {
      var rep;
      rep = {};
      _.each(statSpecs.group, function(g) {
        return rep[g] = data[0][g];
      });
      _.each(statFuncs, function(stats, name) {
        return rep[name] = stats(data);
      });
      return rep;
    });
  };

  /*
  META
  ----
  Calculations of meta properties including sorting and limiting based on the
  values of statistical calculations
  */

  calculateMeta = function(key, metaSpec, data) {
    var asc, comparator, limit, multiplier, sort, stat, statSpec, values;
    sort = metaSpec.sort, stat = metaSpec.stat, limit = metaSpec.limit, asc = metaSpec.asc;
    if (stat) {
      statSpec = {
        stats: [stat],
        group: [key]
      };
      data = calculateStats(data, statSpec);
    }
    multiplier = asc ? 1 : -1;
    comparator = function(a, b) {
      if (a[sort] === b[sort]) return 0;
      if (a[sort] >= b[sort]) return 1 * multiplier;
      return -1 * multiplier;
    };
    data.sort(comparator);
    if (limit) data = data.slice(0, (limit - 1) + 1 || 9e9);
    values = _.uniq(_.pluck(data, key));
    return {
      meta: {
        levels: values,
        sorted: true
      },
      filter: {
        "in": values
      }
    };
  };

  /*
  GENERAL PROCESSING
  ------------------
  Coordinating the actual work being done
  */

  /*
  Given a layer spec, extract the data calculations that needs to be done.
  */

  extractDataSpec = function(layerSpec) {
    return {};
  };

  /*
  Perform the necessary computation in the front end
  */

  frontendProcess = function(dataSpec, rawData, callback) {
    var addMeta, additionalFilter, data, metaData;
    data = _.clone(rawData);
    metaData = {};
    addMeta = function(key, meta) {
      var _ref;
      return _.extend((_ref = metaData[key]) != null ? _ref : {}, meta);
    };
    if (dataSpec.trans) {
      _.each(dataSpec.trans, function(transSpec, key) {
        var meta, trans, _ref;
        _ref = transformFactory(key, transSpec), trans = _ref.trans, meta = _ref.meta;
        _.each(data, function(d) {
          return trans(d);
        });
        return addMeta(transSpec.name, meta);
      });
    }
    if (dataSpec.filter) data = _.filter(data, filterFactory(dataSpec.filter));
    if (dataSpec.meta) {
      additionalFilter = {};
      _.each(dataSpec.meta, function(metaSpec, key) {
        var filter, meta, _ref;
        _ref = calculateMeta(key, metaSpec, data), meta = _ref.meta, filter = _ref.filter;
        additionalFilter[key] = filter;
        return addMeta(key, meta);
      });
      data = _.filter(data, filterFactory(additionalFilter));
    }
    if (dataSpec.stats) data = calculateStats(data, dataSpec.stats);
    return callback(data, metaData);
  };

  /*
  Perform the necessary computation in the backend
  */

  backendProcess = function(dataSpec, rawData, callback) {
    return console.log('backendProcess');
  };

  /*
  For debug purposes only
  */

  poly.data.frontendProcess = frontendProcess;

  /*
  # EXPORT
  */

  this.poly = poly;

}).call(this);
(function() {
  var Bar, Layer, Line, Point, aesthetics, defaults, poly, sf,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  poly = this.poly || {};

  aesthetics = poly["const"].aes;

  sf = poly["const"].scaleFns;

  defaults = {
    'x': sf.novalue(),
    'y': sf.novalue(),
    'color': 'steelblue',
    'size': 1,
    'opacity': 0.7,
    'shape': 1
  };

  poly.layer = {};

  /*
  Turns a 'non-strict' layer spec to a strict one. Specifically, the function
  (1) wraps aes mapping defined by a string in an object: "col" -> {var: "col"}
  (2) puts all the level/min/max filtering into the "filter" group
  See the layer spec definition for more information.
  */

  poly.layer.toStrictMode = function(spec) {
    _.each(aesthetics, function(aes) {
      if (spec[aes] && _.isString(spec[aes])) {
        return spec[aes] = {
          "var": spec[aes]
        };
      }
    });
    return spec;
  };

  /*
  Public interface to making different layer types.
  */

  poly.layer.make = function(layerSpec, strictmode) {
    switch (layerSpec.type) {
      case 'point':
        return new Point(layerSpec, strictmode);
      case 'line':
        return new Line(layerSpec, strictmode);
      case 'bar':
        return new Bar(layerSpec, strictmode);
    }
  };

  /*
  Base class for all layers
  */

  Layer = (function() {

    Layer.prototype.defaults = defaults;

    function Layer(layerSpec, strict) {
      this.render = __bind(this.render, this);
      this._makeMappings = __bind(this._makeMappings, this);
      this.reset = __bind(this.reset, this);      this.initialSpec = poly.layer.toStrictMode(layerSpec);
      this.prevSpec = null;
      this.dataprocess = new poly.DataProcess(this.initialSpec, strict);
      this.pts = {};
    }

    Layer.prototype.reset = function() {
      return this.make(this.initialSpec);
    };

    Layer.prototype._makeMappings = function(spec) {
      var aes, _i, _len, _results;
      this.mapping = {};
      this.consts = {};
      _results = [];
      for (_i = 0, _len = aesthetics.length; _i < _len; _i++) {
        aes = aesthetics[_i];
        if (spec[aes]) {
          if (spec[aes]["var"]) this.mapping[aes] = spec[aes]["var"];
          if (spec[aes]["const"]) {
            _results.push(this.consts[aes] = spec[aes]["const"]);
          } else {
            _results.push(void 0);
          }
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    Layer.prototype.make = function(layerSpec, callback) {
      var spec,
        _this = this;
      spec = poly.layer.toStrictMode(layerSpec);
      this._makeMappings(spec);
      this.dataprocess.make(spec, function(statData, metaData) {
        _this.statData = statData;
        _this.meta = metaData;
        _this._calcGeoms();
        return callback();
      });
      return this.prevSpec = spec;
    };

    Layer.prototype._calcGeoms = function() {
      return this.geoms = {};
    };

    Layer.prototype.render = function(render) {
      var added, deleted, kept, newpts, _ref,
        _this = this;
      newpts = {};
      _ref = poly.compare(_.keys(this.pts), _.keys(this.geoms)), deleted = _ref.deleted, kept = _ref.kept, added = _ref.added;
      _.each(deleted, function(id) {
        return _this._delete(render, _this.pts[id]);
      });
      _.each(added, function(id) {
        return newpts[id] = _this._add(render, _this.geoms[id]);
      });
      _.each(kept, function(id) {
        return newpts[id] = _this._modify(render, _this.pts[id], _this.geoms[id]);
      });
      return this.pts = newpts;
    };

    Layer.prototype._delete = function(render, points) {
      return _.each(points, function(pt, id2) {
        return render.remove(pt);
      });
    };

    Layer.prototype._modify = function(render, points, geom) {
      var objs;
      objs = {};
      _.each(geom.marks, function(mark, id2) {
        return objs[id2] = render.animate(points[id2], mark, geom.evtData);
      });
      return objs;
    };

    Layer.prototype._add = function(render, geom) {
      var objs;
      objs = {};
      _.each(geom.marks, function(mark, id2) {
        return objs[id2] = render.add(mark, geom.evtData);
      });
      return objs;
    };

    Layer.prototype._getValue = function(item, aes) {
      if (this.mapping[aes]) return item[this.mapping[aes]];
      if (this.consts[aes]) return sf.identity(this.consts[aes]);
      return sf.identity(this.defaults[aes]);
    };

    Layer.prototype._getIdFunc = function() {
      var _this = this;
      if (this.mapping['id'] != null) {
        return function(item) {
          return _this._getValue(item, 'id');
        };
      } else {
        return poly.counter();
      }
    };

    return Layer;

  })();

  Point = (function(_super) {

    __extends(Point, _super);

    function Point() {
      Point.__super__.constructor.apply(this, arguments);
    }

    Point.prototype._calcGeoms = function() {
      var idfn,
        _this = this;
      idfn = this._getIdFunc();
      this.geoms = {};
      return _.each(this.statData, function(item) {
        var evtData;
        evtData = {};
        _.each(item, function(v, k) {
          return evtData[k] = {
            "in": [v]
          };
        });
        return _this.geoms[idfn(item)] = {
          marks: {
            0: {
              type: 'circle',
              x: _this._getValue(item, 'x'),
              y: _this._getValue(item, 'y'),
              color: _this._getValue(item, 'color')
            }
          },
          evtData: evtData
        };
      });
    };

    return Point;

  })(Layer);

  Line = (function(_super) {

    __extends(Line, _super);

    function Line() {
      Line.__super__.constructor.apply(this, arguments);
    }

    Line.prototype._calcGeoms = function() {
      var datas, group, idfn, k,
        _this = this;
      group = (function() {
        var _i, _len, _ref, _results;
        _ref = _.without(_.keys(this.mapping), 'x', 'y');
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          k = _ref[_i];
          _results.push(this.mapping[k]);
        }
        return _results;
      }).call(this);
      datas = poly.groupBy(this.statData, group);
      idfn = this._getIdFunc();
      this.geoms = {};
      return _.each(datas, function(data) {
        var evtData, item, sample;
        sample = data[0];
        evtData = {};
        _.each(group, function(key) {
          return evtData[key] = {
            "in": [sample[key]]
          };
        });
        return _this.geoms[idfn(sample)] = {
          marks: {
            0: {
              type: 'line',
              x: (function() {
                var _i, _len, _results;
                _results = [];
                for (_i = 0, _len = data.length; _i < _len; _i++) {
                  item = data[_i];
                  _results.push(this._getValue(item, 'x'));
                }
                return _results;
              }).call(_this),
              y: (function() {
                var _i, _len, _results;
                _results = [];
                for (_i = 0, _len = data.length; _i < _len; _i++) {
                  item = data[_i];
                  _results.push(this._getValue(item, 'y'));
                }
                return _results;
              }).call(_this),
              color: _this._getValue(sample, 'color')
            }
          },
          evtData: evtData
        };
      });
    };

    return Line;

  })(Layer);

  Bar = (function(_super) {

    __extends(Bar, _super);

    function Bar() {
      Bar.__super__.constructor.apply(this, arguments);
    }

    Bar.prototype._calcGeoms = function() {
      var datas, group, idfn,
        _this = this;
      group = this.mapping.x != null ? [this.mapping.x] : [];
      datas = poly.groupBy(this.statData, group);
      _.each(datas, function(data) {
        var tmp, yval;
        tmp = 0;
        yval = _this.mapping.y != null ? (function(item) {
          return item[_this.mapping.y];
        }) : function(item) {
          return 0;
        };
        return _.each(data, function(item) {
          item.$lower = tmp;
          tmp += yval(item);
          return item.$upper = tmp;
        });
      });
      idfn = this._getIdFunc();
      this.geoms = {};
      return _.each(this.statData, function(item) {
        var evtData;
        evtData = {};
        _.each(item, function(v, k) {
          if (k !== 'y') {
            return evtData[k] = {
              "in": [v]
            };
          }
        });
        return _this.geoms[idfn(item)] = {
          marks: {
            0: {
              type: 'rect',
              x1: sf.lower(_this._getValue(item, 'x')),
              x2: sf.upper(_this._getValue(item, 'x')),
              y1: item.$lower,
              y2: item.$upper,
              fill: _this._getValue(item, 'color')
            }
          }
        };
      });
    };

    return Bar;

  })(Layer);

  /*
  # EXPORT
  */

  this.poly = poly;

}).call(this);
(function() {
  var poly;

  poly = this.poly || {};

  /*
  # GLOBALS
  */

  poly.dim = {};

  poly.dim.make = function(spec, ticks) {
    return {
      width: 360,
      height: 360,
      chartWidth: 300,
      chartHeight: 300,
      paddingLeft: 10,
      paddingRight: 10,
      paddingTop: 10,
      paddingBottom: 10,
      guideLeft: 20,
      guideRight: 10,
      guideTop: 10,
      guideBottom: 20
    };
  };

  poly.dim.guess = function(spec) {
    return {
      width: 360,
      height: 360,
      chartWidth: 300,
      chartHeight: 300,
      paddingLeft: 10,
      paddingRight: 10,
      paddingTop: 10,
      paddingBottom: 10,
      guideLeft: 20,
      guideRight: 10,
      guideTop: 10,
      guideBottom: 20
    };
  };

  poly.dim.clipping = function(dim) {
    var gb, gl, gt, h, pl, pt, w;
    pl = dim.paddingLeft;
    gl = dim.guideLeft;
    pt = dim.paddingTop;
    gt = dim.guideTop;
    gb = dim.guideBottom;
    w = dim.chartWidth;
    h = dim.chartHeight;
    return {
      main: [pl + gl, pt + gt, w, h],
      left: [pl, pt, gl + 1, gt + h + gb + 1],
      bottom: [pl, pt + gt + h - 1, gl + w + 1, gb + 1]
    };
  };

  poly.dim.ranges = function(dim) {
    return {
      x: {
        min: dim.paddingLeft + dim.guideLeft,
        max: dim.paddingLeft + dim.guideLeft + dim.chartWidth
      },
      y: {
        min: dim.paddingTop + dim.guideTop + dim.chartHeight,
        max: dim.paddingTop + dim.guideTop
      }
    };
  };

  /*
  # CLASSES
  */

  /*
  # EXPORT
  */

  this.poly = poly;

}).call(this);
(function() {
  var poly, renderer, _makePath;

  poly = this.poly || {};

  /*
  # GLOBALS
  */

  poly.paper = function(dom, w, h) {
    return Raphael(dom, w, h);
  };

  /*
  Helper function for rendering all the geoms of an object
  
  TODO: 
  - make add & remove animations
  - make everything animateWith some standard object
  */

  poly.render = function(id, paper, scales, clipping) {
    return {
      add: function(mark, evtData) {
        var pt;
        pt = renderer[mark.type].render(paper, scales, mark);
        pt.attr('clip-rect', clipping);
        pt.click(function() {
          return eve(id + ".click", this, evtData);
        });
        pt.hover(function() {
          return eve(id + ".hover", this, evtData);
        });
        return pt;
      },
      remove: function(pt) {
        return pt.remove();
      },
      animate: function(pt, mark, evtData) {
        var attr;
        attr = renderer[mark.type].attr(scales, mark);
        pt.animate(attr, 300);
        pt.unclick();
        pt.click(function() {
          return eve(id + ".click", this, evtData);
        });
        pt.unhover();
        pt.hover(function() {
          return eve(id + ".hover", this, evtData);
        });
        return pt;
      }
    };
  };

  renderer = {
    circle: {
      render: function(paper, scales, mark) {
        var pt;
        pt = paper.circle();
        _.each(renderer.circle.attr(scales, mark), function(v, k) {
          return pt.attr(k, v);
        });
        return pt;
      },
      attr: function(scales, mark) {
        return {
          cx: scales.x(mark.x),
          cy: scales.y(mark.y),
          r: 10,
          fill: 'black'
        };
      },
      animate: function(pt, scales, mark) {
        return pt.animate(attr);
      }
    },
    line: {
      render: function(paper, scales, mark) {
        var pt;
        pt = paper.path();
        _.each(renderer.line.attr(scales, mark), function(v, k) {
          return pt.attr(k, v);
        });
        return pt;
      },
      attr: function(scales, mark) {
        var xs, ys;
        xs = _.map(mark.x, scales.x);
        ys = _.map(mark.y, scales.y);
        return {
          path: _makePath(xs, ys),
          stroke: 'black'
        };
      },
      animate: function(pt, scales, mark) {
        return pt.animate(attr);
      }
    },
    hline: {
      render: function(paper, scales, mark) {
        var pt;
        pt = paper.path();
        _.each(renderer.hline.attr(scales, mark), function(v, k) {
          return pt.attr(k, v);
        });
        return pt;
      },
      attr: function(scales, mark) {
        var y;
        y = scales.y(mark.y);
        return {
          path: _makePath([0, 100000], [y, y]),
          stroke: 'black',
          'stroke-width': '1px'
        };
      },
      animate: function(pt, scales, mark) {
        return pt.animate(attr);
      }
    },
    vline: {
      render: function(paper, scales, mark) {
        var pt;
        pt = paper.path();
        _.each(renderer.vline.attr(scales, mark), function(v, k) {
          return pt.attr(k, v);
        });
        return pt;
      },
      attr: function(scales, mark) {
        var x;
        x = scales.x(mark.x);
        return {
          path: _makePath([x, x], [0, 100000]),
          stroke: 'black',
          'stroke-width': '1px'
        };
      },
      animate: function(pt, scales, mark) {
        return pt.animate(attr);
      }
    },
    text: {
      render: function(paper, scales, mark) {
        var pt;
        pt = paper.text();
        _.each(renderer.text.attr(scales, mark), function(v, k) {
          return pt.attr(k, v);
        });
        return pt;
      },
      attr: function(scales, mark) {
        var _ref;
        return {
          x: scales.x(mark.x),
          y: scales.y(mark.y),
          text: scales.text != null ? scales.text(mark.text) : mark.text,
          'text-anchor': (_ref = mark['text-anchor']) != null ? _ref : 'left',
          r: 10,
          fill: 'black'
        };
      },
      animate: function(pt, scales, mark) {
        return pt.animate(attr);
      }
    }
  };

  _makePath = function(xs, ys) {
    var str;
    str = '';
    _.each(xs, function(x, i) {
      var y;
      y = ys[i];
      if (str === '') {
        return str += 'M' + x + ' ' + y;
      } else {
        return str += ' L' + x + ' ' + y;
      }
    });
    return str + ' Z';
  };

}).call(this);
(function() {
  var Graph, poly,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  poly = this.poly || {};

  Graph = (function() {

    function Graph(spec) {
      this._legacy = __bind(this._legacy, this);
      this.render = __bind(this.render, this);
      this.merge = __bind(this.merge, this);
      this.reset = __bind(this.reset, this);      this.graphId = _.uniqueId('graph_');
      this.layers = null;
      this.scaleSet = null;
      this.axes = null;
      this.legends = null;
      this.dims = null;
      this.paper = null;
      this.initial_spec = spec;
      this.make(spec);
    }

    Graph.prototype.reset = function() {
      return this.make(this.initial_spec);
    };

    Graph.prototype.make = function(spec) {
      var merge;
      this.spec = spec;
      if (spec.layers == null) spec.layers = [];
      if (this.layers == null) this.layers = this._makeLayers(this.spec);
      merge = _.after(this.layers.length, this.merge);
      return _.each(this.layers, function(layerObj, id) {
        return layerObj.make(spec.layers[id], merge);
      });
    };

    Graph.prototype.merge = function() {
      var domains;
      domains = this._makeDomains(this.spec, this.layers);
      if (this.scaleSet != null) {
        this.scaleSet.setDomains(domains);
      } else {
        this.scaleSet = this._makeScaleSet(this.spec, domains);
      }
      if (this.dims == null) {
        this.dims = this._makeDimensions(this.spec, this.scaleSet);
      }
      if (this.ranges == null) this.ranges = poly.dim.ranges(this.dims);
      this.scaleSet.setRanges(this.ranges);
      return this._legacy(domains);
    };

    Graph.prototype.render = function(dom) {
      var axes, clipping, renderer, scales,
        _this = this;
      if (this.paper == null) {
        this.paper = this._makePaper(dom, this.dims.width, this.dims.height);
      }
      scales = this.scaleSet.getScaleFns();
      clipping = poly.dim.clipping(this.dims);
      renderer = poly.render(this.graphId, this.paper, scales, clipping.main);
      _.each(this.layers, function(layer) {
        return layer.render(renderer);
      });
      axes = this.scaleSet.getAxes();
      axes.y.render(this.dims, poly.render(this.graphId, this.paper, scales, clipping.left));
      return axes.x.render(this.dims, poly.render(this.graphId, this.paper, scales, clipping.bottom));
    };

    Graph.prototype._makeLayers = function(spec) {
      return _.map(spec.layers, function(layerSpec) {
        return poly.layer.make(layerSpec, spec.strict);
      });
    };

    Graph.prototype._makeDomains = function(spec, layers) {
      var domains;
      domains = {};
      if (spec.guides) {
        if (spec.guides == null) spec.guides = {};
        domains = poly.domain.make(layers, spec.guides, spec.strict);
      }
      return domains;
    };

    Graph.prototype._makeScaleSet = function(spec, domains) {
      var tmpRanges;
      tmpRanges = poly.dim.ranges(poly.dim.guess(spec));
      return poly.scale.make(spec.guides, domains, tmpRanges);
    };

    Graph.prototype._makeDimensions = function(spec, scaleSet) {
      return poly.dim.make(spec, scaleSet.getAxes(), scaleSet.getLegends());
    };

    Graph.prototype._makePaper = function(dom, width, height) {
      return poly.paper(document.getElementById(dom), width, height);
    };

    Graph.prototype._legacy = function(domains) {
      var axes,
        _this = this;
      this.domains = domains;
      this.scales = this.scaleSet.getScaleFns();
      axes = this.scaleSet.getAxes();
      this.ticks = {};
      return _.each(axes, function(v, k) {
        return _this.ticks[k] = v.ticks;
      });
    };

    return Graph;

  })();

  poly.chart = function(spec) {
    return new Graph(spec);
  };

  this.poly = poly;

}).call(this);
