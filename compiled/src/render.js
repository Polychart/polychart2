(function() {
  var poly, renderer;

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
        pt.animate(attr);
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
    }
  };

}).call(this);
