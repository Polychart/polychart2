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
    var layers;
    layers = [];
    spec.layers = spec.layers || [];
    _.each(spec.layers, function(layerSpec) {
      return poly.data.processData(layerSpec.data, layerSpec, function(statData, metaData) {
        var layerObj;
        layerObj = poly.layer.makeLayer(layerSpec, statData, metaData);
        layerObj.calculate();
        return layers.push(layerObj);
      });
    });
    return layers;
    /*
      # domain calculation and guide merging
      _.each layers (layerObj) ->
        makeGuides layerObj
      mergeGuides
    */
  };

  this.poly = poly;

}).call(this);
