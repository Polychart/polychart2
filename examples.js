(function() {

  if (this.examples == null) this.examples = {};

  this.examples.area_static = function(dom) {
    var c, data, jsondata, spec;
    jsondata = [
      {
        a: 1,
        b: 5,
        c: 'A'
      }, {
        a: 3,
        b: 4,
        c: 'A'
      }, {
        a: 2,
        b: 3,
        c: 'A'
      }, {
        a: 2,
        b: 2,
        c: 'B'
      }, {
        a: 1,
        b: 4,
        c: 'B'
      }, {
        a: 2.2,
        b: 3,
        c: 'B'
      }, {
        a: 3,
        b: 3,
        c: 'B'
      }
    ];
    data = new poly.Data({
      json: jsondata
    });
    spec = {
      layers: [
        {
          data: data,
          type: 'area',
          x: 'a',
          y: 'b',
          color: 'c'
        }
      ],
      dom: dom
    };
    return c = poly.chart(spec);
  };

  this.examples.area_single = function(dom) {
    var c, data, i, jsondata, spec, update;
    jsondata = (function() {
      var _results;
      _results = [];
      for (i = 0; i <= 10; i++) {
        _results.push({
          index: i,
          value: Math.random() * 10
        });
      }
      return _results;
    })();
    data = new poly.Data({
      json: jsondata
    });
    spec = {
      layers: [
        {
          data: data,
          type: 'area',
          x: 'index',
          y: 'value'
        }
      ],
      guides: {
        y: {
          type: 'num',
          min: 0,
          max: 10,
          ticks: [2, 4, 6, 8],
          labels: {
            2: 'Two',
            4: 'Four',
            6: 'Six',
            8: 'Eight'
          }
        }
      },
      dom: dom
    };
    c = poly.chart(spec);
    update = function() {
      jsondata.shift();
      jsondata.push({
        index: i++,
        value: Math.random() * 10
      });
      data.update({
        json: jsondata
      });
      return setTimeout(update, 1000);
    };
    setTimeout(update, 1000);
    return c.addHandler(function(type, e) {
      if (type === 'data') return c.make();
    });
  };

  this.examples.area_double = function(dom) {
    var c, data, even, i, item, jsondata, spec, update, value;
    even = function(i) {
      if (i % 2) {
        return "Odd";
      } else {
        return "Even";
      }
    };
    value = function() {
      return 2 + Math.random() * 5;
    };
    item = function(i) {
      return {
        index: Math.floor(i / 2),
        even: even(i),
        value: value()
      };
    };
    jsondata = (function() {
      var _results;
      _results = [];
      for (i = 0; i <= 19; i++) {
        _results.push(item(i));
      }
      return _results;
    })();
    data = new poly.Data({
      json: jsondata
    });
    spec = {
      layers: [
        {
          data: data,
          type: 'area',
          x: 'index',
          y: 'value',
          color: 'even'
        }
      ],
      guides: {
        y: {
          type: 'num',
          min: 0,
          max: 15
        }
      },
      dom: dom
    };
    c = poly.chart(spec);
    update = function() {
      var j, _i, _len, _ref;
      _ref = [1, 2];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        j = _ref[_i];
        jsondata.shift();
        jsondata.push(item(i));
        i++;
      }
      data.update({
        json: jsondata
      });
      return setTimeout(update, 1000);
    };
    setTimeout(update, 1000);
    return c.addHandler(function(type, e) {
      if (type === 'data') return c.make();
    });
  };

}).call(this);
(function() {

  if (this.examples == null) this.examples = {};

  this.examples.bar = function(dom) {
    var c, data, i, jsondata, spec;
    jsondata = (function() {
      var _results;
      _results = [];
      for (i = 0; i <= 10; i++) {
        _results.push({
          index: i,
          value: Math.random() * 10
        });
      }
      return _results;
    })();
    data = new poly.Data({
      json: jsondata
    });
    spec = {
      layers: [
        {
          data: data,
          type: 'bar',
          x: 'index',
          y: 'value',
          id: 'index'
        }
      ],
      guides: {
        x: {
          type: 'num',
          bw: 1
        },
        y: {
          type: 'num',
          min: 0,
          max: 10,
          ticks: [2, 4, 6, 8],
          labels: {
            2: 'Two',
            4: 'Four',
            6: 'Six',
            8: 'Eight'
          }
        }
      },
      dom: dom
    };
    c = poly.chart(spec);
    return c.addHandler(function(type, e) {
      data = e.evtData;
      if (type === 'reset') {
        jsondata.shift();
        jsondata.push({
          index: i++,
          value: Math.random() * 10
        });
        spec.layers[0].data.update({
          json: jsondata
        });
      }
      if (type === 'data') c.make(spec);
      if (type === 'click') {
        return alert("You clicked on index: " + data.index["in"][0]);
      }
    });
  };

  this.examples.bar_flip = function(dom) {
    var c, data, i, jsondata, spec, update;
    jsondata = (function() {
      var _results;
      _results = [];
      for (i = 0; i <= 10; i++) {
        _results.push({
          index: i,
          value: Math.random() * 10
        });
      }
      return _results;
    })();
    data = new poly.Data({
      json: jsondata
    });
    spec = {
      layers: [
        {
          data: data,
          type: 'bar',
          x: 'index',
          y: 'value',
          id: 'index'
        }
      ],
      guides: {
        x: {
          type: 'num',
          bw: 1
        },
        y: {
          type: 'num',
          min: 0,
          max: 10,
          ticks: [2, 4, 6, 8],
          labels: {
            2: 'Two',
            4: 'Four',
            6: 'Six',
            8: 'Eight'
          }
        }
      },
      coord: poly.coord.cartesian({
        flip: true
      }),
      dom: dom
    };
    c = poly.chart(spec);
    update = function() {
      jsondata.shift();
      jsondata.push({
        index: i++,
        value: Math.random() * 10
      });
      data.update({
        json: jsondata
      });
      return setTimeout(update, 1000);
    };
    setTimeout(update, 1000);
    return c.addHandler(function(type, e) {
      if (type === 'data') return c.make();
    });
  };

  this.examples.bar_polar = function(dom) {
    var c, data, i, jsondata, redraw, spec;
    jsondata = (function() {
      var _results;
      _results = [];
      for (i = 0; i <= 10; i++) {
        _results.push({
          index: i,
          value: Math.random() * 10
        });
      }
      return _results;
    })();
    data = new poly.Data({
      json: jsondata
    });
    spec = {
      layers: [
        {
          data: data,
          type: 'bar',
          x: 'index',
          y: 'value',
          id: 'index'
        }
      ],
      guides: {
        x: {
          type: 'num',
          bw: 1
        },
        y: {
          type: 'num',
          min: 0,
          max: 10,
          ticks: [2, 4, 6, 8],
          labels: {
            2: 'Two',
            4: 'Four',
            6: 'Six',
            8: 'Eight'
          }
        }
      },
      coord: poly.coord.polar({
        flip: true
      }),
      dom: dom
    };
    c = poly.chart(spec);
    redraw = function() {
      jsondata.shift();
      jsondata.push({
        index: i++,
        value: Math.random() * 10
      });
      spec.layers[0].data.update({
        json: jsondata
      });
      c.make(spec);
      return setTimeout(redraw, 1000);
    };
    return setTimeout(redraw, 1000);
  };

  this.examples.bar_static = function(dom) {
    var c, data, i, jsondata, spec;
    jsondata = (function() {
      var _results;
      _results = [];
      for (i = 0; i <= 10; i++) {
        _results.push({
          index: i,
          value: Math.random() * 10
        });
      }
      return _results;
    })();
    data = new poly.Data({
      json: jsondata
    });
    spec = {
      layers: [
        {
          data: data,
          type: 'bar',
          x: 'index',
          y: 'value',
          id: 'index'
        }
      ],
      guides: {
        x: {
          type: 'num',
          bw: 1
        },
        y: {
          type: 'num',
          min: 0,
          max: 10,
          ticks: [2, 4, 6, 8],
          labels: {
            2: 'Two',
            4: 'Four',
            6: 'Six',
            8: 'Eight'
          }
        }
      },
      dom: dom
    };
    return c = poly.chart(spec);
  };

  this.examples.bar_sum = function(dom) {
    var c, data, i, jsondata, redraw, spec;
    jsondata = (function() {
      var _results;
      _results = [];
      for (i = 0; i <= 5; i++) {
        _results.push({
          index: i,
          two: (i % 2 === 0 ? 'a' : 'b'),
          value: Math.random() * 10
        });
      }
      return _results;
    })();
    data = new poly.Data({
      json: jsondata
    });
    spec = {
      layers: [
        {
          data: data,
          type: 'bar',
          x: 'two',
          y: 'sum(value)',
          color: 'two',
          id: 'two'
        }
      ],
      guides: {
        color: {
          labels: {
            'a': 'Even Numbers',
            'b': 'Odd Numbers'
          },
          title: 'Test'
        },
        x: {
          labels: {
            'a': 'Even Numbers',
            'b': 'Odd Numbers'
          }
        },
        y: {
          min: 0,
          max: 30
        }
      },
      dom: dom
    };
    c = poly.chart(spec);
    redraw = function() {
      jsondata.shift();
      jsondata.push({
        index: i++,
        two: (i % 2 === 0 ? 'a' : 'b'),
        value: Math.random() * 10
      });
      spec.layers[0].data.update({
        json: jsondata
      });
      c.make(spec);
      return setTimeout(redraw, 1000);
    };
    return setTimeout(redraw, 1000);
  };

  this.examples.bar_stack = function(dom) {
    var c, data, i, jsondata, redraw, spec;
    jsondata = (function() {
      var _results;
      _results = [];
      for (i = 0; i <= 10; i++) {
        _results.push({
          index: i,
          two: (i % 2 === 0 ? 'a' : 'b'),
          value: Math.random() * 10
        });
      }
      return _results;
    })();
    data = new poly.Data({
      json: jsondata
    });
    spec = {
      layers: [
        {
          data: data,
          type: 'bar',
          x: 'two',
          y: 'value',
          color: 'index'
        }
      ],
      guides: {
        color: {
          labels: {
            'a': 'Even Numbers',
            'b': 'Odd Numbers'
          },
          title: 'Test'
        },
        x: {
          labels: {
            'a': 'Even Numbers',
            'b': 'Odd Numbers'
          }
        }
      },
      dom: dom
    };
    c = poly.chart(spec);
    redraw = function() {
      jsondata.push({
        index: i++,
        two: (i % 2 === 0 ? 'a' : 'b'),
        value: Math.random() * 10
      });
      spec.layers[0].data.update({
        json: jsondata
      });
      c.make(spec);
      return setTimeout(redraw, 1000);
    };
    return setTimeout(redraw, 1000);
  };

  this.examples.bar_ajax_csv = function(dom) {
    var c, data, spec;
    data = new poly.Data({
      url: "data/test.csv"
    });
    spec = {
      layers: [
        {
          data: data,
          type: 'bar',
          x: 'A',
          y: 'B'
        }
      ],
      dom: dom,
      guide: {
        y: {
          type: 'num'
        }
      }
    };
    return c = poly.chart(spec);
  };

}).call(this);
(function() {
  var datafn2;

  if (this.examples == null) this.examples = {};

  datafn2 = function() {
    var i, item, _results;
    item = function(i) {
      return {
        mod3: i % 3 === 0 ? "G1" : i % 3 === 1 ? "G2" : "G3",
        value: i === 99 ? 15 : Math.random() * 10
      };
    };
    _results = [];
    for (i = 0; i <= 200; i++) {
      _results.push(item(i));
    }
    return _results;
  };

  this.examples.box = function(dom) {
    var data;
    data = new poly.Data({
      json: datafn2()
    });
    return poly.chart({
      layers: [
        {
          data: data,
          type: 'box',
          x: 'mod3',
          y: 'box(value)'
        }
      ],
      dom: dom
    });
  };

}).call(this);
(function() {

  if (this.examples == null) this.examples = {};

  this.examples.line = function(dom) {
    var c, data, i, jsondata, redraw, spec;
    jsondata = (function() {
      var _results;
      _results = [];
      for (i = 0; i <= 10; i++) {
        _results.push({
          index: i,
          value: Math.random() * 10
        });
      }
      return _results;
    })();
    data = new poly.Data({
      json: jsondata
    });
    spec = {
      layers: [
        {
          data: data,
          type: 'line',
          x: 'index',
          y: 'value'
        }, {
          data: data,
          type: 'point',
          x: 'index',
          y: 'value',
          id: 'index'
        }
      ],
      guides: {
        y: {
          type: 'num',
          min: 0,
          max: 10,
          ticks: [2, 4, 6, 8],
          labels: {
            2: 'Two',
            4: 'Four',
            6: 'Six',
            8: 'Eight'
          }
        }
      },
      dom: dom
    };
    c = poly.chart(spec);
    redraw = function() {
      jsondata.shift();
      jsondata.push({
        index: i++,
        value: Math.random() * 10
      });
      spec.layers[0].data.update({
        json: jsondata
      });
      c.make(spec);
      return setTimeout(redraw, 1000);
    };
    return setTimeout(redraw, 1000);
  };

  this.examples.line_sum = function(dom) {
    var c, data, i, jsondata, next, redraw, s, spec;
    i = 0;
    s = 0;
    next = function() {
      var v;
      v = Math.random() * 10;
      s += v;
      return {
        index: i++,
        value: v,
        total: s
      };
    };
    jsondata = (function() {
      var _results;
      _results = [];
      for (i = 0; i <= 10; i++) {
        _results.push(next());
      }
      return _results;
    })();
    data = new poly.Data({
      json: jsondata
    });
    spec = {
      layers: [
        {
          data: data,
          type: 'line',
          x: 'index',
          y: 'total'
        }, {
          data: data,
          type: 'point',
          x: 'index',
          y: 'total',
          id: 'index'
        }
      ],
      guides: {
        y: {
          min: 0
        }
      },
      dom: dom
    };
    c = poly.chart(spec);
    redraw = function() {
      jsondata.shift();
      jsondata.push(next());
      spec.layers[0].data.update({
        json: jsondata
      });
      c.make(spec);
      return setTimeout(redraw, 1000);
    };
    return setTimeout(redraw, 1000);
  };

  this.examples.line_flip = function(dom) {
    var c, data, i, jsondata, redraw, spec;
    jsondata = (function() {
      var _results;
      _results = [];
      for (i = 0; i <= 10; i++) {
        _results.push({
          index: i,
          value: Math.random() * 10
        });
      }
      return _results;
    })();
    data = new poly.Data({
      json: jsondata
    });
    spec = {
      layers: [
        {
          data: data,
          type: 'line',
          x: 'index',
          y: 'value'
        }, {
          data: data,
          type: 'point',
          x: 'index',
          y: 'value',
          id: 'index'
        }
      ],
      guides: {
        y: {
          type: 'num',
          min: 0,
          max: 10,
          ticks: [2, 4, 6, 8],
          labels: {
            2: 'Two',
            4: 'Four',
            6: 'Six',
            8: 'Eight'
          }
        }
      },
      coord: poly.coord.cartesian({
        flip: true
      }),
      dom: dom
    };
    c = poly.chart(spec);
    redraw = function() {
      jsondata.shift();
      jsondata.push({
        index: i++,
        value: Math.random() * 10
      });
      spec.layers[0].data.update({
        json: jsondata
      });
      c.make(spec);
      return setTimeout(redraw, 1000);
    };
    return setTimeout(redraw, 1000);
  };

  this.examples.line_polar = function(dom) {
    var c, data, i, jsondata, redraw, spec;
    jsondata = (function() {
      var _results;
      _results = [];
      for (i = 0; i <= 10; i++) {
        _results.push({
          index: i,
          value: Math.random() * 10
        });
      }
      return _results;
    })();
    data = new poly.Data({
      json: jsondata
    });
    spec = {
      layers: [
        {
          data: data,
          type: 'line',
          x: 'index',
          y: 'value'
        }, {
          data: data,
          type: 'point',
          x: 'index',
          y: 'value',
          id: 'index'
        }
      ],
      guides: {
        y: {
          type: 'num',
          min: 0,
          max: 10,
          ticks: [2, 4, 6, 8],
          labels: {
            2: 'Two',
            4: 'Four',
            6: 'Six',
            8: 'Eight'
          }
        }
      },
      coord: poly.coord.polar(),
      dom: dom
    };
    c = poly.chart(spec);
    redraw = function() {
      jsondata.shift();
      jsondata.push({
        index: i++,
        value: Math.random() * 10
      });
      spec.layers[0].data.update({
        json: jsondata
      });
      c.make(spec);
      return setTimeout(redraw, 1000);
    };
    return setTimeout(redraw, 1000);
  };

  this.examples.line_polar_flip = function(dom) {
    var c, data, i, jsondata, redraw, spec;
    jsondata = (function() {
      var _results;
      _results = [];
      for (i = 0; i <= 10; i++) {
        _results.push({
          index: i,
          value: Math.random() * 10
        });
      }
      return _results;
    })();
    data = new poly.Data({
      json: jsondata
    });
    spec = {
      layers: [
        {
          data: data,
          type: 'line',
          x: 'index',
          y: 'value'
        }, {
          data: data,
          type: 'point',
          x: 'index',
          y: 'value',
          id: 'index'
        }
      ],
      guides: {
        y: {
          type: 'num',
          min: 0,
          max: 10,
          ticks: [2, 4, 6, 8],
          labels: {
            2: 'Two',
            4: 'Four',
            6: 'Six',
            8: 'Eight'
          }
        }
      },
      coord: poly.coord.polar({
        flip: true
      }),
      dom: dom
    };
    c = poly.chart(spec);
    redraw = function() {
      jsondata.shift();
      jsondata.push({
        index: i++,
        value: Math.random() * 10
      });
      spec.layers[0].data.update({
        json: jsondata
      });
      c.make(spec);
      return setTimeout(redraw, 1000);
    };
    return setTimeout(redraw, 1000);
  };

  this.examples.line_static = function(dom) {
    var c, data, jsondata, spec;
    jsondata = [
      {
        a: 1,
        b: 5,
        c: 'A'
      }, {
        a: 3,
        b: 4,
        c: 'A'
      }, {
        a: 2,
        b: 3,
        c: 'A'
      }, {
        a: 2,
        b: 2,
        c: 'B'
      }, {
        a: 1,
        b: 4,
        c: 'B'
      }, {
        a: 2.2,
        b: 3,
        c: 'B'
      }, {
        a: 3,
        b: 3,
        c: 'B'
      }
    ];
    data = new poly.Data({
      json: jsondata
    });
    spec = {
      layers: [
        {
          data: data,
          type: 'line',
          x: 'a',
          y: 'b',
          color: 'c'
        }
      ],
      dom: dom
    };
    return c = poly.chart(spec);
  };

  this.examples.path = function(dom) {
    var c, data, jsondata, spec;
    jsondata = [
      {
        a: 1,
        b: 5,
        c: 'A'
      }, {
        a: 3,
        b: 4,
        c: 'A'
      }, {
        a: 2,
        b: 3,
        c: 'A'
      }, {
        a: 2,
        b: 2,
        c: 'B'
      }, {
        a: 1,
        b: 4,
        c: 'B'
      }, {
        a: 2.2,
        b: 3,
        c: 'B'
      }, {
        a: 3,
        b: 3,
        c: 'B'
      }
    ];
    data = new poly.Data({
      json: jsondata
    });
    spec = {
      layers: [
        {
          data: data,
          type: 'path',
          x: 'a',
          y: 'b',
          color: 'c'
        }
      ],
      dom: dom
    };
    return c = poly.chart(spec);
  };

}).call(this);
(function() {

  if (this.examples == null) this.examples = {};

  this.examples.point = function(dom) {
    var c, initspec, one, redraw, spec;
    one = function() {
      return Math.random() * 10;
    };
    spec = function() {
      var data, i, jsondata, sampleLayer;
      jsondata = (function() {
        var _results;
        _results = [];
        for (i = 0; i <= 10; i++) {
          _results.push({
            x: one(),
            y: one(),
            c: one()
          });
        }
        return _results;
      })();
      data = new poly.Data({
        json: jsondata
      });
      sampleLayer = {
        data: data,
        type: 'point',
        x: 'x',
        y: 'y',
        color: 'c'
      };
      if (Math.random() < 0.33) {
        sampleLayer.size = 'x';
      } else if (Math.random() < 0.5) {
        sampleLayer.size = 'c';
      }
      return {
        data: jsondata,
        spec: {
          layers: [sampleLayer],
          guides: {
            y: {
              type: 'num',
              min: 0,
              max: 10,
              ticks: [2, 4, 6, 8],
              labels: {
                2: 'Two',
                4: 'Four',
                6: 'Six',
                8: 'Eight'
              }
            },
            x: {
              type: 'num',
              min: 0,
              max: 10,
              ticks: [2, 4, 6, 8],
              labels: {
                2: 'Two',
                4: 'Four',
                6: 'Six',
                8: 'Eight'
              }
            },
            color: {
              type: 'num',
              min: 0,
              max: 10,
              ticks: [2, 4, 6, 8],
              labels: {
                2: 'Two',
                4: 'Four',
                6: 'Six',
                8: 'Eight'
              }
            },
            size: {
              type: 'num',
              min: 0,
              max: 10,
              ticks: [2, 4, 6, 8],
              labels: {
                2: 'Two',
                4: 'Four',
                6: 'Six',
                8: 'Eight'
              }
            }
          },
          dom: dom
        }
      };
    };
    initspec = spec().spec;
    c = poly.chart(initspec);
    redraw = function() {
      var newspec;
      newspec = spec();
      initspec.layers[0].data.update({
        json: newspec.data
      });
      c.make(newspec.spec);
      return setTimeout(redraw, 1000);
    };
    return setTimeout(redraw, 1000);
  };

  this.examples.point2 = function(dom) {
    var c, data, jsondata, sampleLayer, spec;
    jsondata = [
      {
        x: 'A',
        y: 2
      }, {
        x: 'B',
        y: 3
      }, {
        x: 'C',
        y: 1
      }
    ];
    data = new poly.Data({
      json: jsondata
    });
    sampleLayer = {
      dom: dom,
      data: data,
      type: 'point',
      x: 'x',
      y: 'y',
      size: {
        'const': 10
      },
      color: 'x'
    };
    spec = {
      layers: [sampleLayer],
      dom: dom
    };
    return c = poly.chart(spec);
  };

  this.examples.point3 = function(dom) {
    var c, data, jsondata, sampleLayer, spec;
    jsondata = [
      {
        x: 'A',
        y: 'X'
      }, {
        x: 'B',
        y: 'Y'
      }, {
        x: 'C',
        y: 'Z'
      }
    ];
    data = new poly.Data({
      json: jsondata
    });
    sampleLayer = {
      data: data,
      type: 'point',
      x: 'x',
      y: 'y',
      color: {
        "const": '#E01B6A'
      }
    };
    spec = {
      layers: [sampleLayer],
      dom: dom
    };
    return c = poly.chart(spec);
  };

  this.examples.point3_flip = function(dom) {
    var c, data, jsondata, sampleLayer, spec;
    jsondata = [
      {
        x: 'A',
        y: 'X'
      }, {
        x: 'B',
        y: 'Y'
      }, {
        x: 'C',
        y: 'Z'
      }
    ];
    data = new poly.Data({
      json: jsondata
    });
    sampleLayer = {
      data: data,
      type: 'point',
      x: 'x',
      y: 'y',
      color: {
        "const": '#E01B6A'
      }
    };
    spec = {
      layers: [sampleLayer],
      coord: poly.coord.polar({
        flip: true
      }),
      dom: dom
    };
    c = poly.chart(spec);
    return c.addHandler(function(type, data) {
      if (type === 'click' || type === 'reset') {
        console.log(data);
        return alert(type);
      }
    });
  };

}).call(this);
(function() {

  if (this.examples == null) this.examples = {};

  this.examples.text = function(dom) {
    var c, data, jsondata, sampleLayer, spec;
    jsondata = [
      {
        x: 'A',
        y: 'X'
      }, {
        x: 'B',
        y: 'Y'
      }, {
        x: 'C',
        y: 'Z'
      }
    ];
    data = new poly.Data({
      json: jsondata
    });
    sampleLayer = {
      data: data,
      type: 'text',
      x: 'x',
      y: 'y',
      text: 'y'
    };
    spec = {
      layers: [sampleLayer],
      coord: poly.coord.polar({
        flip: true
      }),
      dom: dom
    };
    c = poly.chart(spec);
    return c.addHandler(function(type, data) {
      if (type === 'click' || type === 'reset') {
        console.log(data);
        return alert(type);
      }
    });
  };

}).call(this);
(function() {
  var datafn;

  if (this.examples == null) this.examples = {};

  datafn = function() {
    var a, b, i, item, value, _results;
    a = function(i) {
      return i % 5;
    };
    b = function(i) {
      return Math.floor(i / 5);
    };
    value = function() {
      return Math.random() * 5;
    };
    item = function(i) {
      return {
        mod5: a(i),
        floor5: b(i),
        value: value()
      };
    };
    _results = [];
    for (i = 0; i <= 24; i++) {
      _results.push(item(i));
    }
    return _results;
  };

  this.examples.tiles = function(dom) {
    var c, data, spec;
    data = new poly.Data({
      json: datafn()
    });
    spec = {
      layers: [
        {
          data: data,
          type: 'tile',
          x: 'bin(mod5, 1)',
          y: 'bin(floor5,1)',
          color: 'value'
        }
      ],
      dom: dom
    };
    return c = poly.chart(spec);
  };

  this.examples.tiles_bw = function(dom) {
    var c, data, spec;
    data = new poly.Data({
      json: datafn()
    });
    spec = {
      layers: [
        {
          data: data,
          type: 'tile',
          x: 'bin(mod5, 1)',
          y: 'bin(floor5,1)',
          color: 'value'
        }
      ],
      guides: {
        color: {
          scale: poly.scale.gradient({
            lower: '#FFF',
            upper: '#000'
          })
        }
      },
      dom: dom
    };
    return c = poly.chart(spec);
  };

}).call(this);
