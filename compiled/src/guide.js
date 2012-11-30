(function() {
  var Axis, Guide, Legend, poly, sf,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  poly = this.poly || {};

  sf = poly["const"].scaleFns;

  Guide = (function() {

    function Guide(params) {
      this.scales = params.scales, this.guideSpec = params.guideSpec;
      this.position = 'right';
      this.ticks = [];
    }

    Guide.prototype.getWidth = function() {};

    Guide.prototype.getHeight = function() {};

    Guide.prototype.render = function(paper, render, scales) {
      throw new poly.NotImplemented("render is not implemented");
    };

    return Guide;

  })();

  Axis = (function(_super) {

    __extends(Axis, _super);

    function Axis(params) {
      this._tickToTextFn = __bind(this._tickToTextFn, this);
      this._tickToGeomFn = __bind(this._tickToGeomFn, this);
      this.render = __bind(this.render, this);
      this._renderline = __bind(this._renderline, this);
      this.make = __bind(this.make, this);      this.type = params.type;
      this.position = this.type === 'x' ? 'bottom' : 'left';
      this.oldticks = null;
      this.rendered = false;
      this.ticks = {};
      this.pts = {};
      this.make(params);
    }

    Axis.prototype.make = function(params) {
      this.domain = params.domain, this.factory = params.factory, this.scale = params.scale, this.guideSpec = params.guideSpec;
      this.oldticks = this.ticks;
      return this.ticks = poly.tick.make(this.domain, this.guideSpec, this.factory.tickType(this.domain));
    };

    Axis.prototype._renderline = function(renderer, axisDim) {
      var x, x1, x2, y, y1, y2;
      if (this.type === 'x') {
        y = sf.identity(axisDim.bottom);
        x1 = sf.identity(axisDim.left);
        x2 = sf.identity(axisDim.left + axisDim.width);
        return renderer.add({
          type: 'line',
          y: [y, y],
          x: [x1, x2]
        });
      } else {
        x = sf.identity(axisDim.left);
        y1 = sf.identity(axisDim.top);
        y2 = sf.identity(axisDim.top + axisDim.height);
        return renderer.add({
          type: 'line',
          x: [x, x],
          y: [y1, y2]
        });
      }
    };

    Axis.prototype.render = function(dim, renderer) {
      var added, axisDim, deleted, geomfn, kept, newpts, textfn, _ref,
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
      geomfn = this._tickToGeomFn(axisDim);
      textfn = this._tickToTextFn(axisDim);
      newpts = {};
      _.each(kept, function(t) {
        return newpts[t] = _this._modify(renderer, _this.pts[t], _this.ticks[t], geomfn, textfn);
      });
      _.each(added, function(t) {
        return newpts[t] = _this._add(renderer, _this.ticks[t], geomfn, textfn);
      });
      _.each(deleted, function(t) {
        return _this._delete(renderer, _this.pts[t]);
      });
      this.pts = newpts;
      return this.rendered = true;
    };

    Axis.prototype._tickToGeomFn = function(axisDim) {
      if (this.type === 'x') {
        return function(tick) {
          return {
            type: 'line',
            x: [tick.location, tick.location],
            y: [sf.identity(axisDim.bottom), sf.identity(axisDim.bottom + 5)]
          };
        };
      }
      return function(tick) {
        return {
          type: 'line',
          x: [sf.identity(axisDim.left), sf.identity(axisDim.left - 5)],
          y: [tick.location, tick.location]
        };
      };
    };

    Axis.prototype._tickToTextFn = function(axisDim) {
      if (this.type === 'x') {
        return function(tick) {
          return {
            type: 'text',
            x: tick.location,
            y: sf.identity(axisDim.bottom + 15),
            text: tick.value,
            'text-anchor': 'middle'
          };
        };
      }
      return function(tick) {
        return {
          type: 'text',
          x: sf.identity(axisDim.left - 7),
          y: tick.location,
          text: tick.value,
          'text-anchor': 'end'
        };
      };
    };

    Axis.prototype._add = function(renderer, tick, geomfn, textfn) {
      var obj;
      obj = {};
      obj.tick = renderer.add(geomfn(tick));
      obj.text = renderer.add(textfn(tick));
      return obj;
    };

    Axis.prototype._delete = function(renderer, pt) {
      renderer.remove(pt.tick);
      return renderer.remove(pt.text);
    };

    Axis.prototype._modify = function(renderer, pt, tick, geomfn, textfn) {
      var obj;
      obj = [];
      obj.tick = renderer.animate(pt.tick, geomfn(tick));
      obj.text = renderer.animate(pt.text, textfn(tick));
      return obj;
    };

    return Axis;

  })(Guide);

  Legend = (function() {

    function Legend() {}

    Legend.prototype.render = function(paper, render, scales) {};

    return Legend;

  })();

  poly.guide = {};

  poly.guide.axis = function(params) {
    return new Axis(params);
  };

  this.poly = poly;

}).call(this);
