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
        xs = _.map(mark.x(scales.x));
        ys = _.map(mark.y(scales.y));
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
