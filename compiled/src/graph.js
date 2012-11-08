(function() {
  var Graph, poly,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  poly = this.poly || {};

  Graph = (function() {

    function Graph(spec) {
      this.render = __bind(this.render, this);
      var _this = this;
      this.spec = spec;
      if (spec.strict == null) spec.strict = false;
      this.strict = spec.strict;
      this.layers = [];
      if (spec.layers == null) spec.layers = [];
      _.each(spec.layers, function(layerSpec) {
        var layerObj;
        layerObj = poly.layer.make(layerSpec, spec.strict);
        layerObj.calculate();
        return _this.layers.push(layerObj);
      });
      this.domains = {};
      if (spec.guides) {
        if (spec.guides == null) spec.guides = {};
        this.domains = poly.domain.make(this.layers, spec.guides, spec.strict);
      }
      this.ticks = {};
      _.each(this.domains, function(domain, aes) {
        var _ref;
        return _this.ticks[aes] = poly.tick.make(domain, (_ref = spec.guides[aes]) != null ? _ref : []);
      });
      this.dims = poly.dim.make(spec, this.ticks);
      this.scales = poly.scale.make(spec.guide, this.domains, this.dims);
      console.log(this.scales);
    }

    Graph.prototype.render = function(dom) {
      var paper,
        _this = this;
      dom = document.getElementById(dom);
      paper = poly.paper(dom, 300, 300);
      return _.each(this.layers, function(layer) {
        return poly.render(layer.geoms, paper, _this.scales);
      });
    };

    return Graph;

  })();

  poly.chart = function(spec) {
    return new Graph(spec);
  };

  this.poly = poly;

}).call(this);
