(function() {
  var Axis, Guide, Legend, XAxis, YAxis, poly, sf,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  poly = this.poly || {};

  sf = poly["const"].scaleFns;

  Guide = (function() {

    function Guide() {}

    Guide.prototype.getWidth = function() {};

    Guide.prototype.getHeight = function() {};

    Guide.prototype.render = function(paper, render, scales) {
      throw new poly.NotImplemented("render is not implemented");
    };

    return Guide;

  })();

  Axis = (function(_super) {

    __extends(Axis, _super);

    function Axis() {
      this.render = __bind(this.render, this);
      this.make = __bind(this.make, this);      this.oldticks = null;
      this.rendered = false;
      this.ticks = {};
      this.pts = {};
    }

    Axis.prototype.make = function(params) {
      this.domain = params.domain, this.factory = params.factory, this.guideSpec = params.guideSpec;
      this.oldticks = this.ticks;
      return this.ticks = poly.tick.make(this.domain, this.guideSpec, this.factory.tickType(this.domain));
    };

    Axis.prototype.render = function(dim, renderer) {
      var added, axisDim, deleted, kept, newpts, _ref,
        _this = this;
      axisDim = {
        top: dim.paddingTop + dim.guideTop,
        left: dim.paddingLeft + dim.guideLeft,
        bottom: dim.paddingTop + dim.guideTop + dim.chartHeight,
        width: dim.chartWidth,
        height: dim.chartHeight
      };
      if (!this.rendered) this._renderline(renderer, axisDim);
      _ref = poly.compare(_.keys(this.pts), _.keys(this.ticks)), deleted = _ref.deleted, kept = _ref.kept, added = _ref.added;
      newpts = {};
      _.each(kept, function(t) {
        return newpts[t] = _this._modify(renderer, _this.pts[t], _this.ticks[t], axisDim);
      });
      _.each(added, function(t) {
        return newpts[t] = _this._add(renderer, _this.ticks[t], axisDim);
      });
      _.each(deleted, function(t) {
        return _this._delete(renderer, _this.pts[t]);
      });
      this.pts = newpts;
      return this.rendered = true;
    };

    Axis.prototype._add = function(renderer, tick, axisDim) {
      var obj;
      obj = {};
      obj.tick = renderer.add(this._makeTick(axisDim, tick));
      obj.text = renderer.add(this._makeText(axisDim, tick));
      return obj;
    };

    Axis.prototype._delete = function(renderer, pt) {
      renderer.remove(pt.tick);
      return renderer.remove(pt.text);
    };

    Axis.prototype._modify = function(renderer, pt, tick, axisDim) {
      var obj;
      obj = [];
      obj.tick = renderer.animate(pt.tick, this._makeTick(axisDim, tick));
      obj.text = renderer.animate(pt.text, this._makeText(axisDim, tick));
      return obj;
    };

    Axis.prototype._renderline = function() {
      throw new poly.NotImplemented();
    };

    Axis.prototype._makeTick = function() {
      throw new poly.NotImplemented();
    };

    Axis.prototype._makeText = function() {
      throw new poly.NotImplemented();
    };

    return Axis;

  })(Guide);

  XAxis = (function(_super) {

    __extends(XAxis, _super);

    function XAxis() {
      this._renderline = __bind(this._renderline, this);
      XAxis.__super__.constructor.apply(this, arguments);
    }

    XAxis.prototype._renderline = function(renderer, axisDim) {
      var x1, x2, y;
      y = sf.identity(axisDim.bottom);
      x1 = sf.identity(axisDim.left);
      x2 = sf.identity(axisDim.left + axisDim.width);
      return renderer.add({
        type: 'line',
        y: [y, y],
        x: [x1, x2]
      });
    };

    XAxis.prototype._makeTick = function(axisDim, tick) {
      return {
        type: 'line',
        x: [tick.location, tick.location],
        y: [sf.identity(axisDim.bottom), sf.identity(axisDim.bottom + 5)]
      };
    };

    XAxis.prototype._makeText = function(axisDim, tick) {
      return {
        type: 'text',
        x: tick.location,
        y: sf.identity(axisDim.bottom + 15),
        text: tick.value,
        'text-anchor': 'middle'
      };
    };

    return XAxis;

  })(Axis);

  YAxis = (function(_super) {

    __extends(YAxis, _super);

    function YAxis() {
      this._renderline = __bind(this._renderline, this);
      YAxis.__super__.constructor.apply(this, arguments);
    }

    YAxis.prototype._renderline = function(renderer, axisDim) {
      var x, y1, y2;
      x = sf.identity(axisDim.left);
      y1 = sf.identity(axisDim.top);
      y2 = sf.identity(axisDim.top + axisDim.height);
      return renderer.add({
        type: 'line',
        x: [x, x],
        y: [y1, y2]
      });
    };

    YAxis.prototype._makeTick = function(axisDim, tick) {
      return {
        type: 'line',
        x: [sf.identity(axisDim.left), sf.identity(axisDim.left - 5)],
        y: [tick.location, tick.location]
      };
    };

    YAxis.prototype._makeText = function(axisDim, tick) {
      return {
        type: 'text',
        x: sf.identity(axisDim.left - 7),
        y: tick.location,
        text: tick.value,
        'text-anchor': 'end'
      };
    };

    return YAxis;

  })(Axis);

  Legend = (function() {

    function Legend() {}

    Legend.prototype.render = function(paper, render, scales) {};

    return Legend;

  })();

  poly.guide = {};

  poly.guide.axis = function(type) {
    if (type === 'x') return new XAxis();
    return new YAxis();
  };

  this.poly = poly;

}).call(this);
