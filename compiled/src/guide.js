(function() {
  var Axis, Guide, Legend, poly;

  poly = this.poly || {};

  Guide = (function() {

    function Guide(params) {
      this.scales = params.scales, this.guideSpec = params.guideSpec;
      this.position = 'left';
      this.ticks = [];
    }

    Guide.prototype.getWidth = function() {};

    Guide.prototype.getHeight = function() {};

    Guide.prototype.render = function(paper, render, scales) {
      throw new poly.NotImplemented("render is not implemented");
    };

    return Guide;

  })();

  Axis = (function() {

    function Axis(params) {
      this.domain = params.domain, this.factory = params.factory, this.scale = params.scale, this.guideSpec = params.guideSpec;
      this.position = 'left';
      this.ticks = poly.tick.make(this.domain, this.scale, this.guideSpec, this.factory.tickType(this.domain));
    }

    Axis.prototype.render = function(paper, render, scales) {};

    return Axis;

  })();

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
