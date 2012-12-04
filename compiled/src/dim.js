(function() {
  var poly;

  poly = this.poly || {};

  /*
  # GLOBALS
  */

  poly.dim = {};

  poly.dim.make = function(spec, axes, legends) {
    var d, dim, legend, maxheight, maxwidth, offset, _i, _len, _ref, _ref2, _ref3, _ref4, _ref5, _ref6;
    dim = {
      width: (_ref = spec.width) != null ? _ref : 400,
      height: (_ref2 = spec.height) != null ? _ref2 : 400,
      paddingLeft: (_ref3 = spec.paddingLeft) != null ? _ref3 : 10,
      paddingRight: (_ref4 = spec.paddingRight) != null ? _ref4 : 10,
      paddingTop: (_ref5 = spec.paddingTop) != null ? _ref5 : 10,
      paddingBottom: (_ref6 = spec.paddingBottom) != null ? _ref6 : 10,
      guideLeft: axes.y.getDimension().width + 5,
      guideBottom: axes.x.getDimension().height + 5,
      guideTop: 10,
      guideRight: 0
    };
    maxheight = dim.height - dim.guideTop - dim.paddingTop;
    maxwidth = 0;
    offset = {
      x: 0,
      y: 0
    };
    for (_i = 0, _len = legends.length; _i < _len; _i++) {
      legend = legends[_i];
      d = legend.getDimension();
      if (d.height + offset.y > maxheight) {
        offset.x += maxwidth + 5;
        offset.y = 0;
        maxwidth = 0;
      }
      if (d.width > maxwidth) maxwidth = d.width;
      offset.y += d.height;
    }
    dim.guideRight = offset.x + maxwidth;
    dim.chartHeight = dim.height - dim.paddingTop - dim.paddingBottom - dim.guideTop - dim.guideBottom;
    dim.chartWidth = dim.width - dim.paddingLeft - dim.paddingRight - dim.guideLeft - dim.guideRight;
    return dim;
  };

  poly.dim.guess = function(spec) {
    var _ref, _ref2, _ref3, _ref4, _ref5, _ref6;
    return {
      width: (_ref = spec.width) != null ? _ref : 400,
      height: (_ref2 = spec.height) != null ? _ref2 : 400,
      paddingLeft: (_ref3 = spec.paddingLeft) != null ? _ref3 : 10,
      paddingRight: (_ref4 = spec.paddingRight) != null ? _ref4 : 10,
      paddingTop: (_ref5 = spec.paddingTop) != null ? _ref5 : 10,
      paddingBottom: (_ref6 = spec.paddingBottom) != null ? _ref6 : 10,
      guideLeft: 30,
      guideRight: 40,
      guideTop: 10,
      guideBottom: 30
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
      main: [pl + gl, pt + gt, w, h]
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
