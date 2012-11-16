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
      return console.log('wtf not impl');
    };

    return Guide;

  })();

  Axis = (function() {

    function Axis() {}

    Axis.prototype.render = function(paper, render, scales) {};

    return Axis;

  })();

  Legend = (function() {

    function Legend() {}

    Legend.prototype.render = function(paper, render, scales) {};

    return Legend;

  })();

  poly.guide = {};

  poly.guide.axis = function(domain, factory, scale, guideSpec) {
    return poly.tick.make(domain, scale, guideSpec, factory.tickType(domain));
  };

  this.poly = poly;

}).call(this);
