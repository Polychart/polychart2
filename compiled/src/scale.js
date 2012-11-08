(function() {
  var aesthetics, makeScale, poly, scale;

  poly = this.poly || {};

  /*
  # CONSTANTS
  */

  aesthetics = poly["const"].aes;

  /*
  # GLOBALS
  */

  poly.scale = {};

  poly.scale.make = function(guideSpec, domains, dims) {
    var range, scales;
    scales = {};
    if (domains.x) {
      range = {
        type: 'num',
        min: 0,
        max: dims.chartWidth
      };
      scales.x = makeScale(domains.x, range);
    }
    if (domains.y) {
      range = {
        type: 'num',
        min: 0,
        max: dims.chartHeight
      };
      scales.y = makeScale(domains.y, range);
    }
    return scales;
  };

  /*
  # CLASSES
  */

  makeScale = function(domain, range) {
    if (domain.type === 'num' && range.type === 'num') {
      return scale.numeric(domain, range, 2);
    }
  };

  scale = {
    'numeric': function(domain, range, space) {
      var bw, m, x1, x2, y, y1, y2, _ref;
      _ref = [range.max, range.min, domain.max, domain.min], y2 = _ref[0], y1 = _ref[1], x2 = _ref[2], x1 = _ref[3];
      bw = domain.bw;
      m = (y2 - y1) / (x2 - x1);
      y = function(x) {
        return m * (x - x1) + y1;
      };
      return function(val) {
        if (_.isObject(val)) {
          if (value.t === 'scalefn') {
            if (value.f === 'upper') return y(val + bw) - space;
            if (value.f === 'lower') return y(val) + space;
            if (value.f === 'middle') return y(val + bw / 2);
          }
          console.log('wtf');
        }
        return y(val);
      };
    },
    'identity': function() {
      return function(x) {
        return x;
      };
    }
  };

  /*
  # EXPORT
  */

  this.poly = poly;

}).call(this);
