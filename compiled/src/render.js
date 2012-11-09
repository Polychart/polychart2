(function() {
  var poly;

  poly = this.poly || {};

  /*
  # GLOBALS
  */

  poly.paper = function(dom, w, h) {
    return Raphael(dom, w, h);
  };

  /*
  Helper function for rendering all the geoms of an object
  */

  poly.render = function(geoms, paper, scales, clipping) {
    return _.each(geoms, function(geom) {
      var evtData;
      evtData = geom.evtData;
      return _.each(geom.marks, function(mark) {
        return poly.point(mark, paper, scales, clipping);
      });
    });
  };

  /*
  Rendering a single point
  */

  poly.point = function(mark, paper, scales, clipping) {
    var pt;
    pt = paper.circle();
    pt.attr('cx', scales.x(mark.x));
    pt.attr('cy', scales.y(mark.y));
    pt.attr('r', 10);
    pt.attr('fill', 'black');
    return pt.attr('clip-rect', clipping);
  };

}).call(this);
