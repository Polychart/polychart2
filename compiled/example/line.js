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
