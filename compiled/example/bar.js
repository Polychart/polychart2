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
      spec.layers[0].data.update(jsondata);
      c.make(spec);
      c.render(dom);
      return setTimeout(redraw, 1000);
    };
    return setTimeout(redraw, 1000);
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
    console.log(jsondata);
    data = new poly.Data({
      json: jsondata
    });
    spec = {
      layers: [
        {
          data: data,
          type: 'bar',
          x: 'two',
          y: 'sum(value)'
        }
      ]
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
      spec.layers[0].data.update(jsondata);
      c.make(spec);
      c.render(dom);
      return setTimeout(redraw, 1000);
    };
    return setTimeout(redraw, 1000);
  };

}).call(this);
