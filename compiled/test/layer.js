(function() {

  module("Layer");

  test("point -- smoke test", function() {
    var data, jsondata, layer, layers, spec;
    jsondata = [
      {
        x: 2,
        y: 4
      }, {
        x: 3,
        y: 3
      }
    ];
    data = new poly.Data({
      json: jsondata
    });
    spec = {
      layers: [
        {
          data: data,
          type: 'point',
          x: 'x',
          y: 'y'
        }
      ]
    };
    layers = poly.chart(spec);
    layer = layers[0];
    equal(layer.geoms.length, 2);
    equal(layer.geoms[0].geom.type, 'point');
    equal(layer.geoms[0].geom.x, 2);
    equal(layer.geoms[0].geom.y, 4);
    equal(layer.geoms[0].geom.color, layer.defaults.color);
    deepEqual(layer.geoms[0].evtData.x["in"], [2]);
    deepEqual(layer.geoms[0].evtData.y["in"], [4]);
    equal(layer.geoms[1].geom.type, 'point');
    equal(layer.geoms[1].geom.x, 3);
    equal(layer.geoms[1].geom.y, 3);
    equal(layer.geoms[1].geom.color, layer.defaults.color);
    deepEqual(layer.geoms[1].evtData.x["in"], [3]);
    return deepEqual(layer.geoms[1].evtData.y["in"], [3]);
  });

}).call(this);
