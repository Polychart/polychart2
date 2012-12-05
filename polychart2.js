(function() {
  var poly;

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
    var flat;
    flat = [];
    if (values != null) {
      if (_.isObject(values)) {
        if (values.t === 'scalefn') {
          flat.push(values.v);
        } else {
          _.each(values, function(v) {
            return flat = flat.concat(poly.flatten(v));
          });
        }
      } else if (_.isArray(values)) {
        _.each(values, function(v) {
          return flat = flat.concat(poly.flatten(v));
        });
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
    aes: ['x', 'y', 'color', 'size', 'opacity', 'shape', 'id'],
    trans: {
      'bin': ['key', 'binwidth'],
      'lag': ['key', 'lag']
    },
    stat: {
      'count': ['key'],
      'sum': ['key'],
      'mean': ['key']
    },
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
  var LengthError, NotImplemented, StrictModeError, UnexpectedObject, UnknownError, poly,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  poly = this.poly || {};

  NotImplemented = (function(_super) {

    __extends(NotImplemented, _super);

    function NotImplemented(message) {
      this.message = message != null ? message : "Not implemented";
      this.name = "NotImplemented";
    }

    return NotImplemented;

  })(Error);

  poly.NotImplemented = NotImplemented;

  UnexpectedObject = (function(_super) {

    __extends(UnexpectedObject, _super);

    function UnexpectedObject(message) {
      this.message = message != null ? message : "Unexpected Object";
      this.name = "UnexpectedObject";
    }

    return UnexpectedObject;

  })(Error);

  poly.UnexpectedObject = UnexpectedObject;

  StrictModeError = (function(_super) {

    __extends(StrictModeError, _super);

    function StrictModeError(message) {
      this.message = message != null ? message : "Can't use strict mode here";
      this.name = "StrictModeError";
    }

    return StrictModeError;

  })(Error);

  poly.StrictModeError = StrictModeError;

  LengthError = (function(_super) {

    __extends(LengthError, _super);

    function LengthError(message) {
      this.message = message != null ? message : "Unexpected length";
      this.name = "LengthError";
    }

    return LengthError;

  })(Error);

  poly.LengthError = LengthError;

  UnknownError = (function(_super) {

    __extends(UnknownError, _super);

    function UnknownError(message) {
      this.message = message != null ? message : "Unknown error";
      this.name = "UnknownError";
    }

    return UnknownError;

  })(Error);

  poly.UnknownError = UnknownError;

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
      if (xs.length !== ys.length) {
        throw Error("zipWith: lists have different length: [" + xs + "], [" + ys + "]");
      }
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
    throw new Error("cannot tokenize: " + str);
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
    throw Error("unable to parse: " + (stream.toString()));
  };

  parse = function(str) {
    var expr, stream;
    stream = new Stream(tokenize(str));
    expr = parseExpr(stream);
    if (stream.peek() !== null) {
      throw Error("expected end of stream, but found: " + (stream.toString()));
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
          throw Error("unknown operation: " + fname);
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

  poly.spec = {
    tokenize: tokenize,
    parse: parse,
    layerToData: layerToDataSpec
  };

  this.poly = poly;

  /*
  # testing
  test = (str) ->
    try
      console.log('\n\ntesting: ' + str + '\n')
      toks = tokenize str
      console.log(toks.toString() + '\n')
      expr = parse str
      console.log(expr.toString() + '\n')
      console.log expr.pretty()
    catch error
      console.log error
  
  test '  A'
  test '3.3445 '
  test ' mean(A)'
  test 'log(mean(sum(A_0), 10), 2.718, CCC)  '
  test 'this(should, break'
  test 'so should this'
  console.log '\n\n'
  
  
  extract = extractOps
  r1 = extract(parse 'sum(c)')
  r2 = extract(parse 'bin(lag(a, 1), 10)')
  console.log mergeObjLists([r1, r2])
  
  exampleLS = {
    #data: DATA_SET,
    type: "point",
    y: {var: "b", sort: "a", guide: "y2"},
    x: {var: "a"},
    color: {const: "blue"},
    opacity: {var: "sum(c)"},
    filter: {a: {gt: 0, lt: 100}},
  }
  
  exampleLS2 = {
    #data: DATA_SET,
    type: "point",
    y: {var: "b", sort: "a", guide: "y2"},
    x: {var: "lag(a, 1)"},
    color: {const: "blue"},
    opacity: {var: "sum(c)"},
    filter: {a: {gt: 0, lt: 100}},
  }
  
  exampleLS3 =
    type: "point"
    y: {var: "lag(c , -0xaF1) "}
    x: {var: "bin(a, 0.10)"}
    color: {var: "mean(lag(c,0))"}
    opacity: {var: "bin(a, 10)"}
  
  exampleLS4 =
    type: "point"
    y: {var: "lag(',f+/\\\'c' , -1) "}
    x: {var: "bin(汉字漢字, 10.4e20)"}
    color: {var: "mean(lag(c, -1))"}
    opacity: {var: "bin(\"a-+->\\\"b\", '漢\\\'字')"}
  
  l2d = layerToDataSpec(poly.const)
  testl2d = (ex) ->
    ds = l2d(ex)
    console.log '\n\n'
    console.log ds
    console.log ''
    console.log ds.stats
  
  testl2d exampleLS
  testl2d exampleLS2
  testl2d exampleLS3
  testl2d exampleLS4
  */

}).call(this);
(function() {
  var Cartesian, Coordinate, Polar, poly,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  poly = this.poly || {};

  Coordinate = (function() {

    function Coordinate(params) {
      var _ref, _ref2;
      if (params == null) params = {};
      this.flip = (_ref = params.flip) != null ? _ref : false;
      _ref2 = this.flip ? ['y', 'x'] : ['x', 'y'], this.x = _ref2[0], this.y = _ref2[1];
    }

    Coordinate.prototype.make = function(dims) {
      return this.dims = dims;
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

    Cartesian.prototype.getXY = function(mayflip, scales, mark) {
      var point, scalex, scaley;
      if (mayflip) {
        point = {
          x: _.isArray(mark.x) ? _.map(mark.x, scales.x) : scales.x(mark.x),
          y: _.isArray(mark.y) ? _.map(mark.y, scales.y) : scales.y(mark.y)
        };
        return {
          x: point[this.x],
          y: point[this.y]
        };
      } else {
        scalex = scales[this.x];
        scaley = scales[this.y];
        return {
          x: _.isArray(mark.x) ? _.map(mark.x, scalex) : scalex(mark.x),
          y: _.isArray(mark.y) ? _.map(mark.y, scaley) : scaley(mark.y)
        };
      }
    };

    return Cartesian;

  })(Coordinate);

  Polar = (function(_super) {

    __extends(Polar, _super);

    function Polar() {
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

    Polar.prototype.getXY = function(mayflip, scales, mark) {
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
            radius = scales[r](radius);
            theta = scales[t](mark[t][i]);
            points.x.push(_getx(radius, theta));
            points.y.push(_gety(radius, theta));
            points.r.push(radius);
            points.t.push(theta);
          }
          return points;
        }
        radius = scales[r](mark[r]);
        theta = scales[t](mark[t]);
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
            y: _gety(scales[r](y), 0)
          };
        } else if (identx && identy) {
          return {
            x: x.v,
            y: y.v
          };
        } else if (!identx && identy) {
          return {
            y: y.v,
            x: _gety(scales[t](x), 0)
          };
        } else {
          radius = scales[r](y);
          theta = scales[t](x);
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
  var CategoricalDomain, DateDomain, NumericDomain, aesthetics, domainMerge, flattenGeoms, makeDomain, makeDomainSet, mergeDomainSets, mergeDomains, poly, typeOf;

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
    var domainSets;
    domainSets = [];
    _.each(layers, function(layerObj) {
      return domainSets.push(makeDomainSet(layerObj, guideSpec, strictmode));
    });
    return mergeDomainSets(domainSets);
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
    var domain;
    domain = {};
    _.each(_.keys(layerObj.mapping), function(aes) {
      var fromspec, values, _ref, _ref2, _ref3;
      if (strictmode) {
        return domain[aes] = makeDomain(guideSpec[aes]);
      } else {
        values = flattenGeoms(layerObj.geoms, aes);
        fromspec = function(item) {
          if (guideSpec[aes] != null) {
            return guideSpec[aes][item];
          } else {
            return null;
          }
        };
        if (typeOf(values) === 'num') {
          return domain[aes] = makeDomain({
            type: 'num',
            min: (_ref = fromspec('min')) != null ? _ref : _.min(values),
            max: (_ref2 = fromspec('max')) != null ? _ref2 : _.max(values),
            bw: fromspec('bw')
          });
        } else {
          return domain[aes] = makeDomain({
            type: 'cat',
            levels: (_ref3 = fromspec('levels')) != null ? _ref3 : _.uniq(values),
            sorted: fromspec('levels') != null
          });
        }
      }
    });
    return domain;
  };

  /*
  VERY preliminary flatten function. Need to optimize
  */

  flattenGeoms = function(geoms, aes) {
    var values;
    values = [];
    _.each(geoms, function(geom) {
      return _.each(geom.marks, function(mark) {
        return values = values.concat(poly.flatten(mark[aes]));
      });
    });
    return values;
  };

  /*
  VERY preliminary TYPEOF function. We need some serious optimization here
  */

  typeOf = function(values) {
    if (_.all(values, _.isNumber)) return 'num';
    return 'cat';
  };

  /*
  Merge an array of domain sets: i.e. merge all the domains that shares the
  same aesthetics.
  */

  mergeDomainSets = function(domainSets) {
    var merged;
    merged = {};
    _.each(aesthetics, function(aes) {
      var domains;
      domains = _.without(_.pluck(domainSets, aes), void 0);
      if (domains.length > 0) return merged[aes] = mergeDomains(domains);
    });
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
      bw = _.uniq(_.map(domains, function(d) {
        return d.bw;
      }));
      if (bw.length > 1) {
        throw new poly.LengthError("All binwidths are not of the same length");
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
        throw new poly.UnknownError();
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
      throw new poly.TypeError("Not all domains are of the same type");
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
    var formatter, numticks, tickfn, tickobjs, ticks, _ref;
    if (guideSpec.ticks != null) {
      ticks = guideSpec.ticks;
    } else {
      numticks = (_ref = guideSpec.numticks) != null ? _ref : 5;
      ticks = tickValues[type](domain, numticks);
    }
    formatter = function(x) {
      return x;
    };
    if (guideSpec.labels) {
      formatter = function(x) {
        var _ref2;
        return (_ref2 = guideSpec.labels[x]) != null ? _ref2 : x;
      };
    } else if (guideSpec.formatter) {
      formatter = guideSpec.formatter;
    }
    tickobjs = {};
    tickfn = tickFactory(formatter);
    _.each(ticks, function(t) {
      return tickobjs[t] = tickfn(t);
    });
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
      return domain.levels;
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
      return ticks;
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
      return ticks;
    },
    'date': function(domain, numticks) {
      return 2;
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
      throw new poly.NotImplemented();
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
      if (this.line == null) this.line = this._renderline(renderer, axisDim);
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
      obj = [];
      obj.tick = renderer.animate(pt.tick, this._makeTick(axisDim, tick));
      obj.text = renderer.animate(pt.text, this._makeLabel(axisDim, tick));
      return obj;
    };

    Axis.prototype._renderline = function() {
      throw new poly.NotImplemented();
    };

    Axis.prototype._makeTitle = function() {
      throw new poly.NotImplemented();
    };

    Axis.prototype._makeTick = function() {
      throw new poly.NotImplemented();
    };

    Axis.prototype._makeLabel = function() {
      throw new poly.NotImplemented();
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
        type: 'line',
        y: [y, y],
        x: [x1, x2]
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
        type: 'line',
        x: [tick.location, tick.location],
        y: [sf.identity(axisDim.bottom), sf.identity(axisDim.bottom + 5)]
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
        type: 'line',
        x: [x, x],
        y: [y1, y2]
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
        type: 'line',
        x: [sf.identity(axisDim.left), sf.identity(axisDim.left - 5)],
        y: [tick.location, tick.location]
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
        type: 'line',
        x: [x, x],
        y: [y1, y2]
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
        type: 'line',
        x: [sf.identity(axisDim.left), sf.identity(axisDim.left - 5)],
        y: [tick.location, tick.location]
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
        type: 'line',
        x: [tick.location, tick.location],
        y: [sf.max(0), sf.max(3)]
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
  var Area, Brewer, Color, Gradient, Gradient2, Identity, Linear, Log, PositionScale, Scale, ScaleSet, Shape, aesthetics, poly,
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

  poly.scale = {};

  poly.scale.make = function(guideSpec, domains, ranges) {
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
      this.factory = this._makeFactory(guideSpec, domains, this.ranges);
      return this.scales = this.getScaleFns();
    };

    ScaleSet.prototype.setRanges = function(ranges) {
      this.ranges = ranges;
      return this.scales = this.getScaleFns();
    };

    ScaleSet.prototype.setXDomain = function(d) {
      this.domainx = d;
      return this.scales.x = this._makeXScale();
    };

    ScaleSet.prototype.setYDomain = function(d) {
      this.domainy = d;
      return this.scales.y = this._makeYScale();
    };

    ScaleSet.prototype.resetDomains = function() {
      this.domainx = this.domains.x;
      this.domainy = this.domains.y;
      this.scales.x = this._makeXScale();
      return this.scales.y = this._makeYScale();
    };

    ScaleSet.prototype.getScaleFns = function() {
      var scales,
        _this = this;
      scales = {};
      if (this.domainx) scales.x = this._makeXScale();
      if (this.domainy) scales.y = this._makeYScale();
      _.each(['color', 'size'], function(aes) {
        if (_this.domains[aes]) return scales[aes] = _this._makeScale(aes);
      });
      return scales;
    };

    ScaleSet.prototype._makeXScale = function() {
      return this.factory.x.construct(this.domainx, this.ranges.x);
    };

    ScaleSet.prototype._makeYScale = function() {
      return this.factory.y.construct(this.domainy, this.ranges.y);
    };

    ScaleSet.prototype._makeScale = function(aes) {
      return this.factory[aes].construct(this.domains[aes]);
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
        type: this.factory.x.tickType(this.domainx),
        guideSpec: this.getSpec('x'),
        titletext: poly.getLabel(this.layers, 'x')
      });
      this.axes.y.make({
        domain: this.domainy,
        type: this.factory.y.tickType(this.domainy),
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
        if (aes === 'x' || aes === 'y') continue;
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
        if (aes === 'x' || aes === 'y' || aes === 'id') continue;
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
      var aes, aesGroups, i, idx, layerMapping, legend, legenddeleted, _i, _j, _len, _len2, _ref;
      layerMapping = this._mapLayers(this.layers);
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
          type: this.factory[aes].tickType(this.domains[aes]),
          mapping: layerMapping,
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

    ScaleSet.prototype._makeFactory = function(guideSpec, domains, ranges) {
      var factory, specScale, _ref, _ref2, _ref3, _ref4;
      specScale = function(a) {
        if (guideSpec && (guideSpec[a] != null) && (guideSpec[a].scale != null)) {
          return guideSpec.x.scale;
        }
        return null;
      };
      factory = {
        x: (_ref = specScale('x')) != null ? _ref : poly.scale.linear(),
        y: (_ref2 = specScale('y')) != null ? _ref2 : poly.scale.linear()
      };
      if (domains.color != null) {
        if (domains.color.type === 'cat') {
          factory.color = (_ref3 = specScale('color')) != null ? _ref3 : poly.scale.color();
        } else {
          factory.color = (_ref4 = specScale('color')) != null ? _ref4 : poly.scale.gradient({
            upper: 'steelblue',
            lower: 'red'
          });
        }
      }
      if (domains.size != null) {
        factory.size = specScale('size') || poly.scale.area();
      }
      return factory;
    };

    return ScaleSet;

  })();

  /*
  # CLASSES
  */

  /*
  Scales here are objects that can construct functions that takes a value from
  the data, and returns another value that is suitable for rendering an
  attribute of that value.
  */

  Scale = (function() {

    function Scale(params) {}

    Scale.prototype.guide = function() {};

    Scale.prototype.construct = function(domain) {
      switch (domain.type) {
        case 'num':
          return this._constructNum(domain);
        case 'date':
          return this._constructDate(domain);
        case 'cat':
          return this._constructCat(domain);
      }
    };

    Scale.prototype._constructNum = function(domain) {
      throw new poly.NotImplemented("_constructNum is not implemented");
    };

    Scale.prototype._constructDate = function(domain) {
      throw new poly.NotImplemented("_constructDate is not implemented");
    };

    Scale.prototype._constructCat = function(domain) {
      throw new poly.NotImplemented("_constructCat is not implemented");
    };

    Scale.prototype.tickType = function(domain) {
      switch (domain.type) {
        case 'num':
          return this._tickNum(domain);
        case 'date':
          return this._tickDate(domain);
        case 'cat':
          return this._tickCat(domain);
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

    function PositionScale() {
      this._wrapper = __bind(this._wrapper, this);
      PositionScale.__super__.constructor.apply(this, arguments);
    }

    PositionScale.prototype.construct = function(domain, range) {
      this.range = range;
      return PositionScale.__super__.construct.call(this, domain);
    };

    PositionScale.prototype._wrapper = function(domain, y) {
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
          throw new poly.UnexpectedObject("Expected a value instead of an object");
        }
        return y(value);
      };
    };

    return PositionScale;

  })(Scale);

  Linear = (function(_super) {

    __extends(Linear, _super);

    function Linear() {
      this._wrapper2 = __bind(this._wrapper2, this);
      Linear.__super__.constructor.apply(this, arguments);
    }

    Linear.prototype._constructNum = function(domain) {
      var max, _ref;
      max = domain.max + ((_ref = domain.bw) != null ? _ref : 0);
      return this._wrapper(domain, poly.linear(domain.min, this.range.min, max, this.range.max));
    };

    Linear.prototype._wrapper2 = function(step, y) {
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
          throw new poly.UnexpectedObject("wtf is this object?");
        }
        return y(value) + step / 2;
      };
    };

    Linear.prototype._constructCat = function(domain) {
      var step, y,
        _this = this;
      step = (this.range.max - this.range.min) / domain.levels.length;
      y = function(x) {
        var i;
        i = _.indexOf(domain.levels, x);
        if (i === -1) {
          return null;
        } else {
          return _this.range.min + i * step;
        }
      };
      return this._wrapper2(step, y);
    };

    return Linear;

  })(PositionScale);

  Log = (function(_super) {

    __extends(Log, _super);

    function Log() {
      Log.__super__.constructor.apply(this, arguments);
    }

    Log.prototype._constructNum = function(domain) {
      var lg, ylin;
      lg = Math.log;
      ylin = poly.linear(lg(domain.min), this.range.min, lg(domain.max), this.range.max);
      return this._wrapper(function(x) {
        return ylin(lg(x));
      });
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
      Area.__super__.constructor.apply(this, arguments);
    }

    Area.prototype._constructNum = function(domain) {
      var min, sq, ylin;
      min = domain.min === 0 ? 0 : 1;
      sq = Math.sqrt;
      ylin = poly.linear(sq(domain.min), min, sq(domain.max), 10);
      return this._identityWrapper(function(x) {
        return ylin(sq(x));
      });
    };

    return Area;

  })(Scale);

  Color = (function(_super) {

    __extends(Color, _super);

    function Color() {
      Color.__super__.constructor.apply(this, arguments);
    }

    Color.prototype._constructCat = function(domain) {
      var h, n;
      n = domain.levels.length;
      h = function(v) {
        return _.indexOf(domain.levels, v) / n + 1 / (2 * n);
      };
      return function(value) {
        return Raphael.hsl(h(value), 0.5, 0.5);
      };
    };

    Color.prototype._constructNum = function(domain) {
      var h;
      h = poly.linear(domain.min, 0, domain.max, 1);
      return function(value) {
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

    Brewer.prototype._constructCat = function(domain) {};

    return Brewer;

  })(Scale);

  Gradient = (function(_super) {

    __extends(Gradient, _super);

    function Gradient(params) {
      this._constructNum = __bind(this._constructNum, this);      this.lower = params.lower, this.upper = params.upper;
    }

    Gradient.prototype._constructNum = function(domain) {
      var b, g, lower, r, upper,
        _this = this;
      lower = Raphael.color(this.lower);
      upper = Raphael.color(this.upper);
      r = poly.linear(domain.min, lower.r, domain.max, upper.r);
      g = poly.linear(domain.min, lower.g, domain.max, upper.g);
      b = poly.linear(domain.min, lower.b, domain.max, upper.b);
      return this._identityWrapper(function(value) {
        return Raphael.rgb(r(value), g(value), b(value));
      });
    };

    return Gradient;

  })(Scale);

  Gradient2 = (function(_super) {

    __extends(Gradient2, _super);

    function Gradient2(params) {
      var lower, upper, zero;
      lower = params.lower, zero = params.zero, upper = params.upper;
    }

    Gradient2.prototype._constructCat = function(domain) {};

    return Gradient2;

  })(Scale);

  Shape = (function(_super) {

    __extends(Shape, _super);

    function Shape() {
      Shape.__super__.constructor.apply(this, arguments);
    }

    Shape.prototype._constructCat = function(domain) {};

    return Shape;

  })(Scale);

  Identity = (function(_super) {

    __extends(Identity, _super);

    function Identity() {
      Identity.__super__.constructor.apply(this, arguments);
    }

    Identity.prototype.construct = function(domain) {
      return function(x) {
        return x;
      };
    };

    return Identity;

  })(Scale);

  poly.scale = _.extend(poly.scale, {
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
    }
  });

  /*
  # EXPORT
  */

  this.poly = poly;

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
      this.url = params.url, this.json = params.json;
      this.frontEnd = !this.url;
    }

    Data.prototype.update = function(json) {
      return this.json = json;
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
      this.initialSpec = poly.spec.layerToData(layerSpec);
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
      dataSpec = poly.spec.layerToData(spec);
      wrappedCallback = this._wrap(callback);
      if (this.dataObj.frontEnd) {
        if (this.strictmode) {
          return wrappedCallback(this.dataObj.json, {});
        } else {
          return frontendProcess(dataSpec, this.dataObj.json, wrappedCallback);
        }
      } else {
        if (this.strictmode) {
          throw new poly.StrictModeError();
        } else {
          return backendProcess(dataSpec, this.dataObj, wrappedCallback);
        }
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
    'bin': function(key, transSpec) {
      var binFn, binwidth, name;
      name = transSpec.name, binwidth = transSpec.binwidth;
      if (_.isNumber(binwidth)) {
        binFn = function(item) {
          return item[name] = binwidth * Math.floor(item[key] / binwidth);
        };
        return {
          trans: binFn,
          meta: {
            bw: binwidth,
            binned: true
          }
        };
      }
    },
    'lag': function(key, transSpec) {
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
        meta: void 0
      };
    }
  };

  /*
  Helper function to figures out which transformation to create, then creates it
  */

  transformFactory = function(key, transSpec) {
    return transforms[transSpec.trans](key, transSpec);
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
        var iqr, len, lowerBound, mid, q2, q4, quarter, sortedValues, splitValues, upperBound;
        len = values.length;
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
          outliers: splitValues["false"]
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
        group: [key]
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

  frontendProcess = function(dataSpec, rawData, callback) {
    var addMeta, additionalFilter, data, metaData;
    data = _.clone(rawData);
    metaData = {};
    addMeta = function(key, meta) {
      var _ref;
      return _.extend((_ref = metaData[key]) != null ? _ref : {}, meta);
    };
    if (dataSpec.trans) {
      _.each(dataSpec.trans, function(transSpec, key) {
        var meta, trans, _ref;
        _ref = transformFactory(key, transSpec), trans = _ref.trans, meta = _ref.meta;
        _.each(data, function(d) {
          return trans(d);
        });
        return addMeta(transSpec.name, meta);
      });
    }
    if (dataSpec.filter) data = _.filter(data, filterFactory(dataSpec.filter));
    if (dataSpec.meta) {
      additionalFilter = {};
      _.each(dataSpec.meta, function(metaSpec, key) {
        var filter, meta, _ref;
        _ref = calculateMeta(key, metaSpec, data), meta = _ref.meta, filter = _ref.filter;
        additionalFilter[key] = filter;
        return addMeta(key, meta);
      });
      data = _.filter(data, filterFactory(additionalFilter));
    }
    if (dataSpec.stats && dataSpec.stats.stats && dataSpec.stats.stats.length > 0) {
      data = calculateStats(data, dataSpec.stats);
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
  var Bar, Layer, Line, Point, aesthetics, defaults, poly, sf,
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
    'opacity': 0.7,
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
    _.each(aesthetics, function(aes) {
      if (spec[aes] && _.isString(spec[aes])) {
        return spec[aes] = {
          "var": spec[aes]
        };
      }
    });
    return spec;
  };

  /*
  Public interface to making different layer types.
  */

  poly.layer.make = function(layerSpec, strictmode) {
    switch (layerSpec.type) {
      case 'point':
        return new Point(layerSpec, strictmode);
      case 'line':
        return new Line(layerSpec, strictmode);
      case 'bar':
        return new Bar(layerSpec, strictmode);
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
        _this._calcGeoms();
        return callback();
      });
      return this.prevSpec = spec;
    };

    Layer.prototype._calcGeoms = function() {
      return this.geoms = {};
    };

    Layer.prototype.render = function(render) {
      var added, deleted, kept, newpts, _ref,
        _this = this;
      newpts = {};
      _ref = poly.compare(_.keys(this.pts), _.keys(this.geoms)), deleted = _ref.deleted, kept = _ref.kept, added = _ref.added;
      _.each(deleted, function(id) {
        return _this._delete(render, _this.pts[id]);
      });
      _.each(added, function(id) {
        return newpts[id] = _this._add(render, _this.geoms[id]);
      });
      _.each(kept, function(id) {
        return newpts[id] = _this._modify(render, _this.pts[id], _this.geoms[id]);
      });
      return this.pts = newpts;
    };

    Layer.prototype._delete = function(render, points) {
      return _.each(points, function(pt, id2) {
        return render.remove(pt);
      });
    };

    Layer.prototype._modify = function(render, points, geom) {
      var objs;
      objs = {};
      _.each(geom.marks, function(mark, id2) {
        return objs[id2] = render.animate(points[id2], mark, geom.evtData);
      });
      return objs;
    };

    Layer.prototype._add = function(render, geom) {
      var objs;
      objs = {};
      _.each(geom.marks, function(mark, id2) {
        return objs[id2] = render.add(mark, geom.evtData);
      });
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

    return Layer;

  })();

  Point = (function(_super) {

    __extends(Point, _super);

    function Point() {
      Point.__super__.constructor.apply(this, arguments);
    }

    Point.prototype._calcGeoms = function() {
      var idfn,
        _this = this;
      idfn = this._getIdFunc();
      this.geoms = {};
      return _.each(this.statData, function(item) {
        var evtData;
        evtData = {};
        _.each(item, function(v, k) {
          return evtData[k] = {
            "in": [v]
          };
        });
        return _this.geoms[idfn(item)] = {
          marks: {
            0: {
              type: 'circle',
              x: _this._getValue(item, 'x'),
              y: _this._getValue(item, 'y'),
              color: _this._getValue(item, 'color'),
              size: _this._getValue(item, 'size')
            }
          },
          evtData: evtData
        };
      });
    };

    return Point;

  })(Layer);

  Line = (function(_super) {

    __extends(Line, _super);

    function Line() {
      Line.__super__.constructor.apply(this, arguments);
    }

    Line.prototype._calcGeoms = function() {
      var datas, group, idfn, k,
        _this = this;
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
      return _.each(datas, function(data) {
        var evtData, item, sample;
        sample = data[0];
        evtData = {};
        _.each(group, function(key) {
          return evtData[key] = {
            "in": [sample[key]]
          };
        });
        return _this.geoms[idfn(sample)] = {
          marks: {
            0: {
              type: 'line',
              x: (function() {
                var _i, _len, _results;
                _results = [];
                for (_i = 0, _len = data.length; _i < _len; _i++) {
                  item = data[_i];
                  _results.push(this._getValue(item, 'x'));
                }
                return _results;
              }).call(_this),
              y: (function() {
                var _i, _len, _results;
                _results = [];
                for (_i = 0, _len = data.length; _i < _len; _i++) {
                  item = data[_i];
                  _results.push(this._getValue(item, 'y'));
                }
                return _results;
              }).call(_this),
              color: _this._getValue(sample, 'color')
            }
          },
          evtData: evtData
        };
      });
    };

    return Line;

  })(Layer);

  Bar = (function(_super) {

    __extends(Bar, _super);

    function Bar() {
      Bar.__super__.constructor.apply(this, arguments);
    }

    Bar.prototype._calcGeoms = function() {
      var datas, group, idfn,
        _this = this;
      group = this.mapping.x != null ? [this.mapping.x] : [];
      datas = poly.groupBy(this.statData, group);
      _.each(datas, function(data) {
        var tmp, yval;
        tmp = 0;
        yval = _this.mapping.y != null ? (function(item) {
          return item[_this.mapping.y];
        }) : function(item) {
          return 0;
        };
        return _.each(data, function(item) {
          item.$lower = tmp;
          tmp += yval(item);
          return item.$upper = tmp;
        });
      });
      idfn = this._getIdFunc();
      this.geoms = {};
      return _.each(this.statData, function(item) {
        var evtData;
        evtData = {};
        _.each(item, function(v, k) {
          if (k !== 'y') {
            return evtData[k] = {
              "in": [v]
            };
          }
        });
        return _this.geoms[idfn(item)] = {
          marks: {
            0: {
              type: 'rect',
              x: [sf.lower(_this._getValue(item, 'x')), sf.upper(_this._getValue(item, 'x'))],
              y: [item.$lower, item.$upper],
              color: _this._getValue(item, 'color')
            }
          }
        };
      });
    };

    return Bar;

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
  var Circle, CircleRect, Line, Rect, Renderer, Text, poly, renderer,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  poly = this.poly || {};

  /*
  # GLOBALS
  */

  poly.paper = function(dom, w, h) {
    return Raphael(dom, w, h);
  };

  /*
  Helper function for rendering all the geoms of an object
  
  TODO: 
  - make add & remove animations
  - make everything animateWith some standard object
  */

  poly.render = function(id, paper, scales, coord, mayflip, clipping) {
    return {
      add: function(mark, evtData) {
        var pt;
        pt = renderer[coord.type][mark.type].render(paper, scales, coord, mark, mayflip);
        if (clipping != null) pt.attr('clip-rect', clipping);
        pt.click(function() {
          return eve(id + ".click", this, evtData);
        });
        pt.hover(function() {
          return eve(id + ".hover", this, evtData);
        });
        return pt;
      },
      remove: function(pt) {
        return pt.remove();
      },
      animate: function(pt, mark, evtData) {
        renderer[coord.type][mark.type].animate(pt, scales, coord, mark, mayflip);
        pt.unclick();
        pt.click(function() {
          return eve(id + ".click", this, evtData);
        });
        pt.unhover();
        pt.hover(function() {
          return eve(id + ".hover", this, evtData);
        });
        return pt;
      }
    };
  };

  Renderer = (function() {

    function Renderer() {}

    Renderer.prototype.render = function(paper, scales, coord, mark, mayflip) {
      var pt;
      pt = this._make(paper);
      _.each(this.attr(scales, coord, mark, mayflip), function(v, k) {
        return pt.attr(k, v);
      });
      return pt;
    };

    Renderer.prototype._make = function() {
      throw new poly.NotImplemented();
    };

    Renderer.prototype.animate = function(pt, scales, coord, mark, mayflip) {
      return pt.animate(this.attr(scales, coord, mark, mayflip), 300);
    };

    Renderer.prototype.attr = function(scales, coord, mark, mayflip) {
      throw new poly.NotImplemented();
    };

    Renderer.prototype._makePath = function(xs, ys, type) {
      var path;
      if (type == null) type = 'L';
      path = _.map(xs, function(x, i) {
        return (i === 0 ? 'M' : type) + x + ' ' + ys[i];
      });
      return path.join(' ');
    };

    Renderer.prototype._maybeApply = function(scale, val) {
      if (scale != null) {
        return scale(val);
      } else if (_.isObject(val)) {
        return val.v;
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
      _ref = coord.getXY(mayflip, scales, mark), x = _ref.x, y = _ref.y;
      stroke = mark.stroke ? this._maybeApply(scales.stroke, mark.stroke) : this._maybeApply(scales.color, mark.color);
      return {
        cx: x,
        cy: y,
        r: this._maybeApply(scales.size, mark.size),
        fill: this._maybeApply(scales.color, mark.color),
        stroke: stroke,
        title: 'omgthisiscool!',
        'stroke-width': (_ref2 = mark['stroke-width']) != null ? _ref2 : '0px'
      };
    };

    return Circle;

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
      var x, y, _ref;
      _ref = coord.getXY(mayflip, scales, mark), x = _ref.x, y = _ref.y;
      return {
        path: this._makePath(x, y),
        stroke: 'black'
      };
    };

    return Line;

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
      _ref = coord.getXY(mayflip, scales, mark), x = _ref.x, y = _ref.y;
      return {
        x: _.min(x),
        y: _.min(y),
        width: Math.abs(x[1] - x[0]),
        height: Math.abs(y[1] - y[0]),
        fill: this._maybeApply(scales.color, mark.color),
        stroke: this._maybeApply(scales.color, mark.color),
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
      _ref3 = coord.getXY(mayflip, scales, mark), x = _ref3.x, y = _ref3.y, r = _ref3.r, t = _ref3.t;
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
        fill: this._maybeApply(scales.color, mark.color),
        stroke: this._maybeApply(scales.color, mark.color),
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
      _ref = coord.getXY(mayflip, scales, mark), x = _ref.x, y = _ref.y;
      m = {
        x: x,
        y: y,
        text: this._maybeApply(scales.text, mark.text),
        'text-anchor': (_ref2 = mark['text-anchor']) != null ? _ref2 : 'left',
        r: 10,
        fill: 'black'
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
      text: new Text(),
      rect: new Rect()
    },
    polar: {
      circle: new Circle(),
      line: new Line(),
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
      this.render = __bind(this.render, this);
      this.merge = __bind(this.merge, this);
      this.reset = __bind(this.reset, this);
      var _ref;
      this.graphId = _.uniqueId('graph_');
      this.layers = null;
      this.scaleSet = null;
      this.axes = null;
      this.legends = null;
      this.dims = null;
      this.paper = null;
      this.coord = (_ref = spec.coord) != null ? _ref : poly.coord.cartesian();
      this.initial_spec = spec;
      this.make(spec);
    }

    Graph.prototype.reset = function() {
      return this.make(this.initial_spec);
    };

    Graph.prototype.make = function(spec) {
      var merge;
      this.spec = spec;
      if (spec.layers == null) spec.layers = [];
      if (this.layers == null) this.layers = this._makeLayers(this.spec);
      merge = _.after(this.layers.length, this.merge);
      return _.each(this.layers, function(layerObj, id) {
        return layerObj.make(spec.layers[id], merge);
      });
    };

    Graph.prototype.merge = function() {
      var domains;
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
      return this._legacy(domains);
    };

    Graph.prototype.render = function(dom) {
      var clipping, renderer, scales,
        _this = this;
      if (this.paper == null) {
        this.paper = this._makePaper(dom, this.dims.width, this.dims.height);
      }
      scales = this.scaleSet.getScaleFns();
      clipping = this.coord.clipping(this.dims);
      renderer = poly.render(this.graphId, this.paper, scales, this.coord, true, clipping);
      _.each(this.layers, function(layer) {
        return layer.render(renderer);
      });
      renderer = poly.render(this.graphId, this.paper, scales, this.coord, false);
      this.scaleSet.makeAxes();
      this.scaleSet.renderAxes(this.dims, renderer);
      this.scaleSet.makeLegends();
      return this.scaleSet.renderLegends(this.dims, renderer);
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
      return poly.scale.make(tmpRanges, this.coord);
    };

    Graph.prototype._makeDimensions = function(spec, scaleSet) {
      return poly.dim.make(spec, scaleSet.makeAxes(), scaleSet.makeLegends());
    };

    Graph.prototype._makePaper = function(dom, width, height) {
      return poly.paper(document.getElementById(dom), width, height);
    };

    Graph.prototype._legacy = function(domains) {
      var axes,
        _this = this;
      this.domains = domains;
      this.scales = this.scaleSet.getScaleFns();
      axes = this.scaleSet.makeAxes();
      this.ticks = {};
      return _.each(axes, function(v, k) {
        return _this.ticks[k] = v.ticks;
      });
    };

    return Graph;

  })();

  poly.chart = function(spec) {
    return new Graph(spec);
  };

  this.poly = poly;

}).call(this);
