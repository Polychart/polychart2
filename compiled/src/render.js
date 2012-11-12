(function() {
  var poly, renderPoint;

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

  poly.render = function(id, paper, scales, clipping) {
    return function(mark, evtData) {
      var pt;
      pt = null;
      switch (mark.type) {
        case 'point':
          pt = renderPoint(paper, scales, mark);
      }
      if (pt) {
        pt.attr('clip-rect', clipping);
        pt.click(function() {
          return eve(id + ".click", this, evtData);
        });
        pt.hover(function() {
          return eve(id + ".hover", this, evtData);
        });
      }
      return pt;
    };
  };

  renderPoint = function(paper, scales, mark) {
    var pt;
    pt = paper.circle();
    pt.attr('cx', scales.x(mark.x));
    pt.attr('cy', scales.y(mark.y));
    pt.attr('r', 10);
    return pt.attr('fill', 'black');
  };

}).call(this);
