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

  poly.render = function(geoms, paper, scales) {
    return _.each(geoms, function(geom) {
      var evtData;
      evtData = geom.evtData;
      return _.each(geom.geoms, function(mark) {
        return poly.point(mark, paper, scales);
      });
    });
  };

  /*
  Rendering a single point
  */

  poly.point = function(mark, paper, scales) {
    var pt;
    pt = paper.circle();
    pt.attr('cx', scales.x(mark.x));
    pt.attr('cy', scales.y(mark.y));
    return pt.attr('r', 5);
  };

}).call(this);
