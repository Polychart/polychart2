(function() {
  var Graph, Layer;

  Graph = (function() {

    function Graph(input) {
      var graphSpec;
      graphSpec = spec;
    }

    return Graph;

  })();

  Layer = (function() {

    function Layer(layerSpec, statData) {
      this.spec = layerSpec;
      this.precalc = statData;
    }

    Layer.prototype.calculate = function(statData) {
      return layerData;
    };

    return Layer;

  })();

}).call(this);
