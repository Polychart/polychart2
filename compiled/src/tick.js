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
    var formatter, numticks, t, tickfn, tickobjs, ticks, _i, _len, _ref;
    if (guideSpec.ticks != null) {
      ticks = guideSpec.ticks;
    } else {
      numticks = (_ref = guideSpec.numticks) != null ? _ref : 5;
      ticks = tickValues[type](domain, numticks);
    }
    if (guideSpec.labels) {
      formatter = function(x) {
        var _ref2;
        return (_ref2 = guideSpec.labels[x]) != null ? _ref2 : x;
      };
    } else if (guideSpec.formatter) {
      formatter = guideSpec.formatter;
    } else {
      formatter = poly["const"].formatter[type];
    }
    tickobjs = {};
    tickfn = tickFactory(formatter);
    for (_i = 0, _len = ticks.length; _i < _len; _i++) {
      t = ticks[_i];
      tickobjs[t] = tickfn(t);
    }
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
      this.location = params.location, this.value = params.value, this.index = params.index;
    }

    return Tick;

  })();

  /*
  Helper function for creating a function that creates ticks
  */

  tickFactory = function(formatter) {
    var i;
    i = 0;
    return function(value) {
      return new Tick({
        location: value,
        value: formatter(value),
        index: i++
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
      var current, max, min, step, ticks;
      min = domain.min, max = domain.max;
      step = (max - min) / numticks;
      step = step < 1.4 * 1 ? 'second' : step < 1.4 * 60 ? 'minute' : step < 1.4 * 60 * 60 ? 'hour' : step < 1.4 * 24 * 60 * 60 ? 'day' : step < 1.4 * 7 * 24 * 60 * 60 ? 'week' : step < 1.4 * 30 * 24 * 60 * 60 ? 'month' : 'year';
      ticks = [];
      current = moment.unix(min).startOf(step);
      while (current.unix() < max) {
        ticks.push(current.unix());
        current.add(step + 's', 1);
      }
      return ticks;
    }
  };

  /*
  # EXPORT
  */

  this.poly = poly;

}).call(this);
