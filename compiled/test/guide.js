(function() {
  var data, jsondata, sampleLayer;

  module("Guides");

  jsondata = [
    {
      x: 2,
      y: 1
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
    var guides, spec, ticks, _ref;
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
          levels: [1, 2, 3],
          labels: {
            1: 'One',
            2: 'Five'
          }
        }
      }
    };
    _ref = poly.chart(spec), guides = _ref.guides, ticks = _ref.ticks;
    equal(guides.x.type, 'num');
    equal(guides.x.min, 2);
    equal(guides.x.max, 4);
    equal(guides.x.bw, 3);
    equal(guides.y.type, 'cat');
    deepEqual(guides.y.levels, [1, 2, 3]);
    equal(guides.y.sorted, true);
    deepEqual(_.pluck(ticks.x, 'location'), [2, 2.5, 3, 3.5]);
    deepEqual(_.pluck(ticks.y, 'location'), [1, 2, 3]);
    return deepEqual(_.pluck(ticks.y, 'value'), ['One', 'Five', 3]);
  });

}).call(this);
