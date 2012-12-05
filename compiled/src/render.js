(function() {
  var Circle, CircleRect, Line, Rect, Renderer, Text, poly, renderer,
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

  poly.render = function(id, paper, scales, coord, mayflip, clipping) {
    return {
      add: function(mark, evtData) {
        var pt;
        pt = renderer[coord.type][mark.type].render(paper, scales, coord, mark, mayflip);
        if (clipping != null) pt.attr('clip-rect', clipping);
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
        renderer[coord.type][mark.type].animate(pt, scales, coord, mark, mayflip);
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

    Renderer.prototype.render = function(paper, scales, coord, mark, mayflip) {
      var pt;
      pt = this._make(paper);
      _.each(this.attr(scales, coord, mark, mayflip), function(v, k) {
        return pt.attr(k, v);
      });
      return pt;
    };

    Renderer.prototype._make = function() {
      throw new poly.NotImplemented();
    };

    Renderer.prototype.animate = function(pt, scales, coord, mark, mayflip) {
      return pt.animate(this.attr(scales, coord, mark, mayflip), 300);
    };

    Renderer.prototype.attr = function(scales, coord, mark, mayflip) {
      throw new poly.NotImplemented();
    };

    Renderer.prototype._makePath = function(xs, ys, type) {
      var path;
      if (type == null) type = 'L';
      path = _.map(xs, function(x, i) {
        return (i === 0 ? 'M' : type) + x + ' ' + ys[i];
      });
      return path.join(' ');
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

    Circle.prototype.attr = function(scales, coord, mark, mayflip) {
      var stroke, x, y, _ref, _ref2;
      _ref = coord.getXY(mayflip, scales, mark), x = _ref.x, y = _ref.y;
      stroke = mark.stroke ? this._maybeApply(scales.stroke, mark.stroke) : this._maybeApply(scales.color, mark.color);
      return {
        cx: x,
        cy: y,
        r: this._maybeApply(scales.size, mark.size),
        fill: this._maybeApply(scales.color, mark.color),
        stroke: stroke,
        title: 'omgthisiscool!',
        'stroke-width': (_ref2 = mark['stroke-width']) != null ? _ref2 : '0px'
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

    Line.prototype.attr = function(scales, coord, mark, mayflip) {
      var x, y, _ref;
      _ref = coord.getXY(mayflip, scales, mark), x = _ref.x, y = _ref.y;
      return {
        path: this._makePath(x, y),
        stroke: 'black'
      };
    };

    return Line;

  })(Renderer);

  Rect = (function(_super) {

    __extends(Rect, _super);

    function Rect() {
      Rect.__super__.constructor.apply(this, arguments);
    }

    Rect.prototype._make = function(paper) {
      return paper.rect();
    };

    Rect.prototype.attr = function(scales, coord, mark, mayflip) {
      var x, y, _ref;
      _ref = coord.getXY(mayflip, scales, mark), x = _ref.x, y = _ref.y;
      return {
        x: _.min(x),
        y: _.min(y),
        width: Math.abs(x[1] - x[0]),
        height: Math.abs(y[1] - y[0]),
        fill: this._maybeApply(scales.color, mark.color),
        stroke: this._maybeApply(scales.color, mark.color),
        'stroke-width': '0px'
      };
    };

    return Rect;

  })(Renderer);

  CircleRect = (function(_super) {

    __extends(CircleRect, _super);

    function CircleRect() {
      CircleRect.__super__.constructor.apply(this, arguments);
    }

    CircleRect.prototype._make = function(paper) {
      return paper.path();
    };

    CircleRect.prototype.attr = function(scales, coord, mark, mayflip) {
      debugger;
      var large, path, r, t, x, x0, x1, y, y0, y1, _ref, _ref2, _ref3;
      _ref = mark.x, x0 = _ref[0], x1 = _ref[1];
      _ref2 = mark.y, y0 = _ref2[0], y1 = _ref2[1];
      mark.x = [x0, x0, x1, x1];
      mark.y = [y0, y1, y1, y0];
      _ref3 = coord.getXY(mayflip, scales, mark), x = _ref3.x, y = _ref3.y, r = _ref3.r, t = _ref3.t;
      large = Math.abs(t[1] - t[0]) > Math.PI ? 1 : 0;
      path = "M " + x[0] + " " + y[0] + " A " + r[0] + " " + r[0] + " 0 " + large + " 1 " + x[1] + " " + y[1];
      large = Math.abs(t[3] - t[2]) > Math.PI ? 1 : 0;
      path += "L " + x[2] + " " + y[2] + " A " + r[2] + " " + r[2] + " 0 " + large + " 0 " + x[3] + " " + y[3] + " Z";
      return {
        path: path,
        fill: this._maybeApply(scales.color, mark.color),
        stroke: this._maybeApply(scales.color, mark.color),
        'stroke-width': '0px'
      };
    };

    return CircleRect;

  })(Renderer);

  "class HLine extends Renderer # for both cartesian & polar?\n  _make: (paper) -> paper.path()\n  attr: (scales, coord, mark) ->\n    y = scales.y mark.y\n    path: @_makePath([0, 100000], [y, y])\n    stroke: 'black'\n    'stroke-width': '1px'\n\nclass VLine extends Renderer # for both cartesian & polar?\n  _make: (paper) -> paper.path()\n  attr: (scales, coord, mark) ->\n    x = scales.x mark.x\n    path: @_makePath([x, x], [0, 100000])\n    stroke: 'black'\n    'stroke-width': '1px'";

  Text = (function(_super) {

    __extends(Text, _super);

    function Text() {
      Text.__super__.constructor.apply(this, arguments);
    }

    Text.prototype._make = function(paper) {
      return paper.text();
    };

    Text.prototype.attr = function(scales, coord, mark, mayflip) {
      var m, x, y, _ref, _ref2;
      _ref = coord.getXY(mayflip, scales, mark), x = _ref.x, y = _ref.y;
      m = {
        x: x,
        y: y,
        text: this._maybeApply(scales.text, mark.text),
        'text-anchor': (_ref2 = mark['text-anchor']) != null ? _ref2 : 'left',
        r: 10,
        fill: 'black'
      };
      if (mark.transform != null) m.transform = mark.transform;
      return m;
    };

    return Text;

  })(Renderer);

  renderer = {
    cartesian: {
      circle: new Circle(),
      line: new Line(),
      text: new Text(),
      rect: new Rect()
    },
    polar: {
      circle: new Circle(),
      line: new Line(),
      text: new Text(),
      rect: new CircleRect()
    }
  };

}).call(this);
