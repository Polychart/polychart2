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
  */

  poly.flatten = function(values) {
    var flat, k, v, _i, _len;
    flat = [];
    if (values != null) {
      if (_.isObject(values)) {
        if (values.t === 'scalefn') {
          if (values.f !== 'novalue') flat.push(values.v);
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
(function() {
  var poly;

  poly = this.poly || {};

  /*
  CONSTANTS
  ---------
  These are constants that are referred to throughout the coebase
  */

  poly["const"] = {
    aes: ['x', 'y', 'color', 'size', 'opacity', 'shape', 'id', 'text'],
    noLegend: ['x', 'y', 'id', 'text', 'tooltip'],
    trans: {
      'bin': ['key', 'binwidth'],
      'lag': ['key', 'lag']
    },
    stat: {
      'count': ['key'],
      'sum': ['key'],
      'mean': ['key'],
      'box': ['key'],
      'median': ['key']
    },
    timerange: ['second', 'minute', 'hour', 'day', 'week', 'month', 'year'],
    metas: {
      sort: null,
      stat: null,
      limit: null,
      asc: true
    },
    scaleFns: {
      novalue: function() {
        return {
          v: null,
          f: 'novalue',
          t: 'scalefn'
        };
      },
      max: function(v) {
        return {
          v: v,
          f: 'max',
          t: 'scalefn'
        };
      },
      min: function(v) {
        return {
          v: v,
          f: 'min',
          t: 'scalefn'
        };
      },
      upper: function(v) {
        return {
          v: v,
          f: 'upper',
          t: 'scalefn'
        };
      },
      lower: function(v) {
        return {
          v: v,
          f: 'lower',
          t: 'scalefn'
        };
      },
      middle: function(v) {
        return {
          v: v,
          f: 'middle',
          t: 'scalefn'
        };
      },
      jitter: function(v) {
        return {
          v: v,
          f: 'jitter',
          t: 'scalefn'
        };
      },
      identity: function(v) {
        return {
          v: v,
          f: 'identity',
          t: 'scalefn'
        };
      }
    },
    epsilon: Math.pow(10, -7),
    defaults: {
      'x': {
        v: null,
        f: 'novalue',
        t: 'scalefn'
      },
      'y': {
        v: null,
        f: 'novalue',
        t: 'scalefn'
      },
      'color': 'steelblue',
      'size': 2,
      'opacity': 0.7
    }
  };

  this.poly = poly;

}).call(this);
(function() {
  var DataError, DefinitionError, DependencyError, ModeError, NotImplemented, UnknownInput, poly,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  poly = this.poly || {};

  DefinitionError = (function(_super) {

    __extends(DefinitionError, _super);

    function DefinitionError(message) {
      this.message = message;
      this.name = "DefinitionError";
    }

    return DefinitionError;

  })(Error);

  DependencyError = (function(_super) {

    __extends(DependencyError, _super);

    function DependencyError(message) {
      this.message = message;
      this.name = "DependencyError";
    }

    return DependencyError;

  })(Error);

  ModeError = (function(_super) {

    __extends(ModeError, _super);

    function ModeError(message) {
      this.message = message;
      this.name = "ModeError";
    }

    return ModeError;

  })(Error);

  DataError = (function(_super) {

    __extends(DataError, _super);

    function DataError(message) {
      this.message = message;
      this.name = "DataError";
    }

    return DataError;

  })(Error);

  UnknownInput = (function(_super) {

    __extends(UnknownInput, _super);

    function UnknownInput(message) {
      this.message = message;
      this.name = "UnknownInput";
    }

    return UnknownInput;

  })(Error);

  NotImplemented = (function(_super) {

    __extends(NotImplemented, _super);

    function NotImplemented(message) {
      this.message = message;
      this.name = "ModeError";
    }

    return NotImplemented;

  })(Error);

  poly.error = {
    data: DataError,
    depn: DependencyError,
    defn: DefinitionError,
    mode: ModeError,
    impl: NotImplemented,
    input: UnknownInput,
    unknown: Error
  };

  this.poly = poly;

}).call(this);
(function() {
  var POSTFIXES, formatNumber, poly, postfix,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  poly = this.poly || {};

  poly.format = function(type, step) {
    switch (type) {
      case 'cat':
        return poly.format.identity;
      case 'num':
        return poly.format.number(step);
      case 'date':
        return poly.format.date(step);
    }
  };

  poly.format.identity = function(x) {
    return x;
  };

  POSTFIXES = {
    0: '',
    3: 'k',
    6: 'm',
    9: 'b',
    12: 't'
  };

  postfix = function(num, pow) {
    if (!_.isUndefined(POSTFIXES[pow])) {
      return num + POSTFIXES[pow];
    } else {
      return num + 'e' + (pow > 0 ? '+' : '-') + Math.abs(pow);
    }
  };

  formatNumber = function(n) {
    var abs, i, s, v;
    if (!isFinite(n)) return n;
    s = "" + n;
    abs = Math.abs(n);
    if (abs >= 1000) {
      v = ("" + abs).split(/\./);
      i = v[0].length % 3 || 3;
      v[0] = s.slice(0, i + (n < 0)) + v[0].slice(i).replace(/(\d{3})/g, ',$1');
      s = v.join('.');
    }
    return s;
  };

  poly.format.number = function(exp_original) {
    return function(num) {
      var exp, exp_fixed, exp_precision, rounded;
      exp_fixed = 0;
      exp_precision = 0;
      exp = exp_original != null ? exp_original : Math.floor(Math.log(Math.abs(num === 0 ? 1 : num)) / Math.LN10);
      if ((exp_original != null) && (exp === 2 || exp === 5 || exp === 8 || exp === 11)) {
        exp_fixed = exp + 1;
        exp_precision = 1;
      } else if (exp === -1) {
        exp_fixed = 0;
        exp_precision = exp_original != null ? 1 : 2;
      } else if (exp === -2) {
        exp_fixed = 0;
        exp_precision = exp_original != null ? 2 : 3;
      } else if (exp === 1 || exp === 2) {
        exp_fixed = 0;
      } else if (exp > 3 && exp < 6) {
        exp_fixed = 3;
      } else if (exp > 6 && exp < 9) {
        exp_fixed = 6;
      } else if (exp > 9 && exp < 12) {
        exp_fixed = 9;
      } else if (exp > 12 && exp < 15) {
        exp_fixed = 12;
      } else {
        exp_fixed = exp;
        exp_precision = exp_original != null ? 0 : 1;
      }
      rounded = Math.round(num / Math.pow(10, exp_fixed - exp_precision));
      rounded /= Math.pow(10, exp_precision);
      rounded = rounded.toFixed(exp_precision);
      return postfix(formatNumber(rounded), exp_fixed);
    };
  };

  poly.format.date = function(level) {
    if (!(__indexOf.call(poly["const"].timerange, level) >= 0)) level = 'day';
    if (level === 'second') {
      return function(date) {
        return moment.unix(date).format('h:mm:ss a');
      };
    } else if (level === 'minute') {
      return function(date) {
        return moment.unix(date).format('h:mm a');
      };
    } else if (level === 'hour') {
      return function(date) {
        return moment.unix(date).format('MMM D h a');
      };
    } else if (level === 'day' || level === 'week') {
      return function(date) {
        return moment.unix(date).format('MMM D');
      };
    } else if (level === 'month') {
      return function(date) {
        return moment.unix(date).format('YY/MM');
      };
    } else if (level === 'year') {
      return function(date) {
        return moment.unix(date).format('YYYY');
      };
    }
  };

}).call(this);
(function() {

  poly.xhr = function(url, mime, callback) {
    var req;
    req = new XMLHttpRequest;
    if (arguments.length < 3) {
      callback = mime;
      mime = null;
    } else if (mime && req.overrideMimeType) {
      req.overrideMimeType(mime);
    }
    req.open("GET", url, true);
    if (mime) req.setRequestHeader("Accept", mime);
    req.onreadystatechange = function() {
      var arg, s;
      if (req.readyState === 4) {
        s = req.status;
        arg = !s && req.response || s >= 200 && s < 300 || s === 304 ? req : null;
        return callback(arg);
      }
    };
    return req.send(null);
  };

  poly.text = function(url, mime, callback) {
    var ready;
    ready = function(req) {
      return callback(req && req.responseText);
    };
    if (arguments.length < 3) {
      callback = mime;
      mime = null;
    }
    return poly.xhr(url, mime, ready);
  };

  poly.json = function(url, callback) {
    return poly.text(url, "application/json", function(text) {
      return callback(text ? JSON.parse(text) : null);
    });
  };

  poly.dsv = function(delimiter, mimeType) {
    var delimiterCode, dsv, formatRow, formatValue, header, reFormat, reParse;
    reParse = new RegExp("\r\n|[" + delimiter + "\r\n]", "g");
    reFormat = new RegExp("[\"" + delimiter + "\n]");
    delimiterCode = delimiter.charCodeAt(0);
    formatRow = function(row) {
      return row.map(formatValue).join(delimiter);
    };
    formatValue = function(text) {
      var _ref;
      return (_ref = reFormat.test(text)) != null ? _ref : "\"" + text.replace(/\"/g, "\"\"") + {
        "\"": text
      };
    };
    header = null;
    dsv = function(url, callback) {
      return poly.text(url, mimeType, function(text) {
        return callback(text && dsv.parse(text));
      });
    };
    dsv.parse = function(text) {
      return dsv.parseRows(text, function(row, i) {
        var item, j, m, o;
        if (i) {
          o = {};
          j = -1;
          m = header.length;
          while (++j < m) {
            item = row[j];
            o[header[j]] = row[j];
          }
          return o;
        } else {
          header = row;
          return null;
        }
      });
    };
    dsv.parseRows = function(text, f) {
      var EOF, EOL, a, eol, n, rows, t, token;
      EOL = {};
      EOF = {};
      rows = [];
      n = 0;
      t = null;
      eol = null;
      reParse.lastIndex = 0;
      token = function() {
        var c, i, j, m;
        if (reParse.lastIndex >= text.length) return EOF;
        if (eol) {
          eol = false;
          return EOL;
        }
        j = reParse.lastIndex;
        if (text.charCodeAt(j) === 34) {
          i = j;
          while (i++ < text.length) {
            if (text.charCodeAt(i) === 34) {
              if (text.charCodeAt(i + 1) !== 34) break;
              i++;
            }
          }
          reParse.lastIndex = i + 2;
          c = text.charCodeAt(i + 1);
          if (c === 13) {
            eol = true;
            if (text.charCodeAt(i + 2) === 10) reParse.lastIndex++;
          } else if (c === 10) {
            eol = true;
          }
          return text.substring(j + 1, i).replace(/""/g, "\"");
        }
        m = reParse.exec(text);
        if (m) {
          eol = m[0].charCodeAt(0) !== delimiterCode;
          return text.substring(j, m.index);
        }
        reParse.lastIndex = text.length;
        return text.substring(j);
      };
      while ((t = token()) !== EOF) {
        a = [];
        while (t !== EOL && t !== EOF) {
          a.push(t);
          t = token();
        }
        if (f && !(a = f(a, n++))) continue;
        rows.push(a);
      }
      return rows;
    };
    dsv.format = function(rows) {
      return rows.map(formatRow).join("\n");
    };
    return dsv;
  };

  poly.csv = poly.dsv(",", "text/csv");

}).call(this);
(function() {
  var Call, Comma, Const, Expr, Ident, LParen, Literal, RParen, Stream, Symbol, Token, assocsToObj, dedup, dedupOnKey, dictGet, dictGets, expect, extractOps, layerToDataSpec, matchToken, mergeObjLists, parse, parseCall, parseCallArgs, parseConst, parseExpr, parseFail, parseSymbolic, poly, showCall, showList, tag, tokenize, tokenizers, zip, zipWith, _ref,
    __slice = Array.prototype.slice,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  poly = this.poly || {};

  zipWith = function(op) {
    return function(xs, ys) {
      var ix, xval, _len, _results;
      _results = [];
      for (ix = 0, _len = xs.length; ix < _len; ix++) {
        xval = xs[ix];
        _results.push(op(xval, ys[ix]));
      }
      return _results;
    };
  };

  zip = zipWith(function(xval, yval) {
    return [xval, yval];
  });

  assocsToObj = function(assocs) {
    var key, obj, val, _i, _len, _ref;
    obj = {};
    for (_i = 0, _len = assocs.length; _i < _len; _i++) {
      _ref = assocs[_i], key = _ref[0], val = _ref[1];
      obj[key] = val;
    }
    return obj;
  };

  dictGet = function(dict, key, defval) {
    if (defval == null) defval = null;
    return (key in dict && dict[key]) || defval;
  };

  dictGets = function(dict, keyVals) {
    var defval, final, key, val;
    final = {};
    for (key in keyVals) {
      defval = keyVals[key];
      val = dictGet(dict, key, defval);
      if (val !== null) final[key] = val;
    }
    return final;
  };

  mergeObjLists = function(dicts) {
    var dict, final, key, _i, _len;
    final = {};
    for (_i = 0, _len = dicts.length; _i < _len; _i++) {
      dict = dicts[_i];
      for (key in dict) {
        final[key] = dict[key].concat(dictGet(final, key, []));
      }
    }
    return final;
  };

  dedup = function(vals, trans) {
    var unique, val, _, _i, _len, _results;
    if (trans == null) {
      trans = function(x) {
        return x;
      };
    }
    unique = {};
    for (_i = 0, _len = vals.length; _i < _len; _i++) {
      val = vals[_i];
      unique[trans(val)] = val;
    }
    _results = [];
    for (_ in unique) {
      val = unique[_];
      _results.push(val);
    }
    return _results;
  };

  dedupOnKey = function(key) {
    return function(vals) {
      return dedup(vals, function(val) {
        return val[key];
      });
    };
  };

  showCall = function(fname, args) {
    return "" + fname + "(" + args + ")";
  };

  showList = function(xs) {
    return "[" + xs + "]";
  };

  Stream = (function() {

    function Stream(src) {
      var val;
      this.buffer = ((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = src.length; _i < _len; _i++) {
          val = src[_i];
          _results.push(val);
        }
        return _results;
      })()).reverse();
    }

    Stream.prototype.empty = function() {
      return this.buffer.length === 0;
    };

    Stream.prototype.peek = function() {
      if (this.empty()) {
        return null;
      } else {
        return this.buffer[this.buffer.length - 1];
      }
    };

    Stream.prototype.get = function() {
      if (this.empty()) {
        return null;
      } else {
        return this.buffer.pop();
      }
    };

    Stream.prototype.toString = function() {
      return showCall('Stream', showList(__slice.call(this.buffer).reverse()));
    };

    return Stream;

  })();

  Token = (function() {

    Token.Tag = {
      symbol: 'symbol',
      literal: 'literal',
      lparen: '(',
      rparen: ')',
      comma: ','
    };

    function Token(tag) {
      this.tag = tag;
    }

    Token.prototype.toString = function() {
      return "<" + (this.contents().toString()) + ">";
    };

    Token.prototype.contents = function() {
      return [this.tag];
    };

    return Token;

  })();

  Symbol = (function(_super) {

    __extends(Symbol, _super);

    function Symbol(name) {
      this.name = name;
      Symbol.__super__.constructor.call(this, Token.Tag.symbol);
    }

    Symbol.prototype.contents = function() {
      return Symbol.__super__.contents.call(this).concat([this.name]);
    };

    return Symbol;

  })(Token);

  Literal = (function(_super) {

    __extends(Literal, _super);

    function Literal(val) {
      this.val = val;
      Literal.__super__.constructor.call(this, Token.Tag.literal);
    }

    Literal.prototype.contents = function() {
      return Literal.__super__.contents.call(this).concat([this.val]);
    };

    return Literal;

  })(Token);

  _ref = (function() {
    var _i, _len, _ref, _results;
    _ref = [Token.Tag.lparen, Token.Tag.rparen, Token.Tag.comma];
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      tag = _ref[_i];
      _results.push(new Token(tag));
    }
    return _results;
  })(), LParen = _ref[0], RParen = _ref[1], Comma = _ref[2];

  tokenizers = [
    [
      /^\(/, function() {
        return LParen;
      }
    ], [
      /^\)/, function() {
        return RParen;
      }
    ], [
      /^,/, function() {
        return Comma;
      }
    ], [
      /^[+-]?(0x[0-9a-fA-F]+|0?\.\d+|[1-9]\d*(\.\d+)?|0)([eE][+-]?\d+)?/, function(val) {
        return new Literal(val);
      }
    ], [
      /^(\w|[^\u0000-\u0080])+|'((\\.)|[^\\'])+'|"((\\.)|[^\\"])+"/, function(name) {
        return new Symbol(name);
      }
    ]
  ];

  matchToken = function(str) {
    var match, op, pat, substr, _i, _len, _ref2;
    for (_i = 0, _len = tokenizers.length; _i < _len; _i++) {
      _ref2 = tokenizers[_i], pat = _ref2[0], op = _ref2[1];
      match = pat.exec(str);
      if (match) {
        substr = match[0];
        return [str.slice(substr.length), op(substr)];
      }
    }
    throw poly.error.impl("There is an error in your specification at " + str);
  };

  tokenize = function(str) {
    var tok, _ref2, _results;
    _results = [];
    while (true) {
      str = str.replace(/^\s+/, '');
      if (!str) break;
      _ref2 = matchToken(str), str = _ref2[0], tok = _ref2[1];
      _results.push(tok);
    }
    return _results;
  };

  Expr = (function() {

    function Expr() {}

    Expr.prototype.toString = function() {
      return showCall(this.constructor.name, this.contents());
    };

    return Expr;

  })();

  Ident = (function(_super) {

    __extends(Ident, _super);

    function Ident(name) {
      this.name = name;
    }

    Ident.prototype.contents = function() {
      return [this.name];
    };

    Ident.prototype.pretty = function() {
      return this.name;
    };

    Ident.prototype.visit = function(visitor) {
      return visitor.ident(this, this.name);
    };

    return Ident;

  })(Expr);

  Const = (function(_super) {

    __extends(Const, _super);

    function Const(val) {
      this.val = val;
    }

    Const.prototype.contents = function() {
      return [this.val];
    };

    Const.prototype.pretty = function() {
      return this.val;
    };

    Const.prototype.visit = function(visitor) {
      return visitor["const"](this, this.val);
    };

    return Const;

  })(Expr);

  Call = (function(_super) {

    __extends(Call, _super);

    function Call(fname, args) {
      this.fname = fname;
      this.args = args;
    }

    Call.prototype.contents = function() {
      return [this.fname, showList(this.args)];
    };

    Call.prototype.pretty = function() {
      var arg;
      return showCall(this.fname, (function() {
        var _i, _len, _ref2, _results;
        _ref2 = this.args;
        _results = [];
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          arg = _ref2[_i];
          _results.push(arg.pretty());
        }
        return _results;
      }).call(this));
    };

    Call.prototype.visit = function(visitor) {
      var arg;
      return visitor.call(this, this.fname, (function() {
        var _i, _len, _ref2, _results;
        _ref2 = this.args;
        _results = [];
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          arg = _ref2[_i];
          _results.push(arg.visit(visitor));
        }
        return _results;
      }).call(this));
    };

    return Call;

  })(Expr);

  expect = function(stream, fail, alts) {
    var express, token, _i, _len, _ref2;
    token = stream.peek();
    if (token !== null) {
      for (_i = 0, _len = alts.length; _i < _len; _i++) {
        _ref2 = alts[_i], tag = _ref2[0], express = _ref2[1];
        if (token.tag === tag) return express(stream);
      }
    }
    return fail(stream);
  };

  parseFail = function(stream) {
    throw poly.error.impl("There is an error in your specification at " + (stream.toString()));
  };

  parse = function(str) {
    var expr, stream;
    stream = new Stream(tokenize(str));
    expr = parseExpr(stream);
    if (stream.peek() !== null) {
      throw poly.error.impl("There is an error in your specification at " + (stream.toString()));
    }
    return expr;
  };

  parseExpr = function(stream) {
    return expect(stream, parseFail, [[Token.Tag.literal, parseConst], [Token.Tag.symbol, parseSymbolic]]);
  };

  parseConst = function(stream) {
    return new Const((stream.get().val));
  };

  parseSymbolic = function(stream) {
    var name;
    name = stream.get().name;
    return expect(stream, (function() {
      return new Ident(name);
    }), [[Token.Tag.lparen, parseCall(name)]]);
  };

  parseCall = function(name) {
    return function(stream) {
      var args;
      stream.get();
      args = expect(stream, parseCallArgs([]), [
        [
          Token.Tag.rparen, function(ts) {
            ts.get();
            return [];
          }
        ]
      ]);
      return new Call(name, args);
    };
  };

  parseCallArgs = function(acc) {
    return function(stream) {
      var arg, args;
      arg = parseExpr(stream);
      args = acc.concat([arg]);
      return expect(stream, parseFail, [
        [
          Token.Tag.rparen, function(ts) {
            ts.get();
            return args;
          }
        ], [
          Token.Tag.comma, function(ts) {
            ts.get();
            return (parseCallArgs(args))(ts);
          }
        ]
      ]);
    };
  };

  extractOps = function(expr) {
    var extractor, results;
    results = {
      trans: [],
      stat: []
    };
    extractor = {
      ident: function(expr, name) {
        return name;
      },
      "const": function(expr, val) {
        return val;
      },
      call: function(expr, fname, args) {
        var opargs, optype, result;
        optype = fname in poly["const"].trans ? 'trans' : fname in poly["const"].stat ? 'stat' : 'none';
        if (optype !== 'none') {
          opargs = poly["const"][optype][fname];
          result = assocsToObj(zip(opargs, args));
          result.name = expr.pretty();
          result[optype] = fname;
          results[optype].push(result);
          return result.name;
        } else {
          throw poly.error.impl("The operation " + fname + " is not recognized. Please check your specifications.");
        }
      }
    };
    expr.visit(extractor);
    return results;
  };

  layerToDataSpec = function(lspec) {
    var aesthetics, dedupByName, desc, expr, filters, groups, key, metas, name, result, sdesc, select, sexpr, stats, transstat, transstats, ts, val, _ref2, _ref3;
    filters = {};
    _ref3 = (_ref2 = lspec.filter) != null ? _ref2 : {};
    for (key in _ref3) {
      val = _ref3[key];
      filters[(parse(key)).pretty()] = val;
    }
    aesthetics = dictGets(lspec, assocsToObj((function() {
      var _i, _len, _ref4, _results;
      _ref4 = poly["const"].aes;
      _results = [];
      for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
        name = _ref4[_i];
        _results.push([name, null]);
      }
      return _results;
    })()));
    for (key in aesthetics) {
      if (!('var' in aesthetics[key])) delete aesthetics[key];
    }
    transstat = [];
    select = [];
    groups = [];
    metas = {};
    for (key in aesthetics) {
      desc = aesthetics[key];
      expr = parse(desc["var"]);
      desc["var"] = expr.pretty();
      ts = extractOps(expr);
      transstat.push(ts);
      select.push(desc["var"]);
      if (ts.stat.length === 0) groups.push(desc["var"]);
      if ('sort' in desc) {
        sdesc = dictGets(desc, poly["const"].metas);
        sexpr = parse(sdesc.sort);
        sdesc.sort = sexpr.pretty();
        result = extractOps(sexpr);
        if (result.stat.length !== 0) sdesc.stat = result.stat;
        metas[desc["var"]] = sdesc;
      }
    }
    transstats = mergeObjLists(transstat);
    dedupByName = dedupOnKey('name');
    stats = {
      stats: dedupByName(transstats.stat),
      groups: dedup(groups)
    };
    return {
      trans: dedupByName(transstats.trans),
      stats: stats,
      meta: metas,
      select: dedup(select),
      filter: filters
    };
  };

  poly.parser = {
    tokenize: tokenize,
    parse: parse,
    layerToData: layerToDataSpec
  };

  this.poly = poly;

}).call(this);
(function() {
  var Cartesian, Coordinate, Polar, poly,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  poly = this.poly || {};

  Coordinate = (function() {

    function Coordinate(params) {
      var _ref, _ref2;
      if (params == null) params = {};
      this.flip = (_ref = params.flip) != null ? _ref : false;
      this.scales = null;
      _ref2 = this.flip ? ['y', 'x'] : ['x', 'y'], this.x = _ref2[0], this.y = _ref2[1];
    }

    Coordinate.prototype.make = function(dims) {
      return this.dims = dims;
    };

    Coordinate.prototype.setScales = function(scales) {
      return this.scales = {
        x: scales.x.f,
        y: scales.y.f
      };
    };

    Coordinate.prototype.clipping = function() {
      var gb, gl, gt, h, pl, pt, w;
      pl = this.dims.paddingLeft;
      gl = this.dims.guideLeft;
      pt = this.dims.paddingTop;
      gt = this.dims.guideTop;
      gb = this.dims.guideBottom;
      w = this.dims.chartWidth;
      h = this.dims.chartHeight;
      return [pl + gl, pt + gt, w, h];
    };

    Coordinate.prototype.ranges = function() {};

    return Coordinate;

  })();

  Cartesian = (function(_super) {

    __extends(Cartesian, _super);

    function Cartesian() {
      Cartesian.__super__.constructor.apply(this, arguments);
    }

    Cartesian.prototype.type = 'cartesian';

    Cartesian.prototype.ranges = function() {
      var ranges;
      ranges = {};
      ranges[this.x] = {
        min: this.dims.paddingLeft + this.dims.guideLeft,
        max: this.dims.paddingLeft + this.dims.guideLeft + this.dims.chartWidth
      };
      ranges[this.y] = {
        min: this.dims.paddingTop + this.dims.guideTop + this.dims.chartHeight,
        max: this.dims.paddingTop + this.dims.guideTop
      };
      return ranges;
    };

    Cartesian.prototype.axisType = function(aes) {
      return this[aes];
    };

    Cartesian.prototype.getXY = function(mayflip, mark) {
      var point, scalex, scaley;
      if (mayflip) {
        point = {
          x: _.isArray(mark.x) ? _.map(mark.x, this.scales.x) : this.scales.x(mark.x),
          y: _.isArray(mark.y) ? _.map(mark.y, this.scales.y) : this.scales.y(mark.y)
        };
        return {
          x: point[this.x],
          y: point[this.y]
        };
      } else {
        scalex = this.scales[this.x];
        scaley = this.scales[this.y];
        return {
          x: _.isArray(mark.x) ? _.map(mark.x, scalex) : scalex(mark.x),
          y: _.isArray(mark.y) ? _.map(mark.y, scaley) : scaley(mark.y)
        };
      }
    };

    Cartesian.prototype.getAes = function(pixel1, pixel2, reverse) {
      return {
        x: reverse.x(pixel1[this.x], pixel2[this.x]),
        y: reverse.y(pixel1[this.y], pixel2[this.y])
      };
    };

    return Cartesian;

  })(Coordinate);

  Polar = (function(_super) {

    __extends(Polar, _super);

    function Polar() {
      this.getXY = __bind(this.getXY, this);
      Polar.__super__.constructor.apply(this, arguments);
    }

    Polar.prototype.type = 'polar';

    Polar.prototype.make = function(dims) {
      this.dims = dims;
      this.cx = this.dims.paddingLeft + this.dims.guideLeft + this.dims.chartWidth / 2;
      return this.cy = this.dims.paddingTop + this.dims.guideTop + this.dims.chartHeight / 2;
    };

    Polar.prototype.ranges = function() {
      var r, ranges, t, _ref;
      _ref = [this.x, this.y], r = _ref[0], t = _ref[1];
      ranges = {};
      ranges[t] = {
        min: 0,
        max: 2 * Math.PI
      };
      ranges[r] = {
        min: 0,
        max: Math.min(this.dims.chartWidth, this.dims.chartHeight) / 2 - 10
      };
      return ranges;
    };

    Polar.prototype.axisType = function(aes) {
      if (this[aes] === 'x') {
        return 'r';
      } else {
        return 't';
      }
    };

    Polar.prototype.getXY = function(mayflip, mark) {
      var getpos, i, ident, points, r, radius, t, theta, x, xpos, y, ypos, _getx, _gety, _len, _len2, _ref, _ref2, _ref3, _ref4,
        _this = this;
      _getx = function(radius, theta) {
        return _this.cx + radius * Math.cos(theta - Math.PI / 2);
      };
      _gety = function(radius, theta) {
        return _this.cy + radius * Math.sin(theta - Math.PI / 2);
      };
      _ref = [this.x, this.y], r = _ref[0], t = _ref[1];
      if (mayflip) {
        if (_.isArray(mark[r])) {
          points = {
            x: [],
            y: [],
            r: [],
            t: []
          };
          _ref2 = mark[r];
          for (i = 0, _len = _ref2.length; i < _len; i++) {
            radius = _ref2[i];
            radius = this.scales[r](radius);
            theta = this.scales[t](mark[t][i]);
            points.x.push(_getx(radius, theta));
            points.y.push(_gety(radius, theta));
            points.r.push(radius);
            points.t.push(theta);
          }
          return points;
        }
        radius = this.scales[r](mark[r]);
        theta = this.scales[t](mark[t]);
        return {
          x: _getx(radius, theta),
          y: _gety(radius, theta),
          r: radius,
          t: theta
        };
      }
      ident = function(obj) {
        return _.isObject(obj) && obj.t === 'scalefn' && obj.f === 'identity';
      };
      getpos = function(x, y) {
        var identx, identy;
        identx = ident(x);
        identy = ident(y);
        if (identx && !identy) {
          return {
            x: x.v,
            y: _gety(_this.scales[r](y), 0)
          };
        } else if (identx && identy) {
          return {
            x: x.v,
            y: y.v
          };
        } else if (!identx && identy) {
          return {
            y: y.v,
            x: _gety(_this.scales[t](x), 0)
          };
        } else {
          radius = _this.scales[r](y);
          theta = _this.scales[t](x);
          return {
            x: _getx(radius, theta),
            y: _gety(radius, theta)
          };
        }
      };
      if (_.isArray(mark.x)) {
        points = {
          x: [],
          y: []
        };
        _ref3 = mark.x;
        for (i = 0, _len2 = _ref3.length; i < _len2; i++) {
          xpos = _ref3[i];
          ypos = mark.y[i];
          _ref4 = getpos(xpos, ypos), x = _ref4.x, y = _ref4.y;
          points.x.push(x);
          points.y.push(y);
        }
        return points;
      }
      return getpos(mark.x, mark.y);
    };

    return Polar;

  })(Coordinate);

  poly.coord = {
    cartesian: function(params) {
      return new Cartesian(params);
    },
    polar: function(params) {
      return new Polar(params);
    }
  };

}).call(this);
(function() {
  var CategoricalDomain, DateDomain, NumericDomain, aesthetics, domainMerge, flattenGeoms, makeDomain, makeDomainSet, mergeDomainSets, mergeDomains, poly;

  poly = this.poly || {};

  /*
  # CONSTANTS
  */

  aesthetics = poly["const"].aes;

  /*
  # GLOBALS
  */

  poly.domain = {};

  /*
  Produce a domain set for each layer based on both the information in each
  layer and the specification of the guides, then merge them into one domain
  set.
  */

  poly.domain.make = function(layers, guideSpec, strictmode) {
    var domainSets, layerObj, _i, _len;
    domainSets = [];
    for (_i = 0, _len = layers.length; _i < _len; _i++) {
      layerObj = layers[_i];
      domainSets.push(makeDomainSet(layerObj, guideSpec, strictmode));
    }
    return mergeDomainSets(domainSets);
  };

  poly.domain.sortfn = function(domain) {
    switch (domain.type) {
      case 'num':
        return function(x) {
          return x;
        };
      case 'date':
        return function(x) {
          return x;
        };
      case 'cat':
        return function(x) {
          var idx;
          idx = _.indexOf(domain.levels, x);
          if (idx === -1) return idx = Infinity;
        };
    }
  };

  /*
  # CLASSES & HELPER
  */

  /*
  Domain classes
  */

  NumericDomain = (function() {

    function NumericDomain(params) {
      this.type = params.type, this.min = params.min, this.max = params.max, this.bw = params.bw;
    }

    return NumericDomain;

  })();

  DateDomain = (function() {

    function DateDomain(params) {
      this.type = params.type, this.min = params.min, this.max = params.max, this.bw = params.bw;
    }

    return DateDomain;

  })();

  CategoricalDomain = (function() {

    function CategoricalDomain(params) {
      this.type = params.type, this.levels = params.levels, this.sorted = params.sorted;
    }

    return CategoricalDomain;

  })();

  /*
  Public-ish interface for making different domain types
  */

  makeDomain = function(params) {
    switch (params.type) {
      case 'num':
        return new NumericDomain(params);
      case 'date':
        return new DateDomain(params);
      case 'cat':
        return new CategoricalDomain(params);
    }
  };

  /*
  Make a domain set. A domain set is an associate array of domains, with the
  keys being aesthetics
  */

  makeDomainSet = function(layerObj, guideSpec, strictmode) {
    var aes, bw, domain, fromspec, max, meta, min, values, _ref, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7;
    domain = {};
    for (aes in layerObj.mapping) {
      if (strictmode) {
        domain[aes] = makeDomain(guideSpec[aes]);
      } else {
        values = flattenGeoms(layerObj.geoms, aes);
        meta = (_ref = layerObj.getMeta(aes)) != null ? _ref : {};
        fromspec = function(item) {
          if (guideSpec[aes] != null) {
            return guideSpec[aes][item];
          } else {
            return null;
          }
        };
        switch (meta.type) {
          case 'num':
            bw = (_ref2 = fromspec('bw')) != null ? _ref2 : meta.bw;
            min = (_ref3 = fromspec('min')) != null ? _ref3 : _.min(values);
            max = (_ref4 = fromspec('max')) != null ? _ref4 : _.max(values) + (bw != null ? bw : 0);
            domain[aes] = makeDomain({
              type: 'num',
              min: min,
              max: max,
              bw: bw
            });
            break;
          case 'date':
            bw = (_ref5 = fromspec('bw')) != null ? _ref5 : meta.bw;
            min = (_ref6 = fromspec('min')) != null ? _ref6 : _.min(values);
            max = fromspec('max');
            if (!(max != null)) {
              max = _.max(values);
              if (bw) max = moment.unix(max).add(bw + 's', 1).unix();
            }
            domain[aes] = makeDomain({
              type: 'date',
              min: min,
              max: max,
              bw: bw
            });
            break;
          case 'cat':
            domain[aes] = makeDomain({
              type: 'cat',
              levels: (_ref7 = fromspec('levels')) != null ? _ref7 : _.uniq(values),
              sorted: fromspec('levels') != null
            });
        }
      }
    }
    return domain;
  };

  /*
  VERY preliminary flatten function. Need to optimize
  */

  flattenGeoms = function(geoms, aes) {
    var geom, k, l, mark, values, _ref;
    values = [];
    for (k in geoms) {
      geom = geoms[k];
      _ref = geom.marks;
      for (l in _ref) {
        mark = _ref[l];
        values = values.concat(poly.flatten(mark[aes]));
      }
    }
    return values;
  };

  /*
  Merge an array of domain sets: i.e. merge all the domains that shares the
  same aesthetics.
  */

  mergeDomainSets = function(domainSets) {
    var aes, domains, merged, _i, _len;
    merged = {};
    for (_i = 0, _len = aesthetics.length; _i < _len; _i++) {
      aes = aesthetics[_i];
      domains = _.without(_.pluck(domainSets, aes), void 0);
      if (domains.length > 0) merged[aes] = mergeDomains(domains);
    }
    return merged;
  };

  /*
  Helper for merging domains of the same type. Two domains of the same type
  can be merged if they share the same properties:
   - For numeric/date variables all domains must have the same binwidth parameter
   - For categorial variables, sorted domains must have any categories in common
  */

  domainMerge = {
    'num': function(domains) {
      var bw, max, min, _ref;
      bw = _.compact(_.uniq(_.map(domains, function(d) {
        return d.bw;
      })));
      if (bw.length > 1) {
        throw poly.error.data("Not all layers have the same binwidth.");
      }
      bw = (_ref = bw[0]) != null ? _ref : void 0;
      min = _.min(_.map(domains, function(d) {
        return d.min;
      }));
      max = _.max(_.map(domains, function(d) {
        return d.max;
      }));
      return makeDomain({
        type: 'num',
        min: min,
        max: max,
        bw: bw
      });
    },
    'date': function(domains) {
      var bw, max, min, _ref;
      bw = _.compact(_.uniq(_.map(domains, function(d) {
        return d.bw;
      })));
      if (bw.length > 1) {
        throw poly.error.data("Not all layers have the same binwidth.");
      }
      bw = (_ref = bw[0]) != null ? _ref : void 0;
      min = _.min(_.map(domains, function(d) {
        return d.min;
      }));
      max = _.max(_.map(domains, function(d) {
        return d.max;
      }));
      return makeDomain({
        type: 'date',
        min: min,
        max: max,
        bw: bw
      });
    },
    'cat': function(domains) {
      var levels, sortedLevels, unsortedLevels;
      sortedLevels = _.chain(domains).filter(function(d) {
        return d.sorted;
      }).map(function(d) {
        return d.levels;
      }).value();
      unsortedLevels = _.chain(domains).filter(function(d) {
        return !d.sorted;
      }).map(function(d) {
        return d.levels;
      }).value();
      if (sortedLevels.length > 0 && _.intersection.apply(this, sortedLevels)) {
        throw poly.error.data("You are trying to combine incompatiabl sorted domains in the same axis.");
      }
      sortedLevels = [_.flatten(sortedLevels, true)];
      levels = _.union.apply(this, sortedLevels.concat(unsortedLevels));
      if (sortedLevels[0].length === 0) levels = levels.sort();
      return makeDomain({
        type: 'cat',
        levels: levels,
        sorted: true
      });
    }
  };

  /*
  Merge an array of domains: Two domains can be merged if they are of the
  same type, and they share certain properties.
  */

  mergeDomains = function(domains) {
    var types;
    types = _.uniq(_.map(domains, function(d) {
      return d.type;
    }));
    if (types.length > 1) {
      throw poly.error.data("You are trying to merge data of different types in the same axis or legend.");
    }
    return domainMerge[types[0]](domains);
  };

  /*
  # EXPORT
  */

  this.poly = poly;

}).call(this);
(function() {
  var Tick, getStep, poly, tickFactory, tickValues;

  poly = this.poly || {};

  /*
  # GLOBALS
  */

  poly.tick = {};

  /*
  Produce an associate array of aesthetics to tick objects.
  */

  poly.tick.make = function(domain, guideSpec, type) {
    var formatter, numticks, step, t, tickfn, tickobjs, ticks, _i, _len, _ref, _ref2;
    step = null;
    if (guideSpec.ticks != null) {
      ticks = guideSpec.ticks;
    } else {
      numticks = (_ref = guideSpec.numticks) != null ? _ref : 5;
      _ref2 = tickValues[type](domain, numticks), ticks = _ref2.ticks, step = _ref2.step;
    }
    if (guideSpec.labels) {
      formatter = function(x) {
        var _ref3;
        return (_ref3 = guideSpec.labels[x]) != null ? _ref3 : x;
      };
    } else if (guideSpec.formatter) {
      formatter = guideSpec.formatter;
    } else {
      formatter = poly.format(type, step);
    }
    tickobjs = {};
    tickfn = tickFactory(formatter);
    for (_i = 0, _len = ticks.length; _i < _len; _i++) {
      t = ticks[_i];
      tickobjs[t] = tickfn(t);
    }
    return tickobjs;
  };

  /*
  # CLASSES & HELPERS
  */

  /*
  Tick Object.
  */

  Tick = (function() {

    function Tick(params) {
      this.location = params.location, this.value = params.value, this.index = params.index;
    }

    return Tick;

  })();

  /*
  Helper function for creating a function that creates ticks
  */

  tickFactory = function(formatter) {
    var i;
    i = 0;
    return function(value) {
      return new Tick({
        location: value,
        value: formatter(value),
        index: i++
      });
    };
  };

  /*
  Helper function for determining the size of each "step" (distance between
  ticks) for numeric scales
  */

  getStep = function(span, numticks) {
    var error, step;
    step = Math.pow(10, Math.floor(Math.log(span / numticks) / Math.LN10));
    error = numticks / span * step;
    if (error < 0.15) {
      step *= 10;
    } else if (error <= 0.35) {
      step *= 5;
    } else if (error <= 0.75) {
      step *= 2;
    }
    return step;
  };

  /*
  Function for calculating the location of ticks.
  */

  tickValues = {
    'cat': function(domain, numticks) {
      var i, item, len, step, ticks, _len, _ref;
      len = domain.levels.length;
      step = Math.max(1, Math.round(len / numticks));
      ticks = [];
      _ref = domain.levels;
      for (i = 0, _len = _ref.length; i < _len; i++) {
        item = _ref[i];
        if (i % step === 0) ticks.push(item);
      }
      return {
        ticks: ticks
      };
    },
    'num': function(domain, numticks) {
      var max, min, step, ticks, tmp;
      min = domain.min, max = domain.max;
      step = getStep(max - min, numticks);
      tmp = Math.ceil(min / step) * step;
      ticks = [];
      while (tmp < max) {
        ticks.push(tmp);
        tmp += step;
      }
      return {
        ticks: ticks,
        step: Math.floor(Math.log(step) / Math.LN10)
      };
    },
    'num-log': function(domain, numticks) {
      var exp, lg, lgmax, lgmin, max, min, num, step, tmp;
      min = domain.min, max = domain.max;
      lg = function(v) {
        return Math.log(v) / Math.LN10;
      };
      exp = function(v) {
        return Math.exp(v * Math.LN10);
      };
      lgmin = Math.max(lg(min), 0);
      lgmax = lg(max);
      step = getStep(lgmax - lgmin, numticks);
      tmp = Math.ceil(lgmin / step) * step;
      while (tmp < (lgmax + poly["const"].epsilon)) {
        if (tmp % 1 !== 0 && tmp % 1 <= 0.1) {
          tmp += step;
          continue;
        } else if (tmp % 1 > poly["const"].epsilon) {
          num = Math.floor(tmp) + lg(10 * (tmp % 1));
          if (num % 1 === 0) {
            tmp += step;
            continue;
          }
        }
        num = exp(num);
        if (num < min || num > max) {
          tmp += step;
          continue;
        }
        ticks.push(num);
      }
      return {
        ticks: ticks
      };
    },
    'date': function(domain, numticks) {
      var current, max, min, step, ticks;
      min = domain.min, max = domain.max;
      step = (max - min) / numticks;
      step = step < 1.4 * 1 ? 'second' : step < 1.4 * 60 ? 'minute' : step < 1.4 * 60 * 60 ? 'hour' : step < 1.4 * 24 * 60 * 60 ? 'day' : step < 1.4 * 7 * 24 * 60 * 60 ? 'week' : step < 1.4 * 30 * 24 * 60 * 60 ? 'month' : 'year';
      ticks = [];
      current = moment.unix(min).startOf(step);
      while (current.unix() < max) {
        ticks.push(current.unix());
        current.add(step + 's', 1);
      }
      return {
        ticks: ticks,
        step: step
      };
    }
  };

  /*
  # EXPORT
  */

  this.poly = poly;

}).call(this);
(function() {
  var Axis, Guide, Legend, RAxis, TAxis, XAxis, YAxis, poly, sf,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  poly = this.poly || {};

  sf = poly["const"].scaleFns;

  Guide = (function() {

    function Guide() {}

    Guide.prototype.getDimension = function() {
      throw poly.error.impl();
    };

    return Guide;

  })();

  Axis = (function(_super) {

    __extends(Axis, _super);

    function Axis() {
      this._modify = __bind(this._modify, this);
      this._add = __bind(this._add, this);
      this.render = __bind(this.render, this);
      this.make = __bind(this.make, this);      this.line = null;
      this.title = null;
      this.ticks = {};
      this.pts = {};
    }

    Axis.prototype.make = function(params) {
      var domain, guideSpec, type;
      domain = params.domain, type = params.type, guideSpec = params.guideSpec, this.titletext = params.titletext;
      this.ticks = poly.tick.make(domain, guideSpec, type);
      return this.maxwidth = _.max(_.map(this.ticks, function(t) {
        return poly.strSize(t.value);
      }));
    };

    Axis.prototype.render = function(dim, renderer) {
      var added, axisDim, deleted, kept, newpts, t, _i, _j, _k, _len, _len2, _len3, _ref;
      axisDim = {
        top: dim.paddingTop + dim.guideTop,
        left: dim.paddingLeft + dim.guideLeft,
        bottom: dim.paddingTop + dim.guideTop + dim.chartHeight,
        width: dim.chartWidth,
        height: dim.chartHeight
      };
      if (this.line != null) renderer.remove(this.line);
      this.line = this._renderline(renderer, axisDim);
      if (this.title != null) {
        this.title = renderer.animate(this.title, this._makeTitle(axisDim, this.titletext));
      } else {
        this.title = renderer.add(this._makeTitle(axisDim, this.titletext));
      }
      _ref = poly.compare(_.keys(this.pts), _.keys(this.ticks)), deleted = _ref.deleted, kept = _ref.kept, added = _ref.added;
      newpts = {};
      for (_i = 0, _len = kept.length; _i < _len; _i++) {
        t = kept[_i];
        newpts[t] = this._modify(renderer, this.pts[t], this.ticks[t], axisDim);
      }
      for (_j = 0, _len2 = added.length; _j < _len2; _j++) {
        t = added[_j];
        newpts[t] = this._add(renderer, this.ticks[t], axisDim);
      }
      for (_k = 0, _len3 = deleted.length; _k < _len3; _k++) {
        t = deleted[_k];
        this._delete(renderer, this.pts[t]);
      }
      this.pts = newpts;
      return this.rendered = true;
    };

    Axis.prototype._add = function(renderer, tick, axisDim) {
      var obj;
      obj = {};
      obj.tick = renderer.add(this._makeTick(axisDim, tick));
      obj.text = renderer.add(this._makeLabel(axisDim, tick));
      return obj;
    };

    Axis.prototype._delete = function(renderer, pt) {
      renderer.remove(pt.tick);
      return renderer.remove(pt.text);
    };

    Axis.prototype._modify = function(renderer, pt, tick, axisDim) {
      var obj;
      obj = {};
      obj.tick = renderer.animate(pt.tick, this._makeTick(axisDim, tick));
      obj.text = renderer.animate(pt.text, this._makeLabel(axisDim, tick));
      return obj;
    };

    Axis.prototype._renderline = function() {
      throw poly.error.impl();
    };

    Axis.prototype._makeTitle = function() {
      throw poly.error.impl();
    };

    Axis.prototype._makeTick = function() {
      throw poly.error.impl();
    };

    Axis.prototype._makeLabel = function() {
      throw poly.error.impl();
    };

    return Axis;

  })(Guide);

  XAxis = (function(_super) {

    __extends(XAxis, _super);

    function XAxis() {
      XAxis.__super__.constructor.apply(this, arguments);
    }

    XAxis.prototype._renderline = function(renderer, axisDim) {
      var x1, x2, y;
      y = sf.identity(axisDim.bottom);
      x1 = sf.identity(axisDim.left);
      x2 = sf.identity(axisDim.left + axisDim.width);
      return renderer.add({
        type: 'path',
        y: [y, y],
        x: [x1, x2],
        stroke: sf.identity('black')
      });
    };

    XAxis.prototype._makeTitle = function(axisDim, text) {
      return {
        type: 'text',
        x: sf.identity(axisDim.left + axisDim.width / 2),
        y: sf.identity(axisDim.bottom + 27),
        text: text,
        'text-anchor': 'middle'
      };
    };

    XAxis.prototype._makeTick = function(axisDim, tick) {
      return {
        type: 'path',
        x: [tick.location, tick.location],
        y: [sf.identity(axisDim.bottom), sf.identity(axisDim.bottom + 5)],
        stroke: sf.identity('black')
      };
    };

    XAxis.prototype._makeLabel = function(axisDim, tick) {
      return {
        type: 'text',
        x: tick.location,
        y: sf.identity(axisDim.bottom + 15),
        text: tick.value,
        'text-anchor': 'middle'
      };
    };

    XAxis.prototype.getDimension = function() {
      return {
        position: 'bottom',
        height: 30,
        width: 'all'
      };
    };

    return XAxis;

  })(Axis);

  YAxis = (function(_super) {

    __extends(YAxis, _super);

    function YAxis() {
      YAxis.__super__.constructor.apply(this, arguments);
    }

    YAxis.prototype._renderline = function(renderer, axisDim) {
      var x, y1, y2;
      x = sf.identity(axisDim.left);
      y1 = sf.identity(axisDim.top);
      y2 = sf.identity(axisDim.top + axisDim.height);
      return renderer.add({
        type: 'path',
        x: [x, x],
        y: [y1, y2],
        stroke: sf.identity('black')
      });
    };

    YAxis.prototype._makeTitle = function(axisDim, text) {
      return {
        type: 'text',
        x: sf.identity(axisDim.left - this.maxwidth - 15),
        y: sf.identity(axisDim.top + axisDim.height / 2),
        text: text,
        transform: 'r270',
        'text-anchor': 'middle'
      };
    };

    YAxis.prototype._makeTick = function(axisDim, tick) {
      return {
        type: 'path',
        x: [sf.identity(axisDim.left), sf.identity(axisDim.left - 5)],
        y: [tick.location, tick.location],
        stroke: sf.identity('black')
      };
    };

    YAxis.prototype._makeLabel = function(axisDim, tick) {
      return {
        type: 'text',
        x: sf.identity(axisDim.left - 7),
        y: tick.location,
        text: tick.value,
        'text-anchor': 'end'
      };
    };

    YAxis.prototype.getDimension = function() {
      return {
        position: 'left',
        height: 'all',
        width: 20 + this.maxwidth
      };
    };

    return YAxis;

  })(Axis);

  RAxis = (function(_super) {

    __extends(RAxis, _super);

    function RAxis() {
      RAxis.__super__.constructor.apply(this, arguments);
    }

    RAxis.prototype._renderline = function(renderer, axisDim) {
      var x, y1, y2;
      x = sf.identity(axisDim.left);
      y1 = sf.identity(axisDim.top);
      y2 = sf.identity(axisDim.top + axisDim.height / 2);
      return renderer.add({
        type: 'path',
        x: [x, x],
        y: [y1, y2],
        stroke: sf.identity('black')
      });
    };

    RAxis.prototype._makeTitle = function(axisDim, text) {
      return {
        type: 'text',
        x: sf.identity(axisDim.left - this.maxwidth - 15),
        y: sf.identity(axisDim.top + axisDim.height / 4),
        text: text,
        transform: 'r270',
        'text-anchor': 'middle'
      };
    };

    RAxis.prototype._makeTick = function(axisDim, tick) {
      return {
        type: 'path',
        x: [sf.identity(axisDim.left), sf.identity(axisDim.left - 5)],
        y: [tick.location, tick.location],
        stroke: sf.identity('black')
      };
    };

    RAxis.prototype._makeLabel = function(axisDim, tick) {
      return {
        type: 'text',
        x: sf.identity(axisDim.left - 7),
        y: tick.location,
        text: tick.value,
        'text-anchor': 'end'
      };
    };

    RAxis.prototype.getDimension = function() {
      return {
        position: 'left',
        height: 'all',
        width: 20 + this.maxwidth
      };
    };

    return RAxis;

  })(Axis);

  TAxis = (function(_super) {

    __extends(TAxis, _super);

    function TAxis() {
      TAxis.__super__.constructor.apply(this, arguments);
    }

    TAxis.prototype._renderline = function(renderer, axisDim) {
      var radius;
      radius = Math.min(axisDim.width, axisDim.height) / 2 - 10;
      return renderer.add({
        type: 'circle',
        x: sf.identity(axisDim.left + axisDim.width / 2),
        y: sf.identity(axisDim.top + axisDim.height / 2),
        size: sf.identity(radius),
        color: sf.identity('none'),
        stroke: sf.identity('black'),
        'stroke-width': 1
      });
    };

    TAxis.prototype._makeTitle = function(axisDim, text) {
      return {
        type: 'text',
        x: sf.identity(axisDim.left + axisDim.width / 2),
        y: sf.identity(axisDim.bottom + 27),
        text: text,
        'text-anchor': 'middle'
      };
    };

    TAxis.prototype._makeTick = function(axisDim, tick) {
      var radius;
      radius = Math.min(axisDim.width, axisDim.height) / 2 - 10;
      return {
        type: 'path',
        x: [tick.location, tick.location],
        y: [sf.max(0), sf.max(3)],
        stroke: sf.identity('black')
      };
    };

    TAxis.prototype._makeLabel = function(axisDim, tick) {
      var radius;
      radius = Math.min(axisDim.width, axisDim.height) / 2 - 10;
      return {
        type: 'text',
        x: tick.location,
        y: sf.max(12),
        text: tick.value,
        'text-anchor': 'middle'
      };
    };

    TAxis.prototype.getDimension = function() {
      return {};
    };

    return TAxis;

  })(Axis);

  Legend = (function(_super) {

    __extends(Legend, _super);

    Legend.prototype.TITLEHEIGHT = 15;

    Legend.prototype.TICKHEIGHT = 12;

    Legend.prototype.SPACING = 10;

    function Legend(aes) {
      this.aes = aes;
      this._makeTick = __bind(this._makeTick, this);
      this.make = __bind(this.make, this);
      this.rendered = false;
      this.title = null;
      this.ticks = {};
      this.pts = {};
    }

    Legend.prototype.make = function(params) {
      var domain, guideSpec, type;
      domain = params.domain, type = params.type, guideSpec = params.guideSpec, this.mapping = params.mapping, this.titletext = params.titletext;
      this.ticks = poly.tick.make(domain, guideSpec, type);
      this.height = this.TITLEHEIGHT + this.SPACING + this.TICKHEIGHT * _.size(this.ticks);
      return this.maxwidth = _.max(_.map(this.ticks, function(t) {
        return poly.strSize(t.value);
      }));
    };

    Legend.prototype.render = function(dim, renderer, offset) {
      var added, deleted, kept, legendDim, newpts, t, _i, _j, _k, _len, _len2, _len3, _ref;
      legendDim = {
        top: dim.paddingTop + dim.guideTop + offset.y,
        right: dim.paddingLeft + dim.guideLeft + dim.chartWidth + offset.x,
        width: dim.guideRight,
        height: dim.chartHeight
      };
      if (this.title != null) {
        this.title = renderer.animate(this.title, this._makeTitle(legendDim, this.titletext));
      } else {
        this.title = renderer.add(this._makeTitle(legendDim, this.titletext));
      }
      _ref = poly.compare(_.keys(this.pts), _.keys(this.ticks)), deleted = _ref.deleted, kept = _ref.kept, added = _ref.added;
      newpts = {};
      for (_i = 0, _len = deleted.length; _i < _len; _i++) {
        t = deleted[_i];
        this._delete(renderer, this.pts[t]);
      }
      for (_j = 0, _len2 = kept.length; _j < _len2; _j++) {
        t = kept[_j];
        newpts[t] = this._modify(renderer, this.pts[t], this.ticks[t], legendDim);
      }
      for (_k = 0, _len3 = added.length; _k < _len3; _k++) {
        t = added[_k];
        newpts[t] = this._add(renderer, this.ticks[t], legendDim);
      }
      return this.pts = newpts;
    };

    Legend.prototype.remove = function(renderer) {
      var i, pt, _ref;
      _ref = this.pts;
      for (i in _ref) {
        pt = _ref[i];
        this._delete(renderer, pt);
      }
      renderer.remove(this.title);
      this.title = null;
      return this.pts = {};
    };

    Legend.prototype._add = function(renderer, tick, legendDim) {
      var obj;
      obj = {};
      obj.tick = renderer.add(this._makeTick(legendDim, tick));
      obj.text = renderer.add(this._makeLabel(legendDim, tick));
      return obj;
    };

    Legend.prototype._delete = function(renderer, pt) {
      renderer.remove(pt.tick);
      return renderer.remove(pt.text);
    };

    Legend.prototype._modify = function(renderer, pt, tick, legendDim) {
      var obj;
      obj = [];
      obj.tick = renderer.animate(pt.tick, this._makeTick(legendDim, tick));
      obj.text = renderer.animate(pt.text, this._makeLabel(legendDim, tick));
      return obj;
    };

    Legend.prototype._makeLabel = function(legendDim, tick) {
      return {
        type: 'text',
        x: sf.identity(legendDim.right + 15),
        y: sf.identity(legendDim.top + (15 + tick.index * 12) + 1),
        text: tick.value,
        'text-anchor': 'start'
      };
    };

    Legend.prototype._makeTick = function(legendDim, tick) {
      var aes, obj, value, _ref;
      obj = {
        type: 'circle',
        x: sf.identity(legendDim.right + 7),
        y: sf.identity(legendDim.top + (15 + tick.index * 12)),
        color: sf.identity('steelblue')
      };
      _ref = this.mapping;
      for (aes in _ref) {
        value = _ref[aes];
        if (__indexOf.call(poly["const"].noLegend, aes) >= 0) continue;
        value = value[0];
        if (__indexOf.call(this.aes, aes) >= 0) {
          obj[aes] = tick.location;
        } else if ((value.type != null) && value.type === 'const') {
          obj[aes] = sf.identity(value.value);
        } else if (!_.isObject(value)) {
          obj[aes] = sf.identity(value);
        } else {
          obj[aes] = sf.identity(poly["const"].defaults[aes]);
        }
      }
      if (!(__indexOf.call(this.aes, 'size') >= 0)) obj.size = sf.identity(5);
      return obj;
    };

    Legend.prototype._makeTitle = function(legendDim, text) {
      return {
        type: 'text',
        x: sf.identity(legendDim.right + 5),
        y: sf.identity(legendDim.top),
        text: text,
        'text-anchor': 'start'
      };
    };

    Legend.prototype.getDimension = function() {
      return {
        position: 'right',
        height: this.height,
        width: 15 + this.maxwidth
      };
    };

    return Legend;

  })(Guide);

  poly.guide = {};

  poly.guide.axis = function(type) {
    if (type === 'x') {
      return new XAxis();
    } else if (type === 'y') {
      return new YAxis();
    } else if (type === 'r') {
      return new RAxis();
    } else if (type === 't') {
      return new TAxis();
    }
  };

  poly.guide.legend = function(aes) {
    return new Legend(aes);
  };

  this.poly = poly;

}).call(this);
(function() {
  var Area, Brewer, Color, Gradient, Gradient2, Identity, Linear, Log, Opacity, PositionScale, Scale, Shape, aesthetics, poly,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  poly = this.poly || {};

  /*
  # CONSTANTS
  */

  aesthetics = poly["const"].aes;

  /*
  # GLOBALS
  */

  poly.scale = {
    linear: function(params) {
      return new Linear(params);
    },
    log: function(params) {
      return new Log(params);
    },
    area: function(params) {
      return new Area(params);
    },
    color: function(params) {
      return new Color(params);
    },
    gradient: function(params) {
      return new Gradient(params);
    },
    identity: function(params) {
      return new Identity(params);
    },
    opacity: function(params) {
      return new Opacity(params);
    }
  };

  /*
  Scales here are objects that can construct functions that takes a value from
  the data, and returns another value that is suitable for rendering an
  attribute of that value.
  */

  Scale = (function() {

    function Scale(params) {
      this.f = null;
    }

    Scale.prototype.make = function(domain) {
      this.domain = domain;
      this.sortfn = poly.domain.sortfn(domain);
      switch (domain.type) {
        case 'num':
          return this._makeNum();
        case 'date':
          return this._makeDate();
        case 'cat':
          return this._makeCat();
      }
    };

    Scale.prototype._makeNum = function() {
      throw poly.error.impl("You are using a scale that does not support numbers");
    };

    Scale.prototype._makeDate = function() {
      throw poly.error.impl("You are using a scale that does not support dates");
    };

    Scale.prototype._makeCat = function() {
      throw poly.error.impl("You are using a scale that does not support categoies");
    };

    Scale.prototype.tickType = function() {
      switch (this.domain.type) {
        case 'num':
          return this._tickNum(this.domain);
        case 'date':
          return this._tickDate(this.domain);
        case 'cat':
          return this._tickCat(this.domain);
      }
    };

    Scale.prototype._tickNum = function() {
      return 'num';
    };

    Scale.prototype._tickDate = function() {
      return 'date';
    };

    Scale.prototype._tickCat = function() {
      return 'cat';
    };

    Scale.prototype._identityWrapper = function(y) {
      return function(x) {
        if (_.isObject(x) && x.t === 'scalefn') if (x.f === 'identity') return x.v;
        return y(x);
      };
    };

    return Scale;

  })();

  /*
  Position Scales for the x- and y-axes
  */

  PositionScale = (function(_super) {

    __extends(PositionScale, _super);

    function PositionScale(params) {
      this._catWrapper = __bind(this._catWrapper, this);
      this._dateWrapper = __bind(this._dateWrapper, this);
      this._numWrapper = __bind(this._numWrapper, this);      this.f = null;
      this.finv = null;
    }

    PositionScale.prototype.make = function(domain, range) {
      this.range = range;
      return PositionScale.__super__.make.call(this, domain);
    };

    PositionScale.prototype._numWrapper = function(domain, y) {
      var _this = this;
      return function(value) {
        var space;
        space = 0.001 * (_this.range.max > _this.range.min ? 1 : -1);
        if (_.isObject(value)) {
          if (value.t === 'scalefn') {
            if (value.f === 'identity') return value.v;
            if (value.f === 'upper') return y(value.v + domain.bw) - space;
            if (value.f === 'lower') return y(value.v) + space;
            if (value.f === 'middle') return y(value.v + domain.bw / 2);
            if (value.f === 'max') return _this.range.max + value.v;
            if (value.f === 'min') return _this.range.min + value.v;
          }
          throw poly.error.input("Unknown object " + value + " is passed to a scale");
        }
        return y(value);
      };
    };

    PositionScale.prototype._dateWrapper = function(domain, y) {
      var _this = this;
      return function(value) {
        var space, v, v1, v2;
        space = 0.001 * (_this.range.max > _this.range.min ? 1 : -1);
        if (_.isObject(value)) {
          if (value.t === 'scalefn') {
            if (value.f === 'identity') return value.v;
            if (value.f === 'upper') {
              v = moment.unix(value.v).endOf(domain.bw).unix();
              return y(v) - space;
            }
            if (value.f === 'lower') {
              v = moment.unix(value.v).startOf(domain.bw).unix();
              return y(v) + space;
            }
            if (value.f === 'middle') {
              v1 = moment.unix(value.v).endOf(domain.bw).unix();
              v2 = moment.unix(value.v).startOf(domain.bw).unix();
              return y(v1 / 2 + v2 / 2);
            }
            if (value.f === 'max') return _this.range.max + value.v;
            if (value.f === 'min') return _this.range.min + value.v;
          }
          throw poly.error.input("Unknown object " + value + " is passed to a scale");
        }
        return y(value);
      };
    };

    PositionScale.prototype._catWrapper = function(step, y) {
      var _this = this;
      return function(value) {
        var space;
        space = 0.001 * (_this.range.max > _this.range.min ? 1 : -1);
        if (_.isObject(value)) {
          if (value.t === 'scalefn') {
            if (value.f === 'identity') return value.v;
            if (value.f === 'upper') return y(value.v) + step - space;
            if (value.f === 'lower') return y(value.v) + space;
            if (value.f === 'middle') return y(value.v) + step / 2;
            if (value.f === 'max') return _this.range.max + value.v;
            if (value.f === 'min') return _this.range.min + value.v;
          }
          throw poly.error.input("Unknown object " + value + " is passed to a scale");
        }
        return y(value) + step / 2;
      };
    };

    return PositionScale;

  })(Scale);

  Linear = (function(_super) {

    __extends(Linear, _super);

    function Linear() {
      Linear.__super__.constructor.apply(this, arguments);
    }

    Linear.prototype._makeNum = function() {
      var x, y;
      y = poly.linear(this.domain.min, this.range.min, this.domain.max, this.range.max);
      x = poly.linear(this.range.min, this.domain.min, this.range.max, this.domain.max);
      this.f = this._numWrapper(this.domain, y);
      return this.finv = function(y1, y2) {
        var xs;
        xs = [x(y1), x(y2)];
        return {
          ge: _.min(xs),
          le: _.max(xs)
        };
      };
    };

    Linear.prototype._makeDate = function() {
      var x, y;
      y = poly.linear(this.domain.min, this.range.min, this.domain.max, this.range.max);
      x = poly.linear(this.range.min, this.domain.min, this.range.max, this.domain.max);
      this.f = this._dateWrapper(this.domain, y);
      return this.finv = function(y1, y2) {
        var xs;
        xs = [x(y1), x(y2)];
        return {
          ge: _.min(xs),
          le: _.max(xs)
        };
      };
    };

    Linear.prototype._makeCat = function() {
      var step, x, y,
        _this = this;
      step = (this.range.max - this.range.min) / this.domain.levels.length;
      y = function(x) {
        var i;
        i = _.indexOf(_this.domain.levels, x);
        if (i === -1) {
          return null;
        } else {
          return _this.range.min + i * step;
        }
      };
      x = function(y1, y2) {
        var i1, i2, tmp;
        if (y2 < y1) {
          tmp = y2;
          y2 = y1;
          y1 = tmp;
        }
        i1 = Math.floor(y1 / step);
        i2 = Math.ceil(y2 / step);
        return {
          "in": _this.domain.levels.slice(i1, i2 + 1 || 9e9)
        };
      };
      this.f = this._catWrapper(step, y);
      return this.finv = x;
    };

    return Linear;

  })(PositionScale);

  Log = (function(_super) {

    __extends(Log, _super);

    function Log() {
      Log.__super__.constructor.apply(this, arguments);
    }

    Log.prototype._makeNum = function() {
      var lg, x, ylin, ylininv;
      lg = Math.log;
      ylin = poly.linear(lg(this.domain.min), this.range.min, lg(this.domain.max), this.range.max);
      this.f = this._numWrapper(function(x) {
        return ylin(lg(x));
      });
      ylininv = poly.linear(this.range.min, lg(this.domain.min), this.range.max, lg(this.domain.max));
      x = function(y) {
        return Math.exp(ylininv(y));
      };
      return this.finv = function(y1, y2) {
        var xs;
        xs = [x(y1), x(y2)];
        return {
          ge: _.min(xs),
          le: _.max(xs)
        };
      };
    };

    Log.prototype._tickNum = function() {
      return 'num-log';
    };

    return Log;

  })(PositionScale);

  /*
  Other, legend-type scales for the x- and y-axes
  */

  Area = (function(_super) {

    __extends(Area, _super);

    function Area() {
      this._makeNum = __bind(this._makeNum, this);
      Area.__super__.constructor.apply(this, arguments);
    }

    Area.prototype._makeNum = function() {
      var min, sq, ylin;
      min = this.domain.min === 0 ? 0 : 1;
      sq = Math.sqrt;
      ylin = poly.linear(sq(this.domain.min), min, sq(this.domain.max), 10);
      return this.f = this._identityWrapper(function(x) {
        return ylin(sq(x));
      });
    };

    return Area;

  })(Scale);

  Opacity = (function(_super) {

    __extends(Opacity, _super);

    function Opacity() {
      this._makeNum = __bind(this._makeNum, this);
      Opacity.__super__.constructor.apply(this, arguments);
    }

    Opacity.prototype._makeNum = function() {
      var max, min;
      min = this.domain.min === 0 ? 0 : 0.1;
      max = 1;
      return this.f = this._identityWrapper(poly.linear(this.domain.min, min, this.domain.max, max));
    };

    return Opacity;

  })(Scale);

  Color = (function(_super) {

    __extends(Color, _super);

    function Color() {
      this._makeNum = __bind(this._makeNum, this);
      this._makeCat = __bind(this._makeCat, this);
      Color.__super__.constructor.apply(this, arguments);
    }

    Color.prototype._makeCat = function() {
      var h, n,
        _this = this;
      n = this.domain.levels.length;
      h = function(v) {
        return _.indexOf(_this.domain.levels, v) / n + 1 / (2 * n);
      };
      return this.f = function(value) {
        return Raphael.hsl(h(value), 0.5, 0.5);
      };
    };

    Color.prototype._makeNum = function() {
      var h;
      h = poly.linear(this.domain.min, 0, this.domain.max, 1);
      return this.f = function(value) {
        return Raphael.hsl(0.5, h(value), 0.5);
      };
    };

    return Color;

  })(Scale);

  Brewer = (function(_super) {

    __extends(Brewer, _super);

    function Brewer() {
      Brewer.__super__.constructor.apply(this, arguments);
    }

    Brewer.prototype._makeCat = function() {};

    return Brewer;

  })(Scale);

  Gradient = (function(_super) {

    __extends(Gradient, _super);

    function Gradient(params) {
      this._makeNum = __bind(this._makeNum, this);      this.lower = params.lower, this.upper = params.upper;
    }

    Gradient.prototype._makeNum = function() {
      var b, g, lower, r, upper,
        _this = this;
      lower = Raphael.color(this.lower);
      upper = Raphael.color(this.upper);
      r = poly.linear(this.domain.min, lower.r, this.domain.max, upper.r);
      g = poly.linear(this.domain.min, lower.g, this.domain.max, upper.g);
      b = poly.linear(this.domain.min, lower.b, this.domain.max, upper.b);
      return this.f = this._identityWrapper(function(value) {
        return Raphael.rgb(r(value), g(value), b(value));
      });
    };

    return Gradient;

  })(Scale);

  Gradient2 = (function(_super) {

    __extends(Gradient2, _super);

    function Gradient2(params) {
      this._makeCat = __bind(this._makeCat, this);
      var lower, upper, zero;
      lower = params.lower, zero = params.zero, upper = params.upper;
    }

    Gradient2.prototype._makeCat = function() {};

    return Gradient2;

  })(Scale);

  Shape = (function(_super) {

    __extends(Shape, _super);

    function Shape() {
      Shape.__super__.constructor.apply(this, arguments);
    }

    Shape.prototype._makeCat = function() {};

    return Shape;

  })(Scale);

  Identity = (function(_super) {

    __extends(Identity, _super);

    function Identity() {
      Identity.__super__.constructor.apply(this, arguments);
    }

    Identity.prototype.make = function() {
      this.sortfn = function(x) {
        return x;
      };
      return this.f = this._identityWrapper(function(x) {
        return x;
      });
    };

    return Identity;

  })(Scale);

  /*
  # EXPORT
  */

  this.poly = poly;

}).call(this);
(function() {
  var ScaleSet, poly,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  poly = this.poly || {};

  poly.scaleset = function(guideSpec, domains, ranges) {
    return new ScaleSet(guideSpec, domains, ranges);
  };

  ScaleSet = (function() {

    function ScaleSet(tmpRanges, coord) {
      this.axes = {
        x: poly.guide.axis(coord.axisType('x')),
        y: poly.guide.axis(coord.axisType('y'))
      };
      this.coord = coord;
      this.ranges = tmpRanges;
      this.legends = [];
      this.deletedLegends = [];
    }

    ScaleSet.prototype.make = function(guideSpec, domains, layers) {
      this.guideSpec = guideSpec;
      this.layers = layers;
      this.domains = domains;
      this.domainx = this.domains.x;
      this.domainy = this.domains.y;
      this.scales = this._makeScales(guideSpec, domains, this.ranges);
      this.reverse = {
        x: this.scales.x.finv,
        y: this.scales.y.finv
      };
      return this.layerMapping = this._mapLayers(layers);
    };

    ScaleSet.prototype.setRanges = function(ranges) {
      this.ranges = ranges;
      this._makeXScale();
      return this._makeYScale();
    };

    ScaleSet.prototype.setXDomain = function(d) {
      this.domainx = d;
      return this._makeXScale();
    };

    ScaleSet.prototype.setYDomain = function(d) {
      this.domainy = d;
      return this._makeYScale();
    };

    ScaleSet.prototype.resetDomains = function() {
      this.domainx = this.domains.x;
      this.domainy = this.domains.y;
      this._makeXScale();
      return this._makeYScale();
    };

    ScaleSet.prototype._makeXScale = function() {
      return this.scales.x.make(this.domainx, this.ranges.x);
    };

    ScaleSet.prototype._makeYScale = function() {
      return this.scales.y.make(this.domainy, this.ranges.y);
    };

    ScaleSet.prototype._makeScales = function(guideSpec, domains, ranges) {
      var scales, specScale, _ref, _ref2, _ref3, _ref4;
      specScale = function(a) {
        if (guideSpec && (guideSpec[a] != null) && (guideSpec[a].scale != null)) {
          return guideSpec[a].scale;
        }
        return null;
      };
      scales = {};
      scales.x = (_ref = specScale('x')) != null ? _ref : poly.scale.linear();
      scales.x.make(domains.x, ranges.x);
      scales.y = (_ref2 = specScale('y')) != null ? _ref2 : poly.scale.linear();
      scales.y.make(domains.y, ranges.y);
      if (domains.color != null) {
        if (domains.color.type === 'cat') {
          scales.color = (_ref3 = specScale('color')) != null ? _ref3 : poly.scale.color();
        } else {
          scales.color = (_ref4 = specScale('color')) != null ? _ref4 : poly.scale.gradient({
            upper: 'steelblue',
            lower: 'red'
          });
        }
        scales.color.make(domains.color);
      }
      if (domains.size != null) {
        scales.size = specScale('size') || poly.scale.area();
        scales.size.make(domains.size);
      }
      if (domains.opacity != null) {
        scales.opacity = specScale('opacity') || poly.scale.opacity();
        scales.opacity.make(domains.opacity);
      }
      scales.text = poly.scale.identity();
      scales.text.make();
      return scales;
    };

    ScaleSet.prototype.fromPixels = function(start, end) {
      var map, obj, x, y, _i, _j, _len, _len2, _ref, _ref2, _ref3;
      _ref = this.coord.getAes(start, end, this.reverse), x = _ref.x, y = _ref.y;
      obj = {};
      _ref2 = this.layerMapping.x;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        map = _ref2[_i];
        if ((map.type != null) && map.type === 'map') obj[map.value] = x;
      }
      _ref3 = this.layerMapping.y;
      for (_j = 0, _len2 = _ref3.length; _j < _len2; _j++) {
        map = _ref3[_j];
        if ((map.type != null) && map.type === 'map') obj[map.value] = y;
      }
      return obj;
    };

    ScaleSet.prototype.getSpec = function(a) {
      if ((this.guideSpec != null) && (this.guideSpec[a] != null)) {
        return this.guideSpec[a];
      } else {
        return {};
      }
    };

    ScaleSet.prototype.makeAxes = function() {
      this.axes.x.make({
        domain: this.domainx,
        type: this.scales.x.tickType(),
        guideSpec: this.getSpec('x'),
        titletext: poly.getLabel(this.layers, 'x')
      });
      this.axes.y.make({
        domain: this.domainy,
        type: this.scales.y.tickType(),
        guideSpec: this.getSpec('y'),
        titletext: poly.getLabel(this.layers, 'y')
      });
      return this.axes;
    };

    ScaleSet.prototype.renderAxes = function(dims, renderer) {
      this.axes.x.render(dims, renderer);
      return this.axes.y.render(dims, renderer);
    };

    ScaleSet.prototype._mapLayers = function(layers) {
      var aes, obj;
      obj = {};
      for (aes in this.domains) {
        obj[aes] = _.map(layers, function(layer) {
          if (layer.mapping[aes] != null) {
            return {
              type: 'map',
              value: layer.mapping[aes]
            };
          } else if (layer.consts[aes] != null) {
            return {
              type: 'const',
              value: layer["const"][aes]
            };
          } else {
            return layer.defaults[aes];
          }
        });
      }
      return obj;
    };

    ScaleSet.prototype._mergeAes = function(layers) {
      var aes, m, mapped, merged, merging, _i, _len;
      merging = [];
      for (aes in this.domains) {
        if (__indexOf.call(poly["const"].noLegend, aes) >= 0) continue;
        mapped = _.map(layers, function(layer) {
          return layer.mapping[aes];
        });
        if (!_.all(mapped, _.isUndefined)) {
          merged = false;
          for (_i = 0, _len = merging.length; _i < _len; _i++) {
            m = merging[_i];
            if (_.isEqual(m.mapped, mapped)) {
              m.aes.push(aes);
              merged = true;
              break;
            }
          }
          if (!merged) {
            merging.push({
              aes: [aes],
              mapped: mapped
            });
          }
        }
      }
      return _.pluck(merging, 'aes');
    };

    ScaleSet.prototype.makeLegends = function(mapping) {
      var aes, aesGroups, i, idx, legend, legenddeleted, _i, _j, _len, _len2, _ref;
      aesGroups = this._mergeAes(this.layers);
      idx = 0;
      while (idx < this.legends.length) {
        legend = this.legends[idx];
        legenddeleted = true;
        i = 0;
        while (i < aesGroups.length) {
          aes = aesGroups[i];
          if (_.isEqual(aes, legend.aes)) {
            aesGroups.splice(i, 1);
            legenddeleted = false;
            break;
          }
          i++;
        }
        if (legenddeleted) {
          this.deletedLegends.push(legend);
          this.legends.splice(idx, 1);
        } else {
          idx++;
        }
      }
      for (_i = 0, _len = aesGroups.length; _i < _len; _i++) {
        aes = aesGroups[_i];
        this.legends.push(poly.guide.legend(aes));
      }
      _ref = this.legends;
      for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
        legend = _ref[_j];
        aes = legend.aes[0];
        legend.make({
          domain: this.domains[aes],
          guideSpec: this.getSpec(aes),
          type: this.scales[aes].tickType(),
          mapping: this.layerMapping,
          titletext: poly.getLabel(this.layers, aes)
        });
      }
      return this.legends;
    };

    ScaleSet.prototype.renderLegends = function(dims, renderer) {
      var legend, maxheight, maxwidth, newdim, offset, _i, _j, _len, _len2, _ref, _ref2, _results;
      _ref = this.deletedLegends;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        legend = _ref[_i];
        legend.remove(renderer);
      }
      this.deletedLegends = [];
      offset = {
        x: 0,
        y: 0
      };
      maxwidth = 0;
      maxheight = dims.height - dims.guideTop - dims.paddingTop;
      _ref2 = this.legends;
      _results = [];
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        legend = _ref2[_j];
        newdim = legend.getDimension();
        if (newdim.height + offset.y > maxheight) {
          offset.x += maxwidth + 5;
          offset.y = 0;
          maxwidth = 0;
        }
        if (newdim.width > maxwidth) maxwidth = newdim.width;
        legend.render(dims, renderer, offset);
        _results.push(offset.y += newdim.height);
      }
      return _results;
    };

    return ScaleSet;

  })();

}).call(this);
(function() {
  var Data, DataProcess, backendProcess, calculateMeta, calculateStats, filterFactory, filters, frontendProcess, poly, statistics, statsFactory, transformFactory, transforms,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  poly = this.poly || {};

  /*
  # GLOBALS
  */

  /*
  Generalized data object that either contains JSON format of a dataset,
  or knows how to retrieve data from some source.
  */

  Data = (function() {

    function Data(params) {
      this.url = params.url, this.json = params.json, this.csv = params.csv, this.meta = params.meta;
      this.dataBackend = params.url != null;
      this.computeBackend = false;
      this.raw = null;
      if (this.meta == null) this.meta = {};
      this.subscribed = [];
    }

    Data.prototype.impute = function(json) {
      var first100, item, key, keys, _base, _i, _j, _k, _len, _len2, _len3;
      keys = _.keys(json[0]);
      first100 = json.slice(0, 100);
      for (_i = 0, _len = keys.length; _i < _len; _i++) {
        key = keys[_i];
        if ((_base = this.meta)[key] == null) _base[key] = {};
        if (!this.meta[key].type) {
          this.meta[key].type = poly.typeOf(_.pluck(first100, key));
        }
      }
      for (_j = 0, _len2 = json.length; _j < _len2; _j++) {
        item = json[_j];
        for (_k = 0, _len3 = keys.length; _k < _len3; _k++) {
          key = keys[_k];
          item[key] = poly.coerce(item[key], this.meta[key]);
        }
      }
      return this.raw = json;
    };

    Data.prototype.getRaw = function(callback) {
      var _this = this;
      if (this.json) this.raw = this.impute(this.json);
      if (this.csv) this.raw = this.impute(poly.csv.parse(this.csv));
      if (this.raw) return callback(this.raw, this.meta);
      if (this.url) {
        return poly.csv(this.url, function(csv) {
          _this.raw = _this.impute(csv);
          return callback(_this.raw, _this.meta);
        });
      }
    };

    Data.prototype.update = function(params) {
      var _this = this;
      this.json = params.json, this.csv = params.csv;
      return this.getRaw(function() {
        var fn, _i, _len, _ref, _results;
        _ref = _this.subscribed;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          fn = _ref[_i];
          _results.push(fn());
        }
        return _results;
      });
    };

    Data.prototype.subscribe = function(h) {
      if (_.indexOf(this.subscribed, h) === -1) return this.subscribed.push(h);
    };

    Data.prototype.unsubscribe = function(h) {
      return this.subscribed.splice(_.indexOf(this.subscribed, h), 1);
    };

    return Data;

  })();

  poly.Data = Data;

  /*
  Wrapper around the data processing piece that keeps track of the kind of
  data processing to be done.
  */

  DataProcess = (function() {

    function DataProcess(layerSpec, strictmode) {
      this._wrap = __bind(this._wrap, this);      this.dataObj = layerSpec.data;
      this.initialSpec = poly.parser.layerToData(layerSpec);
      this.prevSpec = null;
      this.strictmode = strictmode;
      this.statData = null;
      this.metaData = {};
    }

    DataProcess.prototype.reset = function(callback) {
      return this.make(this.initialSpec, callback);
    };

    DataProcess.prototype.make = function(spec, callback) {
      var dataSpec, wrappedCallback;
      dataSpec = poly.parser.layerToData(spec);
      wrappedCallback = this._wrap(callback);
      if (this.strictmode) wrappedCallback(this.dataObj.json, {});
      if (this.dataObj.computeBackend) {
        return backendProcess(dataSpec, this.dataObj, wrappedCallback);
      } else {
        return this.dataObj.getRaw(function(data, meta) {
          return frontendProcess(dataSpec, data, meta, wrappedCallback);
        });
      }
    };

    DataProcess.prototype._wrap = function(callback) {
      var _this = this;
      return function(data, metaData) {
        _this.statData = data;
        _this.metaData = metaData;
        return callback(_this.statData, _this.metaData);
      };
    };

    return DataProcess;

  })();

  poly.DataProcess = DataProcess;

  /*
  Temporary
  */

  poly.data = {};

  poly.data.process = function(dataObj, layerSpec, strictmode, callback) {
    var d;
    d = new DataProcess(layerSpec, strictmode);
    d.process(callback);
    return d;
  };

  /*
  TRANSFORMS
  ----------
  Key:value pair of available transformations to a function that creates that
  transformation. Also, a metadata description of the transformation is returned
  when appropriate. (e.g for binning)
  */

  transforms = {
    'bin': function(key, transSpec, meta) {
      var binFn, binwidth, name;
      name = transSpec.name, binwidth = transSpec.binwidth;
      if (meta.type === 'num') {
        if (isNaN(binwidth)) {
          throw poly.error.defn("The binwidth " + binwidth + " is invalid for a numeric varliable");
        }
        binwidth = +binwidth;
        binFn = function(item) {
          return item[name] = binwidth * Math.floor(item[key] / binwidth);
        };
        return {
          trans: binFn,
          meta: {
            bw: binwidth,
            binned: true,
            type: 'num'
          }
        };
      }
      if (meta.type === 'date') {
        if (!(__indexOf.call(poly["const"].timerange, binwidth) >= 0)) {
          throw poly.error.defn("The binwidth " + binwidth + " is invalid for a datetime varliable");
        }
        binFn = function(item) {
          return item[name] = moment.unix(item[key]).startOf(binwidth).unix();
        };
        return {
          trans: binFn,
          meta: {
            bw: binwidth,
            binned: true,
            type: 'date'
          }
        };
      }
    },
    'lag': function(key, transSpec, meta) {
      var i, lag, lagFn, lastn, name;
      name = transSpec.name, lag = transSpec.lag;
      lastn = (function() {
        var _results;
        _results = [];
        for (i = 1; 1 <= lag ? i <= lag : i >= lag; 1 <= lag ? i++ : i--) {
          _results.push(void 0);
        }
        return _results;
      })();
      lagFn = function(item) {
        lastn.push(item[key]);
        return item[name] = lastn.shift();
      };
      return {
        trans: lagFn,
        meta: {
          type: meta.type
        }
      };
    }
  };

  /*
  Helper function to figures out which transformation to create, then creates it
  */

  transformFactory = function(key, transSpec, meta) {
    return transforms[transSpec.trans](key, transSpec, meta);
  };

  /*
  FILTERS
  ----------
  Key:value pair of available filtering operations to filtering function. The
  filtering function returns true iff the data item satisfies the filtering
  criteria.
  */

  filters = {
    'lt': function(x, value) {
      return x < value;
    },
    'le': function(x, value) {
      return x <= value;
    },
    'gt': function(x, value) {
      return x > value;
    },
    'ge': function(x, value) {
      return x >= value;
    },
    'in': function(x, value) {
      return __indexOf.call(value, x) >= 0;
    }
  };

  /*
  Helper function to figures out which filter to create, then creates it
  */

  filterFactory = function(filterSpec) {
    var filterFuncs;
    filterFuncs = [];
    _.each(filterSpec, function(spec, key) {
      return _.each(spec, function(value, predicate) {
        var filter;
        filter = function(item) {
          return filters[predicate](item[key], value);
        };
        return filterFuncs.push(filter);
      });
    });
    return function(item) {
      var f, _i, _len;
      for (_i = 0, _len = filterFuncs.length; _i < _len; _i++) {
        f = filterFuncs[_i];
        if (!f(item)) return false;
      }
      return true;
    };
  };

  /*
  STATISTICS
  ----------
  Key:value pair of available statistics operations to a function that creates
  the appropriate statistical function given the spec. Each statistics function
  produces one atomic value for each group of data.
  */

  statistics = {
    sum: function(spec) {
      return function(values) {
        return _.reduce(_.without(values, void 0, null), (function(v, m) {
          return v + m;
        }), 0);
      };
    },
    count: function(spec) {
      return function(values) {
        return _.without(values, void 0, null).length;
      };
    },
    uniq: function(spec) {
      return function(values) {
        return (_.uniq(_.without(values, void 0, null))).length;
      };
    },
    min: function(spec) {
      return function(values) {
        return _.min(values);
      };
    },
    max: function(spec) {
      return function(values) {
        return _.max(values);
      };
    },
    median: function(spec) {
      return function(values) {
        return poly.median(values);
      };
    },
    box: function(spec) {
      return function(values) {
        var iqr, len, lowerBound, mid, q2, q4, quarter, sortedValues, splitValues, upperBound, _ref;
        len = values.length;
        if (len > 5) {
          mid = len / 2;
          sortedValues = _.sortBy(values, function(x) {
            return x;
          });
          quarter = Math.ceil(mid) / 2;
          if (quarter % 1 !== 0) {
            quarter = Math.floor(quarter);
            q2 = sortedValues[quarter];
            q4 = sortedValues[(len - 1) - quarter];
          } else {
            q2 = (sortedValues[quarter] + sortedValues[quarter - 1]) / 2;
            q4 = (sortedValues[len - quarter] + sortedValues[(len - quarter) - 1]) / 2;
          }
          iqr = q4 - q2;
          lowerBound = q2 - (1.5 * iqr);
          upperBound = q4 + (1.5 * iqr);
          splitValues = _.groupBy(sortedValues, function(v) {
            return v >= lowerBound && v <= upperBound;
          });
          return {
            q1: _.min(splitValues["true"]),
            q2: q2,
            q3: poly.median(sortedValues, true),
            q4: q4,
            q5: _.max(splitValues["true"]),
            outliers: (_ref = splitValues["false"]) != null ? _ref : []
          };
        }
        return {
          outliers: values
        };
      };
    }
  };

  /*
  Helper function to figures out which statistics to create, then creates it
  */

  statsFactory = function(statSpec) {
    return statistics[statSpec.stat](statSpec);
  };

  /*
  Calculate statistics
  */

  calculateStats = function(data, statSpecs) {
    var groupedData, statFuncs;
    statFuncs = {};
    _.each(statSpecs.stats, function(statSpec) {
      var key, name, statFn;
      key = statSpec.key, name = statSpec.name;
      statFn = statsFactory(statSpec);
      return statFuncs[name] = function(data) {
        return statFn(_.pluck(data, key));
      };
    });
    groupedData = poly.groupBy(data, statSpecs.groups);
    return _.map(groupedData, function(data) {
      var rep;
      rep = {};
      _.each(statSpecs.groups, function(g) {
        return rep[g] = data[0][g];
      });
      _.each(statFuncs, function(stats, name) {
        return rep[name] = stats(data);
      });
      return rep;
    });
  };

  /*
  META
  ----
  Calculations of meta properties including sorting and limiting based on the
  values of statistical calculations
  */

  calculateMeta = function(key, metaSpec, data) {
    var asc, comparator, limit, multiplier, sort, stat, statSpec, values;
    sort = metaSpec.sort, stat = metaSpec.stat, limit = metaSpec.limit, asc = metaSpec.asc;
    if (stat) {
      statSpec = {
        stats: [stat],
        groups: [key]
      };
      data = calculateStats(data, statSpec);
    }
    multiplier = asc ? 1 : -1;
    comparator = function(a, b) {
      if (a[sort] === b[sort]) return 0;
      if (a[sort] >= b[sort]) return 1 * multiplier;
      return -1 * multiplier;
    };
    data.sort(comparator);
    if (limit) data = data.slice(0, (limit - 1) + 1 || 9e9);
    values = _.uniq(_.pluck(data, key));
    return {
      meta: {
        levels: values,
        sorted: true
      },
      filter: {
        "in": values
      }
    };
  };

  /*
  GENERAL PROCESSING
  ------------------
  Coordinating the actual work being done
  */

  /*
  Perform the necessary computation in the front end
  */

  frontendProcess = function(dataSpec, rawData, metaData, callback) {
    var addMeta, additionalFilter, d, data, filter, key, meta, metaSpec, name, statSpec, trans, transSpec, _i, _j, _k, _len, _len2, _len3, _ref, _ref2, _ref3, _ref4, _ref5;
    data = _.clone(rawData);
    if (metaData == null) metaData = {};
    addMeta = function(key, meta) {
      var _ref;
      return metaData[key] = _.extend((_ref = metaData[key]) != null ? _ref : {}, meta);
    };
    if (dataSpec.trans) {
      _ref = dataSpec.trans;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        transSpec = _ref[_i];
        key = transSpec.key;
        _ref2 = transformFactory(key, transSpec, metaData[key]), trans = _ref2.trans, meta = _ref2.meta;
        for (_j = 0, _len2 = data.length; _j < _len2; _j++) {
          d = data[_j];
          trans(d);
        }
        addMeta(transSpec.name, meta);
      }
    }
    if (dataSpec.filter) data = _.filter(data, filterFactory(dataSpec.filter));
    if (dataSpec.meta) {
      additionalFilter = {};
      _ref3 = dataSpec.meta;
      for (key in _ref3) {
        metaSpec = _ref3[key];
        _ref4 = calculateMeta(key, metaSpec, data), meta = _ref4.meta, filter = _ref4.filter;
        additionalFilter[key] = filter;
        addMeta(key, meta);
      }
      data = _.filter(data, filterFactory(additionalFilter));
    }
    if (dataSpec.stats && dataSpec.stats.stats && dataSpec.stats.stats.length > 0) {
      data = calculateStats(data, dataSpec.stats);
      _ref5 = dataSpec.stats.stats;
      for (_k = 0, _len3 = _ref5.length; _k < _len3; _k++) {
        statSpec = _ref5[_k];
        name = statSpec.name;
        addMeta(name, {
          type: 'num'
        });
      }
    }
    return callback(data, metaData);
  };

  /*
  Perform the necessary computation in the backend
  */

  backendProcess = function(dataSpec, rawData, callback) {
    return console.log('backendProcess');
  };

  /*
  For debug purposes only
  */

  poly.data.frontendProcess = frontendProcess;

  /*
  # EXPORT
  */

  this.poly = poly;

}).call(this);
(function() {
  var Area, Bar, Box, Layer, Line, Path, Point, Text, Tile, aesthetics, defaults, poly, sf,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  poly = this.poly || {};

  aesthetics = poly["const"].aes;

  sf = poly["const"].scaleFns;

  defaults = {
    'x': sf.novalue(),
    'y': sf.novalue(),
    'color': 'steelblue',
    'size': 2,
    'opacity': 0.9,
    'shape': 1
  };

  poly.layer = {};

  /*
  Turns a 'non-strict' layer spec to a strict one. Specifically, the function
  (1) wraps aes mapping defined by a string in an object: "col" -> {var: "col"}
  (2) puts all the level/min/max filtering into the "filter" group
  See the layer spec definition for more information.
  */

  poly.layer.toStrictMode = function(spec) {
    var aes, _i, _len;
    for (_i = 0, _len = aesthetics.length; _i < _len; _i++) {
      aes = aesthetics[_i];
      if (spec[aes] && _.isString(spec[aes])) {
        spec[aes] = {
          "var": spec[aes]
        };
      }
    }
    return spec;
  };

  /*
  Public interface to making different layer types.
  */

  poly.layer.make = function(layerSpec, strictmode) {
    switch (layerSpec.type) {
      case 'point':
        return new Point(layerSpec, strictmode);
      case 'text':
        return new Text(layerSpec, strictmode);
      case 'line':
        return new Line(layerSpec, strictmode);
      case 'path':
        return new Path(layerSpec, strictmode);
      case 'area':
        return new Area(layerSpec, strictmode);
      case 'bar':
        return new Bar(layerSpec, strictmode);
      case 'tile':
        return new Tile(layerSpec, strictmode);
      case 'box':
        return new Box(layerSpec, strictmode);
    }
  };

  /*
  Base class for all layers
  */

  Layer = (function() {

    Layer.prototype.defaults = _.extend(defaults, {
      'size': 7
    });

    function Layer(layerSpec, strict) {
      this._makeMappings = __bind(this._makeMappings, this);
      this.render = __bind(this.render, this);
      this.reset = __bind(this.reset, this);      this.initialSpec = poly.layer.toStrictMode(layerSpec);
      this.prevSpec = null;
      this.dataprocess = new poly.DataProcess(this.initialSpec, strict);
      this.pts = {};
    }

    Layer.prototype.reset = function() {
      return this.make(this.initialSpec);
    };

    Layer.prototype.make = function(layerSpec, callback) {
      var spec,
        _this = this;
      spec = poly.layer.toStrictMode(layerSpec);
      this._makeMappings(spec);
      this.dataprocess.make(spec, function(statData, metaData) {
        _this.statData = statData;
        _this.meta = metaData;
        if (!(_this.statData != null)) {
          throw poly.error.data("No data is passed into the layer");
        }
        _this._calcGeoms();
        return callback();
      });
      return this.prevSpec = spec;
    };

    Layer.prototype._calcGeoms = function() {
      return this.geoms = {};
    };

    Layer.prototype.getMeta = function(key) {
      if (this.mapping[key]) {
        return this.meta[this.mapping[key]];
      } else {
        return {};
      }
    };

    Layer.prototype.render = function(render) {
      var added, deleted, id, kept, newpts, _i, _j, _k, _len, _len2, _len3, _ref;
      newpts = {};
      _ref = poly.compare(_.keys(this.pts), _.keys(this.geoms)), deleted = _ref.deleted, kept = _ref.kept, added = _ref.added;
      for (_i = 0, _len = deleted.length; _i < _len; _i++) {
        id = deleted[_i];
        this._delete(render, this.pts[id]);
      }
      for (_j = 0, _len2 = added.length; _j < _len2; _j++) {
        id = added[_j];
        newpts[id] = this._add(render, this.geoms[id]);
      }
      for (_k = 0, _len3 = kept.length; _k < _len3; _k++) {
        id = kept[_k];
        newpts[id] = this._modify(render, this.pts[id], this.geoms[id]);
      }
      return this.pts = newpts;
    };

    Layer.prototype._delete = function(render, points) {
      var id2, pt, _results;
      _results = [];
      for (id2 in points) {
        pt = points[id2];
        _results.push(render.remove(pt));
      }
      return _results;
    };

    Layer.prototype._modify = function(render, points, geom) {
      var id2, mark, objs, _ref;
      objs = {};
      _ref = geom.marks;
      for (id2 in _ref) {
        mark = _ref[id2];
        objs[id2] = render.animate(points[id2], mark, geom.evtData);
      }
      return objs;
    };

    Layer.prototype._add = function(render, geom) {
      var id2, mark, objs, _ref;
      objs = {};
      _ref = geom.marks;
      for (id2 in _ref) {
        mark = _ref[id2];
        objs[id2] = render.add(mark, geom.evtData);
      }
      return objs;
    };

    Layer.prototype._makeMappings = function(spec) {
      var aes, _i, _len, _results;
      this.mapping = {};
      this.consts = {};
      _results = [];
      for (_i = 0, _len = aesthetics.length; _i < _len; _i++) {
        aes = aesthetics[_i];
        if (spec[aes]) {
          if (spec[aes]["var"]) this.mapping[aes] = spec[aes]["var"];
          if (spec[aes]["const"]) {
            _results.push(this.consts[aes] = spec[aes]["const"]);
          } else {
            _results.push(void 0);
          }
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    Layer.prototype._getValue = function(item, aes) {
      if (this.mapping[aes]) return item[this.mapping[aes]];
      if (this.consts[aes]) return sf.identity(this.consts[aes]);
      return sf.identity(this.defaults[aes]);
    };

    Layer.prototype._getIdFunc = function() {
      var _this = this;
      if (this.mapping['id'] != null) {
        return function(item) {
          return _this._getValue(item, 'id');
        };
      } else {
        return poly.counter();
      }
    };

    Layer.prototype._fillZeros = function(data, all_x) {
      var data_x, item, missing, x;
      data_x = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = data.length; _i < _len; _i++) {
          item = data[_i];
          _results.push(this._getValue(item, 'x'));
        }
        return _results;
      }).call(this);
      missing = _.difference(all_x, data_x);
      return {
        x: data_x.concat(missing),
        y: ((function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = data.length; _i < _len; _i++) {
            item = data[_i];
            _results.push(this._getValue(item, 'y'));
          }
          return _results;
        }).call(this)).concat((function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = missing.length; _i < _len; _i++) {
            x = missing[_i];
            _results.push(0);
          }
          return _results;
        })())
      };
    };

    Layer.prototype._stack = function(group) {
      var data, datas, item, key, tmp, yval, _results,
        _this = this;
      datas = poly.groupBy(this.statData, group);
      _results = [];
      for (key in datas) {
        data = datas[key];
        tmp = 0;
        yval = this.mapping.y != null ? (function(item) {
          return item[_this.mapping.y];
        }) : function(item) {
          return 0;
        };
        _results.push((function() {
          var _i, _len, _results2;
          _results2 = [];
          for (_i = 0, _len = data.length; _i < _len; _i++) {
            item = data[_i];
            item.$lower = tmp;
            tmp += yval(item);
            _results2.push(item.$upper = tmp);
          }
          return _results2;
        })());
      }
      return _results;
    };

    return Layer;

  })();

  Point = (function(_super) {

    __extends(Point, _super);

    function Point() {
      Point.__super__.constructor.apply(this, arguments);
    }

    Point.prototype._calcGeoms = function() {
      var evtData, idfn, item, k, v, _i, _len, _ref, _results;
      idfn = this._getIdFunc();
      this.geoms = {};
      _ref = this.statData;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        evtData = {};
        for (k in item) {
          v = item[k];
          evtData[k] = {
            "in": [v]
          };
        }
        _results.push(this.geoms[idfn(item)] = {
          marks: {
            0: {
              type: 'circle',
              x: this._getValue(item, 'x'),
              y: this._getValue(item, 'y'),
              color: this._getValue(item, 'color'),
              size: this._getValue(item, 'size'),
              opacity: this._getValue(item, 'opacity')
            }
          },
          evtData: evtData
        });
      }
      return _results;
    };

    return Point;

  })(Layer);

  Path = (function(_super) {

    __extends(Path, _super);

    function Path() {
      Path.__super__.constructor.apply(this, arguments);
    }

    Path.prototype._calcGeoms = function() {
      var data, datas, evtData, group, idfn, item, k, key, sample, _i, _len, _results;
      group = (function() {
        var _i, _len, _ref, _results;
        _ref = _.without(_.keys(this.mapping), 'x', 'y');
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          k = _ref[_i];
          _results.push(this.mapping[k]);
        }
        return _results;
      }).call(this);
      datas = poly.groupBy(this.statData, group);
      idfn = this._getIdFunc();
      this.geoms = {};
      _results = [];
      for (k in datas) {
        data = datas[k];
        sample = data[0];
        evtData = {};
        for (_i = 0, _len = group.length; _i < _len; _i++) {
          key = group[_i];
          evtData[key] = {
            "in": [sample[key]]
          };
        }
        _results.push(this.geoms[idfn(sample)] = {
          marks: {
            0: {
              type: 'path',
              x: (function() {
                var _j, _len2, _results2;
                _results2 = [];
                for (_j = 0, _len2 = data.length; _j < _len2; _j++) {
                  item = data[_j];
                  _results2.push(this._getValue(item, 'x'));
                }
                return _results2;
              }).call(this),
              y: (function() {
                var _j, _len2, _results2;
                _results2 = [];
                for (_j = 0, _len2 = data.length; _j < _len2; _j++) {
                  item = data[_j];
                  _results2.push(this._getValue(item, 'y'));
                }
                return _results2;
              }).call(this),
              color: this._getValue(sample, 'color'),
              opacity: this._getValue(sample, 'opacity')
            }
          },
          evtData: evtData
        });
      }
      return _results;
    };

    return Path;

  })(Layer);

  Line = (function(_super) {

    __extends(Line, _super);

    function Line() {
      Line.__super__.constructor.apply(this, arguments);
    }

    Line.prototype._calcGeoms = function() {
      var all_x, data, datas, evtData, group, idfn, item, k, key, sample, x, y, _i, _len, _ref, _results;
      all_x = _.uniq((function() {
        var _i, _len, _ref, _results;
        _ref = this.statData;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          item = _ref[_i];
          _results.push(this._getValue(item, 'x'));
        }
        return _results;
      }).call(this));
      group = (function() {
        var _i, _len, _ref, _results;
        _ref = _.without(_.keys(this.mapping), 'x', 'y');
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          k = _ref[_i];
          _results.push(this.mapping[k]);
        }
        return _results;
      }).call(this);
      datas = poly.groupBy(this.statData, group);
      idfn = this._getIdFunc();
      this.geoms = {};
      _results = [];
      for (k in datas) {
        data = datas[k];
        sample = data[0];
        evtData = {};
        for (_i = 0, _len = group.length; _i < _len; _i++) {
          key = group[_i];
          evtData[key] = {
            "in": [sample[key]]
          };
        }
        _ref = this._fillZeros(data, all_x), x = _ref.x, y = _ref.y;
        _results.push(this.geoms[idfn(sample)] = {
          marks: {
            0: {
              type: 'line',
              x: x,
              y: y,
              color: this._getValue(sample, 'color'),
              opacity: this._getValue(sample, 'opacity')
            }
          },
          evtData: evtData
        });
      }
      return _results;
    };

    return Line;

  })(Layer);

  Bar = (function(_super) {

    __extends(Bar, _super);

    function Bar() {
      Bar.__super__.constructor.apply(this, arguments);
    }

    Bar.prototype._calcGeoms = function() {
      var evtData, group, idfn, item, k, v, _i, _len, _ref, _results;
      group = this.mapping.x != null ? [this.mapping.x] : [];
      this._stack(group);
      idfn = this._getIdFunc();
      this.geoms = {};
      _ref = this.statData;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        evtData = {};
        for (k in item) {
          v = item[k];
          if (k !== 'y') {
            evtData[this.mapping[k]] = {
              "in": [v]
            };
          }
        }
        _results.push(this.geoms[idfn(item)] = {
          marks: {
            0: {
              type: 'rect',
              x: [sf.lower(this._getValue(item, 'x')), sf.upper(this._getValue(item, 'x'))],
              y: [item.$lower, item.$upper],
              color: this._getValue(item, 'color'),
              opacity: this._getValue(item, 'opacity')
            }
          },
          evtData: evtData
        });
      }
      return _results;
    };

    return Bar;

  })(Layer);

  Area = (function(_super) {

    __extends(Area, _super);

    function Area() {
      Area.__super__.constructor.apply(this, arguments);
    }

    Area.prototype._calcGeoms = function() {
      var all_x, counters, data, datas, evtData, group, idfn, item, k, key, sample, x, y, y_next, y_previous, _i, _j, _k, _len, _len2, _len3, _results;
      all_x = _.uniq((function() {
        var _i, _len, _ref, _results;
        _ref = this.statData;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          item = _ref[_i];
          _results.push(this._getValue(item, 'x'));
        }
        return _results;
      }).call(this));
      counters = {};
      for (_i = 0, _len = all_x.length; _i < _len; _i++) {
        key = all_x[_i];
        counters[key] = 0;
      }
      group = (function() {
        var _j, _len2, _ref, _results;
        _ref = _.without(_.keys(this.mapping), 'x', 'y');
        _results = [];
        for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
          k = _ref[_j];
          _results.push(this.mapping[k]);
        }
        return _results;
      }).call(this);
      datas = poly.groupBy(this.statData, group);
      idfn = this._getIdFunc();
      this.geoms = {};
      _results = [];
      for (k in datas) {
        data = datas[k];
        sample = data[0];
        evtData = {};
        for (_j = 0, _len2 = group.length; _j < _len2; _j++) {
          key = group[_j];
          evtData[key] = {
            "in": [sample[key]]
          };
        }
        y_previous = (function() {
          var _k, _len3, _results2;
          _results2 = [];
          for (_k = 0, _len3 = all_x.length; _k < _len3; _k++) {
            x = all_x[_k];
            _results2.push(counters[x]);
          }
          return _results2;
        })();
        for (_k = 0, _len3 = data.length; _k < _len3; _k++) {
          item = data[_k];
          x = this._getValue(item, 'x');
          y = this._getValue(item, 'y');
          counters[x] += y;
        }
        y_next = (function() {
          var _l, _len4, _results2;
          _results2 = [];
          for (_l = 0, _len4 = all_x.length; _l < _len4; _l++) {
            x = all_x[_l];
            _results2.push(counters[x]);
          }
          return _results2;
        })();
        _results.push(this.geoms[idfn(sample)] = {
          marks: {
            0: {
              type: 'area',
              x: all_x,
              y: {
                bottom: y_previous,
                top: y_next
              },
              color: this._getValue(sample, 'color'),
              opacity: this._getValue(sample, 'opacity')
            }
          },
          evtData: evtData
        });
      }
      return _results;
    };

    return Area;

  })(Layer);

  Text = (function(_super) {

    __extends(Text, _super);

    function Text() {
      Text.__super__.constructor.apply(this, arguments);
    }

    Text.prototype._calcGeoms = function() {
      var evtData, idfn, item, k, v, _i, _len, _ref, _results;
      idfn = this._getIdFunc();
      this.geoms = {};
      _ref = this.statData;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        evtData = {};
        for (k in item) {
          v = item[k];
          evtData[k] = {
            "in": [v]
          };
        }
        _results.push(this.geoms[idfn(item)] = {
          marks: {
            0: {
              type: 'text',
              x: this._getValue(item, 'x'),
              y: this._getValue(item, 'y'),
              text: this._getValue(item, 'text'),
              color: this._getValue(item, 'color'),
              size: this._getValue(item, 'size'),
              opacity: this._getValue(item, 'opacity'),
              'text-anchor': 'center'
            }
          },
          evtData: evtData
        });
      }
      return _results;
    };

    return Text;

  })(Layer);

  Tile = (function(_super) {

    __extends(Tile, _super);

    function Tile() {
      Tile.__super__.constructor.apply(this, arguments);
    }

    Tile.prototype._calcGeoms = function() {
      var evtData, idfn, item, x, y, _i, _len, _ref, _results;
      idfn = this._getIdFunc();
      this.geoms = {};
      _ref = this.statData;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        evtData = {};
        x = this._getValue(item, 'x');
        y = this._getValue(item, 'y');
        _results.push(this.geoms[idfn(item)] = {
          marks: {
            0: {
              type: 'rect',
              x: [sf.lower(this._getValue(item, 'x')), sf.upper(this._getValue(item, 'x'))],
              y: [sf.lower(this._getValue(item, 'y')), sf.upper(this._getValue(item, 'y'))],
              color: this._getValue(item, 'color'),
              size: this._getValue(item, 'size'),
              opacity: this._getValue(item, 'opacity')
            }
          },
          evtData: evtData
        });
      }
      return _results;
    };

    return Tile;

  })(Layer);

  Box = (function(_super) {

    __extends(Box, _super);

    function Box() {
      Box.__super__.constructor.apply(this, arguments);
    }

    Box.prototype._calcGeoms = function() {
      var evtData, geom, idfn, index, item, point, x, xl, xm, xu, y, _i, _len, _len2, _ref, _ref2, _results;
      idfn = this._getIdFunc();
      this.geoms = {};
      _ref = this.statData;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        evtData = {};
        x = this._getValue(item, 'x');
        y = this._getValue(item, 'y');
        xl = sf.lower(x);
        xu = sf.upper(x);
        xm = sf.middle(x);
        geom = {
          marks: {},
          evtData: evtData
        };
        if (y.q1) {
          geom.marks = {
            iqr: {
              type: 'path',
              x: [xl, xl, xu, xu, xl],
              y: [y.q2, y.q4, y.q4, y.q2, y.q2],
              stroke: this._getValue(item, 'color'),
              fill: 'none',
              size: this._getValue(item, 'size'),
              opacity: this._getValue(item, 'opacity')
            },
            lower: {
              type: 'line',
              x: [xm, xm],
              y: [y.q1, y.q2],
              color: this._getValue(item, 'color'),
              size: this._getValue(item, 'size'),
              opacity: this._getValue(item, 'opacity')
            },
            upper: {
              type: 'line',
              x: [xm, xm],
              y: [y.q4, y.q5],
              color: this._getValue(item, 'color'),
              size: this._getValue(item, 'size'),
              opacity: this._getValue(item, 'opacity')
            },
            middle: {
              type: 'line',
              x: [xl, xu],
              y: [y.q3, y.q3],
              color: this._getValue(item, 'color'),
              size: this._getValue(item, 'size'),
              opacity: this._getValue(item, 'opacity')
            }
          };
        }
        _ref2 = y.outliers;
        for (index = 0, _len2 = _ref2.length; index < _len2; index++) {
          point = _ref2[index];
          geom.marks[index] = {
            type: 'circle',
            x: xm,
            y: point,
            color: this._getValue(item, 'color'),
            size: this._getValue(item, 'size'),
            opacity: this._getValue(item, 'opacity')
          };
        }
        _results.push(this.geoms[idfn(item)] = geom);
      }
      return _results;
    };

    return Box;

  })(Layer);

  /*
  # EXPORT
  */

  this.poly = poly;

}).call(this);
(function() {
  var poly;

  poly = this.poly || {};

  /*
  # GLOBALS
  */

  poly.dim = {};

  poly.dim.make = function(spec, axes, legends) {
    var d, dim, key, legend, maxheight, maxwidth, obj, offset, _i, _len, _ref, _ref2, _ref3, _ref4, _ref5, _ref6;
    dim = {
      width: (_ref = spec.width) != null ? _ref : 400,
      height: (_ref2 = spec.height) != null ? _ref2 : 400,
      paddingLeft: (_ref3 = spec.paddingLeft) != null ? _ref3 : 10,
      paddingRight: (_ref4 = spec.paddingRight) != null ? _ref4 : 10,
      paddingTop: (_ref5 = spec.paddingTop) != null ? _ref5 : 10,
      paddingBottom: (_ref6 = spec.paddingBottom) != null ? _ref6 : 10
    };
    dim.guideTop = 10;
    dim.guideRight = 0;
    dim.guideLeft = 5;
    dim.guideBottom = 5;
    for (key in axes) {
      obj = axes[key];
      d = obj.getDimension();
      if (d.position === 'left') {
        dim.guideLeft += d.width;
      } else if (d.position === 'right') {
        dim.guideRight += d.width;
      } else if (d.position === 'bottom') {
        dim.guideBottom += d.height;
      } else if (d.position === 'top') {
        dim.guideTop += d.height;
      }
    }
    maxheight = dim.height - dim.guideTop - dim.paddingTop;
    maxwidth = 0;
    offset = {
      x: 0,
      y: 0
    };
    for (_i = 0, _len = legends.length; _i < _len; _i++) {
      legend = legends[_i];
      d = legend.getDimension();
      if (d.height + offset.y > maxheight) {
        offset.x += maxwidth + 5;
        offset.y = 0;
        maxwidth = 0;
      }
      if (d.width > maxwidth) maxwidth = d.width;
      offset.y += d.height;
    }
    dim.guideRight = offset.x + maxwidth;
    dim.chartHeight = dim.height - dim.paddingTop - dim.paddingBottom - dim.guideTop - dim.guideBottom;
    dim.chartWidth = dim.width - dim.paddingLeft - dim.paddingRight - dim.guideLeft - dim.guideRight;
    return dim;
  };

  poly.dim.guess = function(spec) {
    var dim, _ref, _ref2, _ref3, _ref4, _ref5, _ref6;
    dim = {
      width: (_ref = spec.width) != null ? _ref : 400,
      height: (_ref2 = spec.height) != null ? _ref2 : 400,
      paddingLeft: (_ref3 = spec.paddingLeft) != null ? _ref3 : 10,
      paddingRight: (_ref4 = spec.paddingRight) != null ? _ref4 : 10,
      paddingTop: (_ref5 = spec.paddingTop) != null ? _ref5 : 10,
      paddingBottom: (_ref6 = spec.paddingBottom) != null ? _ref6 : 10,
      guideLeft: 30,
      guideRight: 40,
      guideTop: 10,
      guideBottom: 30
    };
    dim.chartHeight = dim.height - dim.paddingTop - dim.paddingBottom - dim.guideTop - dim.guideBottom;
    dim.chartWidth = dim.width - dim.paddingLeft - dim.paddingRight - dim.guideLeft - dim.guideRight;
    return dim;
  };

  /*
  # CLASSES
  */

  /*
  # EXPORT
  */

  this.poly = poly;

}).call(this);
(function() {
  var Area, Circle, CircleRect, Line, Path, Rect, Renderer, Text, poly, renderer,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  poly = this.poly || {};

  /*
  # GLOBALS
  */

  poly.paper = function(dom, w, h, handleEvent) {
    var bg, end, handler, onend, onmove, onstart, paper, start;
    if (!(typeof Raphael !== "undefined" && Raphael !== null)) {
      throw poly.error.depn("The dependency Raphael is not included.");
    }
    paper = Raphael(dom, w, h);
    bg = paper.rect(0, 0, w, h).attr('stroke-width', 0);
    bg.click(handleEvent('reset'));
    handler = handleEvent('select');
    start = end = null;
    onstart = function() {
      start = null;
      return end = null;
    };
    onmove = function(dx, dy, y, x) {
      if (start != null) {
        return end = {
          x: x,
          y: y
        };
      } else {
        return start = {
          x: x,
          y: y
        };
      }
    };
    onend = function() {
      if ((start != null) && (end != null)) {
        return handler({
          start: start,
          end: end
        });
      }
    };
    bg.drag(onmove, onstart, onend);
    return paper;
  };

  /*
  Helper function for rendering all the geoms of an object
  */

  poly.render = function(handleEvent, paper, scales, coord, mayflip, clipping) {
    return {
      add: function(mark, evtData) {
        var pt;
        pt = renderer[coord.type][mark.type].render(paper, scales, coord, mark, mayflip);
        if (clipping != null) pt.attr('clip-rect', clipping);
        if (evtData && _.keys(evtData).length > 0) {
          pt.data('e', evtData);
          pt.click(handleEvent('click'));
          pt.hover(handleEvent('mover'), handleEvent('mout'));
        }
        return pt;
      },
      remove: function(pt) {
        return pt.remove();
      },
      animate: function(pt, mark, evtData) {
        renderer[coord.type][mark.type].animate(pt, scales, coord, mark, mayflip);
        if (evtData && _.keys(evtData).length > 0) pt.data('e', evtData);
        return pt;
      }
    };
  };

  Renderer = (function() {

    function Renderer() {}

    Renderer.prototype.render = function(paper, scales, coord, mark, mayflip) {
      var k, pt, v, _ref;
      pt = this._make(paper);
      _ref = this.attr(scales, coord, mark, mayflip);
      for (k in _ref) {
        v = _ref[k];
        pt.attr(k, v);
      }
      return pt;
    };

    Renderer.prototype._make = function() {
      throw poly.error.impl();
    };

    Renderer.prototype.animate = function(pt, scales, coord, mark, mayflip) {
      return pt.animate(this.attr(scales, coord, mark, mayflip), 300);
    };

    Renderer.prototype.attr = function(scales, coord, mark, mayflip) {
      throw poly.error.impl();
    };

    Renderer.prototype._makePath = function(xs, ys, type) {
      var path;
      if (type == null) type = 'L';
      path = _.map(xs, function(x, i) {
        return (i === 0 ? 'M' : type) + x + ' ' + ys[i];
      });
      return path.join(' ');
    };

    Renderer.prototype._maybeApply = function(scales, mark, key) {
      var val;
      val = mark[key];
      if (_.isObject(val) && val.f === 'identity') {
        return val.v;
      } else if (scales[key] != null) {
        return scales[key].f(val);
      } else {
        return val;
      }
    };

    return Renderer;

  })();

  Circle = (function(_super) {

    __extends(Circle, _super);

    function Circle() {
      Circle.__super__.constructor.apply(this, arguments);
    }

    Circle.prototype._make = function(paper) {
      return paper.circle();
    };

    Circle.prototype.attr = function(scales, coord, mark, mayflip) {
      var stroke, x, y, _ref, _ref2;
      _ref = coord.getXY(mayflip, mark), x = _ref.x, y = _ref.y;
      stroke = mark.stroke ? this._maybeApply(scales, mark, 'stroke') : this._maybeApply(scales, mark, 'color');
      return {
        cx: x,
        cy: y,
        r: this._maybeApply(scales, mark, 'size'),
        fill: this._maybeApply(scales, mark, 'color'),
        opacity: this._maybeApply(scales, mark, 'opacity'),
        stroke: stroke,
        title: 'omgthisiscool!',
        'stroke-width': (_ref2 = mark['stroke-width']) != null ? _ref2 : '0px'
      };
    };

    return Circle;

  })(Renderer);

  Path = (function(_super) {

    __extends(Path, _super);

    function Path() {
      Path.__super__.constructor.apply(this, arguments);
    }

    Path.prototype._make = function(paper) {
      return paper.path();
    };

    Path.prototype.attr = function(scales, coord, mark, mayflip) {
      var stroke, x, y, _ref;
      _ref = coord.getXY(mayflip, mark), x = _ref.x, y = _ref.y;
      stroke = mark.stroke ? this._maybeApply(scales, mark, 'stroke') : this._maybeApply(scales, mark, 'color');
      return {
        path: this._makePath(x, y),
        opacity: this._maybeApply(scales, mark, 'opacity'),
        stroke: stroke
      };
    };

    return Path;

  })(Renderer);

  Line = (function(_super) {

    __extends(Line, _super);

    function Line() {
      Line.__super__.constructor.apply(this, arguments);
    }

    Line.prototype._make = function(paper) {
      return paper.path();
    };

    Line.prototype.attr = function(scales, coord, mark, mayflip) {
      var stroke, x, y, _ref, _ref2;
      _ref = poly.sortArrays(scales.x.sortfn, [mark.x, mark.y]), mark.x = _ref[0], mark.y = _ref[1];
      _ref2 = coord.getXY(mayflip, mark), x = _ref2.x, y = _ref2.y;
      stroke = mark.stroke ? this._maybeApply(scales, mark, 'stroke') : this._maybeApply(scales, mark, 'color');
      return {
        path: this._makePath(x, y),
        stroke: stroke,
        opacity: this._maybeApply(scales, mark, 'opacity')
      };
    };

    return Line;

  })(Renderer);

  Area = (function(_super) {

    __extends(Area, _super);

    function Area() {
      Area.__super__.constructor.apply(this, arguments);
    }

    Area.prototype._make = function(paper) {
      return paper.path();
    };

    Area.prototype.attr = function(scales, coord, mark, mayflip) {
      var bottom, top, x, y, _ref, _ref2;
      _ref = poly.sortArrays(scales.x.sortfn, [mark.x, mark.y.top]), x = _ref[0], y = _ref[1];
      top = coord.getXY(mayflip, {
        x: x,
        y: y
      });
      _ref2 = poly.sortArrays((function(a) {
        return -scales.x.sortfn(a);
      }), [mark.x, mark.y.bottom]), x = _ref2[0], y = _ref2[1];
      bottom = coord.getXY(mayflip, {
        x: x,
        y: y
      });
      x = top.x.concat(bottom.x);
      y = top.y.concat(bottom.y);
      return {
        path: this._makePath(x, y),
        stroke: this._maybeApply(scales, mark, 'color'),
        opacity: this._maybeApply(scales, mark, 'opacity'),
        fill: this._maybeApply(scales, mark, 'color'),
        'stroke-width': '0px'
      };
    };

    return Area;

  })(Renderer);

  Rect = (function(_super) {

    __extends(Rect, _super);

    function Rect() {
      Rect.__super__.constructor.apply(this, arguments);
    }

    Rect.prototype._make = function(paper) {
      return paper.rect();
    };

    Rect.prototype.attr = function(scales, coord, mark, mayflip) {
      var x, y, _ref;
      _ref = coord.getXY(mayflip, mark), x = _ref.x, y = _ref.y;
      return {
        x: _.min(x),
        y: _.min(y),
        width: Math.abs(x[1] - x[0]),
        height: Math.abs(y[1] - y[0]),
        fill: this._maybeApply(scales, mark, 'color'),
        stroke: this._maybeApply(scales, mark, 'color'),
        opacity: this._maybeApply(scales, mark, 'opacity'),
        'stroke-width': '0px'
      };
    };

    return Rect;

  })(Renderer);

  CircleRect = (function(_super) {

    __extends(CircleRect, _super);

    function CircleRect() {
      CircleRect.__super__.constructor.apply(this, arguments);
    }

    CircleRect.prototype._make = function(paper) {
      return paper.path();
    };

    CircleRect.prototype.attr = function(scales, coord, mark, mayflip) {
      var large, path, r, t, x, x0, x1, y, y0, y1, _ref, _ref2, _ref3;
      _ref = mark.x, x0 = _ref[0], x1 = _ref[1];
      _ref2 = mark.y, y0 = _ref2[0], y1 = _ref2[1];
      mark.x = [x0, x0, x1, x1];
      mark.y = [y0, y1, y1, y0];
      _ref3 = coord.getXY(mayflip, mark), x = _ref3.x, y = _ref3.y, r = _ref3.r, t = _ref3.t;
      if (coord.flip) {
        x.push(x.splice(0, 1)[0]);
        y.push(y.splice(0, 1)[0]);
        r.push(r.splice(0, 1)[0]);
        t.push(t.splice(0, 1)[0]);
      }
      large = Math.abs(t[1] - t[0]) > Math.PI ? 1 : 0;
      path = "M " + x[0] + " " + y[0] + " A " + r[0] + " " + r[0] + " 0 " + large + " 1 " + x[1] + " " + y[1];
      large = Math.abs(t[3] - t[2]) > Math.PI ? 1 : 0;
      path += "L " + x[2] + " " + y[2] + " A " + r[2] + " " + r[2] + " 0 " + large + " 0 " + x[3] + " " + y[3] + " Z";
      return {
        path: path,
        fill: this._maybeApply(scales, mark, 'color'),
        stroke: this._maybeApply(scales, mark, 'color'),
        opacity: this._maybeApply(scales, mark, 'opacity'),
        'stroke-width': '0px'
      };
    };

    return CircleRect;

  })(Renderer);

  "class HLine extends Renderer # for both cartesian & polar?\n  _make: (paper) -> paper.path()\n  attr: (scales, coord, mark) ->\n    y = scales.y mark.y\n    path: @_makePath([0, 100000], [y, y])\n    stroke: 'black'\n    'stroke-width': '1px'\n\nclass VLine extends Renderer # for both cartesian & polar?\n  _make: (paper) -> paper.path()\n  attr: (scales, coord, mark) ->\n    x = scales.x mark.x\n    path: @_makePath([x, x], [0, 100000])\n    stroke: 'black'\n    'stroke-width': '1px'";

  Text = (function(_super) {

    __extends(Text, _super);

    function Text() {
      Text.__super__.constructor.apply(this, arguments);
    }

    Text.prototype._make = function(paper) {
      return paper.text();
    };

    Text.prototype.attr = function(scales, coord, mark, mayflip) {
      var m, x, y, _ref, _ref2;
      _ref = coord.getXY(mayflip, mark), x = _ref.x, y = _ref.y;
      m = {
        x: x,
        y: y,
        r: 10,
        text: this._maybeApply(scales, mark, 'text'),
        'text-anchor': (_ref2 = mark['text-anchor']) != null ? _ref2 : 'left',
        fill: this._maybeApply(scales, mark, 'color') || 'black'
      };
      if (mark.transform != null) m.transform = mark.transform;
      return m;
    };

    return Text;

  })(Renderer);

  renderer = {
    cartesian: {
      circle: new Circle(),
      line: new Line(),
      area: new Area(),
      path: new Path(),
      text: new Text(),
      rect: new Rect()
    },
    polar: {
      circle: new Circle(),
      path: new Path(),
      line: new Line(),
      area: new Area(),
      text: new Text(),
      rect: new CircleRect()
    }
  };

}).call(this);
(function() {
  var Graph, poly,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  poly = this.poly || {};

  Graph = (function() {

    function Graph(spec) {
      this._legacy = __bind(this._legacy, this);
      this.handleEvent = __bind(this.handleEvent, this);
      this.merge = __bind(this.merge, this);
      this.reset = __bind(this.reset, this);
      var _ref;
      if (!(spec != null)) {
        throw poly.error.defn("No graph specification is passed in!");
      }
      this.handlers = [];
      this.layers = null;
      this.scaleSet = null;
      this.axes = null;
      this.legends = null;
      this.dims = null;
      this.paper = null;
      this.coord = (_ref = spec.coord) != null ? _ref : poly.coord.cartesian();
      this.initial_spec = spec;
      this.dataSubscribed = false;
      this.make(spec);
    }

    Graph.prototype.reset = function() {
      if (!(this.initial_spec != null)) {
        throw poly.error.defn("No graph specification is passed in!");
      }
      return this.make(this.initial_spec);
    };

    Graph.prototype.make = function(spec) {
      var dataChange, id, layerObj, merge, _len, _len2, _ref, _ref2, _results;
      if (spec == null) spec = this.initial_spec;
      this.spec = spec;
      if (!(spec.layers != null)) {
        throw poly.error.defn("No layers are defined in the specification.");
      }
      if (this.layers == null) this.layers = this._makeLayers(this.spec);
      if (!this.dataSubscribed) {
        dataChange = this.handleEvent('data');
        _ref = this.layers;
        for (id = 0, _len = _ref.length; id < _len; id++) {
          layerObj = _ref[id];
          if (!(spec.layers[id].data != null)) {
            throw poly.error.defn("Layer " + id + " does not have data to plot!");
          }
          spec.layers[id].data.subscribe(dataChange);
        }
        this.dataSubscribed = true;
      }
      merge = _.after(this.layers.length, this.merge);
      _ref2 = this.layers;
      _results = [];
      for (id = 0, _len2 = _ref2.length; id < _len2; id++) {
        layerObj = _ref2[id];
        _results.push(layerObj.make(spec.layers[id], merge));
      }
      return _results;
    };

    Graph.prototype.merge = function() {
      var clipping, dom, domains, layer, renderer, scales, _i, _len, _ref;
      domains = this._makeDomains(this.spec, this.layers);
      if (this.scaleSet == null) {
        this.scaleSet = this._makeScaleSet(this.spec, domains);
      }
      this.scaleSet.make(this.spec.guides, domains, this.layers);
      if (!this.dims) {
        this.dims = this._makeDimensions(this.spec, this.scaleSet);
        this.coord.make(this.dims);
        this.ranges = this.coord.ranges();
      }
      this.scaleSet.setRanges(this.ranges);
      this._legacy(domains);
      if (!this.spec.dom) {
        throw poly.error.defn("No DOM element specified. Where to make plot?");
      }
      dom = this.spec.dom;
      scales = this.scaleSet.scales;
      this.coord.setScales(scales);
      if (this.paper == null) {
        this.paper = this._makePaper(dom, this.dims.width, this.dims.height, this.handleEvent);
      }
      clipping = this.coord.clipping(this.dims);
      renderer = poly.render(this.handleEvent, this.paper, scales, this.coord, true, clipping);
      _ref = this.layers;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        layer = _ref[_i];
        layer.render(renderer);
      }
      renderer = poly.render(this.handleEvent, this.paper, scales, this.coord, false);
      this.scaleSet.makeAxes();
      this.scaleSet.renderAxes(this.dims, renderer);
      this.scaleSet.makeLegends();
      return this.scaleSet.renderLegends(this.dims, renderer);
    };

    Graph.prototype.addHandler = function(h) {
      return this.handlers.push(h);
    };

    Graph.prototype.removeHandler = function(h) {
      return this.handlers.splice(_.indexOf(this.handlers, h), 1);
    };

    Graph.prototype.handleEvent = function(type) {
      var graph, handler;
      graph = this;
      handler = function(params) {
        var end, h, obj, start, _i, _len, _ref, _results;
        obj = this;
        if (type === 'select') {
          start = params.start, end = params.end;
          obj.evtData = graph.scaleSet.fromPixels(start, end);
        } else if (type === 'data') {
          obj.evtData = {};
        } else {
          obj.evtData = obj.data('e');
        }
        _ref = graph.handlers;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          h = _ref[_i];
          if (_.isFunction(h)) {
            _results.push(h(type, obj));
          } else {
            _results.push(h.handle(type, obj));
          }
        }
        return _results;
      };
      return _.throttle(handler, 1000);
    };

    Graph.prototype._makeLayers = function(spec) {
      return _.map(spec.layers, function(layerSpec) {
        return poly.layer.make(layerSpec, spec.strict);
      });
    };

    Graph.prototype._makeDomains = function(spec, layers) {
      if (spec.guides == null) spec.guides = {};
      return poly.domain.make(layers, spec.guides, spec.strict);
    };

    Graph.prototype._makeScaleSet = function(spec, domains) {
      var tmpRanges;
      this.coord.make(poly.dim.guess(spec));
      tmpRanges = this.coord.ranges();
      return poly.scaleset(tmpRanges, this.coord);
    };

    Graph.prototype._makeDimensions = function(spec, scaleSet) {
      return poly.dim.make(spec, scaleSet.makeAxes(), scaleSet.makeLegends());
    };

    Graph.prototype._makePaper = function(dom, width, height, handleEvent) {
      var paper;
      return paper = poly.paper(document.getElementById(dom), width, height, handleEvent);
    };

    Graph.prototype._legacy = function(domains) {
      var axes, k, v, _results;
      this.domains = domains;
      this.scales = this.scaleSet.scales;
      axes = this.scaleSet.makeAxes();
      this.ticks = {};
      _results = [];
      for (k in axes) {
        v = axes[k];
        _results.push(this.ticks[k] = v.ticks);
      }
      return _results;
    };

    return Graph;

  })();

  poly.chart = function(spec) {
    return new Graph(spec);
  };

  this.poly = poly;

}).call(this);
