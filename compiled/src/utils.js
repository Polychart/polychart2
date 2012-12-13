(function() {
  var THRESHOLD, poly;

  poly = this.poly || {};

  /*
  Group an array of data items by the value of certain columns.
  
  Input:
  - `data`: an array of data items
  - `group`: an array of column keys, to group by
  Output:
  - an associate array of key: array of data, with the appropriate grouping
    the `key` is a string of format "columnKey:value;colunmKey2:value2;..."
  */

  poly.groupBy = function(data, group) {
    return _.groupBy(data, function(item) {
      var concat;
      concat = function(memo, g) {
        return "" + memo + g + ":" + item[g] + ";";
      };
      return _.reduce(group, concat, "");
    });
  };

  /*
  Produces a linear function that passes through two points.
  Input:
  - `x1`: x coordinate of the first point
  - `y1`: y coordinate of the first point
  - `x2`: x coordinate of the second point
  - `y2`: y coordinate of the second point
  Output:
  - A function that, given the x-coord, returns the y-coord
  */

  poly.linear = function(x1, y1, x2, y2) {
    return function(x) {
      return (y2 - y1) / (x2 - x1) * (x - x1) + y1;
    };
  };

  /*
  given a sorted list and a midpoint calculate the median
  */

  poly.median = function(values, sorted) {
    var mid;
    if (sorted == null) sorted = false;
    if (!sorted) {
      values = _.sortBy(values, function(x) {
        return x;
      });
    }
    mid = values.length / 2;
    if (mid % 1 !== 0) return values[Math.floor(mid)];
    return (values[mid - 1] + values[mid]) / 2;
  };

  this.poly = poly;

  /*
  Produces a function that counts how many times it has been called
  */

  poly.counter = function() {
    var i;
    i = 0;
    return function() {
      return i++;
    };
  };

  /*
  Given an OLD array and NEW array, split the points in (OLD union NEW) into
  three sets: 
    - deleted
    - kept
    - added
  TODO: make this a one-pass algorithm
  */

  poly.compare = function(oldarr, newarr) {
    return {
      deleted: _.difference(oldarr, newarr),
      kept: _.intersection(newarr, oldarr),
      added: _.difference(newarr, oldarr)
    };
  };

  /*
  Given an aesthetic mapping in the "geom" object, flatten it and extract only
  the values from it. This is so that even if a compound object is encoded in an
  aestehtic, we have the correct set of values to calculate the min/max.
  
  TODO: handles the "novalue" case (when x or y has no mapping)
  */

  poly.flatten = function(values) {
    var flat, k, v, _i, _len;
    flat = [];
    if (values != null) {
      if (_.isObject(values)) {
        if (values.t === 'scalefn') {
          flat.push(values.v);
        } else {
          for (k in values) {
            v = values[k];
            flat = flat.concat(poly.flatten(v));
          }
        }
      } else if (_.isArray(values)) {
        for (_i = 0, _len = values.length; _i < _len; _i++) {
          v = values[_i];
          flat = flat.concat(poly.flatten(v));
        }
      } else {
        flat.push(values);
      }
    }
    return flat;
  };

  /*
  GET LABEL
  TODO: move somewhere else and allow overwrite by user
  */

  poly.getLabel = function(layers, aes) {
    return _.chain(layers).map(function(l) {
      return l.mapping[aes];
    }).without(null, void 0).uniq().value().join(' | ');
  };

  /*
  Estimate the number of pixels rendering this string would take...?
  */

  poly.strSize = function(str) {
    return (str + "").length * 7;
  };

  /*
  Sort Arrays: given a sorting function and some number of arrays, sort all the
  arrays by the function applied to the first array. This is used for sorting 
  points for a line chart, i.e. poly.sortArrays(sortFn, [xs, ys])
  
  This way, all the points are sorted by (sortFn(x) for x in xs)
  */

  poly.sortArrays = function(fn, arrays) {
    return _.zip.apply(_, _.sortBy(_.zip.apply(_, arrays), function(a) {
      return fn(a[0]);
    }));
  };

  /*
  Impute types from values
  */

  THRESHOLD = 0.95;

  poly.typeOf = function(values) {
    var date, num, value, _i, _len;
    date = 0;
    num = 0;
    for (_i = 0, _len = values.length; _i < _len; _i++) {
      value = values[_i];
      if (!(value != null)) continue;
      if (!isNaN(value) || !isNaN(value.replace(/\$|\,/g, ''))) num++;
      if (moment(value).isValid()) date++;
    }
    if (num > THRESHOLD * values.length) return 'num';
    if (date > THRESHOLD * values.length) return 'date';
    return 'cat';
  };

  /*
  Parse values into correct types
  */

  poly.coerce = function(value, meta) {
    if (meta.type === 'cat') {
      return value;
    } else if (meta.type === 'num') {
      if (!isNaN(value)) {
        return +value;
      } else {
        return +(("" + value).replace(/\$|\,/g, ''));
      }
    } else if (meta.type === 'date') {
      if (meta.format) {
        if (meta.format === 'unix') {
          return moment.unix(value).unix();
        } else {
          return moment(value, meta.format).unix();
        }
      } else {
        return moment(value).unix();
      }
    } else {
      return;
    }
  };

}).call(this);
