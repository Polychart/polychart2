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

  test("filtering", function() {
    var data, spec, trans;
    data = [
      {
        x: 1.2,
        y: 1
      }, {
        x: 3.3,
        y: 2
      }, {
        x: 3.4,
        y: 3
      }
    ];
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
      },
      filter: {
        x: {
          lt: 3
        }
      }
    };
    trans = frontendProcess(spec, data, function(x) {
      return x;
    });
    deepEqual(trans, [
      {
        x: 1.2,
        y: 1,
        'bin(x, 1)': 1,
        'lag(y, 1)': void 0
      }
    ]);
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
      },
      filter: {
        x: {
          lt: 3.35,
          gt: 1.2
        }
      }
    };
    trans = frontendProcess(spec, data, function(x) {
      return x;
    });
    deepEqual(trans, [
      {
        x: 3.3,
        y: 2,
        'bin(x, 1)': 3,
        'lag(y, 1)': 1
      }
    ]);
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
      },
      filter: {
        x: {
          le: 3.35,
          ge: 1.2
        },
        y: {
          lt: 100
        }
      }
    };
    trans = frontendProcess(spec, data, function(x) {
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
      }
    ]);
    data = [
      {
        x: 1.2,
        y: 1,
        z: 'A'
      }, {
        x: 3.3,
        y: 2,
        z: 'B'
      }, {
        x: 3.4,
        y: 3,
        z: 'B'
      }
    ];
    spec = {
      filter: {
        z: {
          "in": 'B'
        }
      }
    };
    trans = frontendProcess(spec, data, function(x) {
      return x;
    });
    deepEqual(trans, [
      {
        x: 3.3,
        y: 2,
        z: 'B'
      }, {
        x: 3.4,
        y: 3,
        z: 'B'
      }
    ]);
    spec = {
      filter: {
        z: {
          "in": ['A', 'B']
        }
      }
    };
    trans = frontendProcess(spec, data, function(x) {
      return x;
    });
    return deepEqual(trans, [
      {
        x: 1.2,
        y: 1,
        z: 'A'
      }, {
        x: 3.3,
        y: 2,
        z: 'B'
      }, {
        x: 3.4,
        y: 3,
        z: 'B'
      }
    ]);
  });

  test("statistics - sum", function() {
    var data, spec, trans;
    data = [
      {
        x: 'A',
        y: 1,
        z: 1
      }, {
        x: 'A',
        y: 1,
        z: 2
      }, {
        x: 'A',
        y: 1,
        z: 1
      }, {
        x: 'A',
        y: 1,
        z: 2
      }, {
        x: 'A',
        y: 1,
        z: 1
      }, {
        x: 'A',
        y: 1,
        z: 2
      }, {
        x: 'B',
        y: 1,
        z: 1
      }, {
        x: 'B',
        y: 1,
        z: 2
      }, {
        x: 'B',
        y: 1,
        z: 1
      }, {
        x: 'B',
        y: 1,
        z: 2
      }
    ];
    spec = {
      stats: {
        stats: [
          {
            key: 'y',
            stat: 'count',
            name: 'count(y)'
          }
        ],
        group: ['x']
      }
    };
    trans = frontendProcess(spec, data, function(x) {
      return x;
    });
    deepEqual(trans, [
      {
        x: 'A',
        'count(y)': 6
      }, {
        x: 'B',
        'count(y)': 4
      }
    ]);
    spec = {
      stats: {
        stats: [
          {
            key: 'y',
            stat: 'count',
            name: 'count(y)'
          }
        ],
        group: ['x', 'z']
      }
    };
    trans = frontendProcess(spec, data, function(x) {
      return x;
    });
    deepEqual(trans, [
      {
        x: 'A',
        z: 1,
        'count(y)': 3
      }, {
        x: 'A',
        z: 2,
        'count(y)': 3
      }, {
        x: 'B',
        z: 1,
        'count(y)': 2
      }, {
        x: 'B',
        z: 2,
        'count(y)': 2
      }
    ]);
    spec = {
      stats: {
        stats: [
          {
            key: 'y',
            stat: 'uniq',
            name: 'uniq(y)'
          }
        ],
        group: ['x', 'z']
      }
    };
    trans = frontendProcess(spec, data, function(x) {
      return x;
    });
    deepEqual(trans, [
      {
        x: 'A',
        z: 1,
        'uniq(y)': 1
      }, {
        x: 'A',
        z: 2,
        'uniq(y)': 1
      }, {
        x: 'B',
        z: 1,
        'uniq(y)': 1
      }, {
        x: 'B',
        z: 2,
        'uniq(y)': 1
      }
    ]);
    spec = {
      stats: {
        stats: [
          {
            key: 'y',
            stat: 'count',
            name: 'count(y)'
          }, {
            key: 'y',
            stat: 'uniq',
            name: 'uniq(y)'
          }
        ],
        group: ['x', 'z']
      }
    };
    trans = frontendProcess(spec, data, function(x) {
      return x;
    });
    return deepEqual(trans, [
      {
        x: 'A',
        z: 1,
        'uniq(y)': 1,
        'count(y)': 3
      }, {
        x: 'A',
        z: 2,
        'uniq(y)': 1,
        'count(y)': 3
      }, {
        x: 'B',
        z: 1,
        'uniq(y)': 1,
        'count(y)': 2
      }, {
        x: 'B',
        z: 2,
        'uniq(y)': 1,
        'count(y)': 2
      }
    ]);
  });

}).call(this);
