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
