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
