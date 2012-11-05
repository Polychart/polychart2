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
    var guides, layers, ticks;
    if (spec.strict == null) spec.strict = false;
    layers = [];
    if (spec.layers == null) spec.layers = [];
    _.each(spec.layers, function(layerSpec) {
      var callback;
      callback = function(statData, metaData) {
        var layerObj;
        layerObj = poly.layer.makeLayer(layerSpec, statData, metaData);
        layerObj.calculate();
        return layers.push(layerObj);
      };
      return poly.data.processData(layerSpec.data, layerSpec, spec.strict, callback);
    });
    guides = {};
    ticks = {};
    if (spec.guides) {
      if (spec.guides == null) spec.guides = {};
      guides = poly.guide.makeGuides(layers, spec.guides, spec.strict);
    }
    _.each(guides, function(domain, aes) {
      var _ref;
      return ticks[aes] = poly.guide.makeTicks(domain, (_ref = spec.guides[aes]) != null ? _ref : []);
    });
    return {
      layers: layers,
      guides: guides,
      ticks: ticks
    };
  };

  this.poly = poly;

}).call(this);
