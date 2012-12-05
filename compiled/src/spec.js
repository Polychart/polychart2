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
