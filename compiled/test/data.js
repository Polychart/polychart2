(function() {

  module("Data");

  test("smoke test", function() {
    var data, jsondata;
    jsondata = [
      {
        x: 2,
        y: 4
      }, {
        x: 2,
        y: 4
      }
    ];
    data = new Data({
      json: jsondata
    });
    return deepEqual(data.json, jsondata);
  });

  test("transforms -- numeric binning", function() {
    var data, spec, trans;
    data = new Data({
      json: [
        {
          x: 12,
          y: 42
        }, {
          x: 33,
          y: 56
        }
      ]
    });
    spec = {
      trans: {
        x: {
          trans: "bin",
          binwidth: 10,
          name: "bin(x, 10)"
        },
        y: {
          trans: "bin",
          binwidth: 5,
          name: "bin(y, 5)"
        }
      }
    };
    trans = frontendProcess(spec, data.json, function(x) {
      return x;
    });
    deepEqual(trans, [
      {
        x: 12,
        y: 42,
        'bin(x, 10)': 10,
        'bin(y, 5)': 40
      }, {
        x: 33,
        y: 56,
        'bin(x, 10)': 30,
        'bin(y, 5)': 55
      }
    ]);
    data = new Data({
      json: [
        {
          x: 1.2,
          y: 1
        }, {
          x: 3.3,
          y: 2
        }, {
          x: 3.3,
          y: 3
        }
      ]
    });
    spec = {
      trans: {
        x: {
          trans: "bin",
          binwidth: 1,
          name: "bin(x, 1)"
        },
        y: {
          trans: "lag",
          lag: 1,
          name: "lag(y, 1)"
        }
      }
    };
    trans = frontendProcess(spec, data.json, function(x) {
      return x;
    });
    deepEqual(trans, [
      {
        x: 1.2,
        y: 1,
        'bin(x, 1)': 1,
        'lag(y, 1)': void 0
      }, {
        x: 3.3,
        y: 2,
        'bin(x, 1)': 3,
        'lag(y, 1)': 1
      }, {
        x: 3.3,
        y: 3,
        'bin(x, 1)': 3,
        'lag(y, 1)': 2
      }
    ]);
    data = new Data({
      json: [
        {
          x: 1.2,
          y: 1
        }, {
          x: 3.3,
          y: 2
        }, {
          x: 3.3,
          y: 3
        }
      ]
    });
    spec = {
      trans: {
        x: {
          trans: "bin",
          binwidth: 1,
          name: "bin(x, 1)"
        },
        y: {
          trans: "lag",
          lag: 2,
          name: "lag(y, 2)"
        }
      }
    };
    trans = frontendProcess(spec, data.json, function(x) {
      return x;
    });
    return deepEqual(trans, [
      {
        x: 1.2,
        y: 1,
        'bin(x, 1)': 1,
        'lag(y, 2)': void 0
      }, {
        x: 3.3,
        y: 2,
        'bin(x, 1)': 3,
        'lag(y, 2)': void 0
      }, {
        x: 3.3,
        y: 3,
        'bin(x, 1)': 3,
        'lag(y, 2)': 1
      }
    ]);
  });

  test("transforms -- dates binning", function() {});

}).call(this);
