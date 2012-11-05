(function() {
  var data, jsondata, sampleLayer;

  module("Guides");

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

  sampleLayer = {
    data: data,
    type: 'point',
    x: 'x',
    y: 'y'
  };

  test("domain: strict mode num & cat", function() {
    var guides, spec;
    spec = {
      layers: [sampleLayer],
      strict: true,
      guides: {
        x: {
          type: 'num',
          min: 2,
          max: 4,
          bw: 3
        },
        y: {
          type: 'cat',
          levels: [1, 2, 3]
        }
      }
    };
    guides = poly.chart(spec).guides;
    equal(guides.x.type, 'num');
    equal(guides.x.min, 2);
    equal(guides.x.max, 4);
    equal(guides.x.bw, 3);
    equal(guides.y.type, 'cat');
    deepEqual(guides.y.levels, [1, 2, 3]);
    return equal(guides.y.sorted, true);
  });

}).call(this);
