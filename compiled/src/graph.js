(function() {
  var Graph, poly;

  poly = this.poly || {};

  Graph = (function() {

    function Graph(spec) {
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
    }

    return Graph;

  })();

  poly.chart = function(spec) {
    return new Graph(spec);
  };

  this.poly = poly;

}).call(this);
