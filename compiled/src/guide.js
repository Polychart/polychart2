(function() {
  var Axis, Guide, Legend, poly, sf,
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
      this.domain = params.domain, this.factory = params.factory, this.scale = params.scale, this.guideSpec = params.guideSpec, this.type = params.type;
      this.position = this.type === 'x' ? 'bottom' : 'left';
      this.ticks = poly.tick.make(this.domain, this.scale, this.guideSpec, this.factory.tickType(this.domain));
    }

    Axis.prototype._renderHline = function(dim, renderer) {
      var hline;
      hline = {
        type: 'hline',
        y: sf.identity(dim.paddingTop + dim.guideTop + dim.chartHeight + 1)
      };
      return renderer.add(hline, {});
    };

    Axis.prototype._renderVline = function(dim, renderer) {
      var vline;
      vline = {
        type: 'vline',
        x: sf.identity(dim.paddingLeft + dim.guideLeft - 1)
      };
      return renderer.add(vline, {});
    };

    Axis.prototype.render = function(dim, renderer) {
      if (this.type === 'x') this._renderHline(dim, renderer);
      if (this.type === 'y') this._renderVline(dim, renderer);
      return _.each(this.ticks, function(t) {});
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
