(function() {
  var Circle, HLine, Line, Renderer, Text, VLine, poly, renderer,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

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
        pt = renderer.cartesian[mark.type].render(paper, scales, mark);
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
        renderer.cartesian[mark.type].animate(pt, scales, mark);
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

  Renderer = (function() {

    function Renderer() {}

    Renderer.prototype.render = function(paper, scales, mark) {
      var pt;
      pt = this._make(paper);
      _.each(this.attr(scales, mark), function(v, k) {
        return pt.attr(k, v);
      });
      return pt;
    };

    Renderer.prototype._make = function() {
      throw new poly.NotImplemented();
    };

    Renderer.prototype.animate = function(pt, scales, mark) {
      return pt.animate(this.attr(scales, mark), 300);
    };

    Renderer.prototype.attr = function(scales, mark) {
      throw new poly.NotImplemented();
    };

    Renderer.prototype._makePath = function(xs, ys, type) {
      var path;
      if (type == null) type = 'L';
      path = _.map(xs, function(x, i) {
        return (i === 0 ? 'M' : type) + x + ' ' + ys[i];
      });
      return path.join(' ') + 'Z';
    };

    Renderer.prototype._maybeApply = function(scale, val) {
      if (scale != null) {
        return scale(val);
      } else if (_.isObject(val)) {
        return val.v;
      } else {
        return val;
      }
    };

    return Renderer;

  })();

  Circle = (function(_super) {

    __extends(Circle, _super);

    function Circle() {
      Circle.__super__.constructor.apply(this, arguments);
    }

    Circle.prototype._make = function(paper) {
      return paper.circle();
    };

    Circle.prototype.attr = function(scales, mark) {
      return {
        cx: scales.x(mark.x),
        cy: scales.y(mark.y),
        r: this._maybeApply(scales.size, mark.size),
        fill: this._maybeApply(scales.color, mark.color),
        stroke: this._maybeApply(scales.color, mark.color),
        'stroke-width': '0px'
      };
    };

    return Circle;

  })(Renderer);

  Line = (function(_super) {

    __extends(Line, _super);

    function Line() {
      Line.__super__.constructor.apply(this, arguments);
    }

    Line.prototype._make = function(paper) {
      return paper.path();
    };

    Line.prototype.attr = function(scales, mark) {
      var xs, ys;
      xs = _.map(mark.x, scales.x);
      ys = _.map(mark.y, scales.y);
      return {
        path: this._makePath(xs, ys),
        stroke: 'black'
      };
    };

    return Line;

  })(Renderer);

  HLine = (function(_super) {

    __extends(HLine, _super);

    function HLine() {
      HLine.__super__.constructor.apply(this, arguments);
    }

    HLine.prototype._make = function(paper) {
      return paper.path();
    };

    HLine.prototype.attr = function(scales, mark) {
      var y;
      y = scales.y(mark.y);
      return {
        path: this._makePath([0, 100000], [y, y]),
        stroke: 'black',
        'stroke-width': '1px'
      };
    };

    return HLine;

  })(Renderer);

  VLine = (function(_super) {

    __extends(VLine, _super);

    function VLine() {
      VLine.__super__.constructor.apply(this, arguments);
    }

    VLine.prototype._make = function(paper) {
      return paper.path();
    };

    VLine.prototype.attr = function(scales, mark) {
      var x;
      x = scales.x(mark.x);
      return {
        path: this._makePath([x, x], [0, 100000]),
        stroke: 'black',
        'stroke-width': '1px'
      };
    };

    return VLine;

  })(Renderer);

  Text = (function(_super) {

    __extends(Text, _super);

    function Text() {
      Text.__super__.constructor.apply(this, arguments);
    }

    Text.prototype._make = function(paper) {
      return paper.text();
    };

    Text.prototype.attr = function(scales, mark) {
      var _ref;
      return {
        x: scales.x(mark.x),
        y: scales.y(mark.y),
        text: this._maybeApply(scales.text, mark.text),
        'text-anchor': (_ref = mark['text-anchor']) != null ? _ref : 'left',
        r: 10,
        fill: 'black'
      };
    };

    return Text;

  })(Renderer);

  renderer = {
    cartesian: {
      circle: new Circle(),
      line: new Line(),
      hline: new HLine(),
      vline: new VLine(),
      text: new Text()
    },
    polar: {
      circle: new Circle(),
      line: new Line(),
      hline: new HLine(),
      vline: new VLine(),
      text: new Text()
    }
  };

}).call(this);
