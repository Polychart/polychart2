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

}).call(this);
