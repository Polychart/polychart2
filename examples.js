(function() {

  if (this.examples == null) this.examples = {};

  this.examples.bar = function(dom) {
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
      spec.layers[0].data.update(jsondata);
      c.make(spec);
      c.render(dom);
      return setTimeout(redraw, 1000);
    };
    return setTimeout(redraw, 1000);
  };

  this.examples.bar_flip = function(dom) {
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
      flip: true
    };
    c = poly.chart(spec);
    c.render(dom);
    redraw = function() {
      jsondata.shift();
      jsondata.push({
        index: i++,
        value: Math.random() * 10
      });
      spec.layers[0].data.update(jsondata);
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
    return c.render(dom);
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
      spec.layers[0].data.update(jsondata);
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
      flip: true
    };
    c = poly.chart(spec);
    c.render(dom);
    redraw = function() {
      jsondata.shift();
      jsondata.push({
        index: i++,
        value: Math.random() * 10
      });
      spec.layers[0].data.update(jsondata);
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
      initspec.layers[0].data.update(newspec.data);
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
      flip: true
    };
    c = poly.chart(spec);
    return c.render(dom);
  };

}).call(this);
