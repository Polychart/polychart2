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
      }
    };
    c = poly.chart(spec);
    c.render(dom);
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
      if (type === 'data') {
        c.make(spec);
        c.render(dom);
      }
      if (type === 'click') alert("You clicked on index: " + data.index["in"][0]);
      if (type === 'select') return console.log(data);
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
      })
    };
    c = poly.chart(spec);
    c.render(dom);
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
      if (type === 'data') {
        c.make();
        return c.render(dom);
      }
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
      })
    };
    c = poly.chart(spec);
    c.render(dom);
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
      c.render(dom);
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
      }
    };
    c = poly.chart(spec);
    c.render(dom);
    return c.addHandler(function(type, e) {
      data = e.evtData;
      if (type === 'select') return console.log(data);
    });
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
      }
    };
    c = poly.chart(spec);
    c.render(dom);
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
      c.render(dom);
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
      }
    };
    c = poly.chart(spec);
    c.render(dom);
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
      c.render(dom);
      return setTimeout(redraw, 1000);
    };
    return setTimeout(redraw, 1000);
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
      }
    };
    c = poly.chart(spec);
    c.render(dom);
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
      c.render(dom);
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
      }
    };
    c = poly.chart(spec);
    c.render(dom);
    redraw = function() {
      jsondata.shift();
      jsondata.push(next());
      spec.layers[0].data.update({
        json: jsondata
      });
      c.make(spec);
      c.render(dom);
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
      })
    };
    c = poly.chart(spec);
    c.render(dom);
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
      c.render(dom);
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
      coord: poly.coord.polar()
    };
    c = poly.chart(spec);
    c.render(dom);
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
      c.render(dom);
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
      })
    };
    c = poly.chart(spec);
    c.render(dom);
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
      c.render(dom);
      return setTimeout(redraw, 1000);
    };
    return setTimeout(redraw, 1000);
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
          }
        }
      };
    };
    initspec = spec().spec;
    c = poly.chart(initspec);
    c.render(dom);
    redraw = function() {
      var newspec;
      newspec = spec();
      initspec.layers[0].data.update({
        json: newspec.data
      });
      c.make(newspec.spec);
      c.render();
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
      layers: [sampleLayer]
    };
    c = poly.chart(spec);
    return c.render(dom);
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
      layers: [sampleLayer]
    };
    c = poly.chart(spec);
    return c.render(dom);
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
      })
    };
    c = poly.chart(spec);
    c.render(dom);
    return c.addHandler(function(type, data) {
      if (type === 'click' || type === 'reset') {
        console.log(data);
        return alert(type);
      }
    });
  };

}).call(this);
