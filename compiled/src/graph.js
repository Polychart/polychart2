(function() {
  var Graph, poly;

  poly = this.poly || {};

  Graph = (function() {

    function Graph(spec) {
      var graphSpec;
      graphSpec = spec;
    }

    return Graph;

  })();

  poly.chart = function(spec) {
    var dims, domains, layers, scales, ticks;
    if (spec.strict == null) spec.strict = false;
    layers = [];
    if (spec.layers == null) spec.layers = [];
    _.each(spec.layers, function(layerSpec) {
      var callback;
      callback = function(statData, metaData) {
        var layerObj;
        layerObj = poly.layer.make(layerSpec, statData, metaData);
        layerObj.calculate();
        return layers.push(layerObj);
      };
      return poly.data.process(layerSpec.data, layerSpec, spec.strict, callback);
    });
    domains = {};
    ticks = {};
    if (spec.guides) {
      if (spec.guides == null) spec.guides = {};
      domains = poly.domain.make(layers, spec.guides, spec.strict);
    }
    _.each(domains, function(domain, aes) {
      var _ref;
      return ticks[aes] = poly.tick.make(domain, (_ref = spec.guides[aes]) != null ? _ref : []);
    });
    dims = poly.dim.make(spec, ticks);
    scales = poly.scale.make(spec.guide, domains, dims);
    return {
      layers: layers,
      guides: domains,
      ticks: ticks,
      dims: dims,
      scales: scales
    };
  };

  this.poly = poly;

}).call(this);
