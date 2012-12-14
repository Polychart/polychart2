(function() {

  module("parsers");

  test("expressions", function() {
    equal(poly.parser.tokenize('A').toString(), '<symbol,A>');
    equal(poly.parser.parse('A').toString(), 'Ident(A)');
    equal(poly.parser.tokenize('  A').toString(), '<symbol,A>');
    equal(poly.parser.parse('  A').toString(), 'Ident(A)');
    equal(poly.parser.tokenize('3.3445').toString(), '<literal,3.3445>');
    equal(poly.parser.parse('3.3445').toString(), 'Const(3.3445)');
    equal(poly.parser.tokenize('mean(A )').toString(), '<symbol,mean>,<(>,<symbol,A>,<)>');
    equal(poly.parser.parse('mean(A )').toString(), 'Call(mean,[Ident(A)])');
    equal(poly.parser.tokenize(' mean(A )').toString(), '<symbol,mean>,<(>,<symbol,A>,<)>');
    equal(poly.parser.parse('mean(A )').toString(), 'Call(mean,[Ident(A)])');
    equal(poly.parser.tokenize('mean( A )  ').toString(), '<symbol,mean>,<(>,<symbol,A>,<)>');
    equal(poly.parser.parse('mean( A )  ').toString(), 'Call(mean,[Ident(A)])');
    equal(poly.parser.tokenize('log(mean(sum(A_0), 10), 2.7188, CCC)').toString(), '<symbol,log>,<(>,<symbol,mean>,<(>,<symbol,sum>,<(>,<symbol,A_0>,<)>,<,>,<literal,10>,<)>,<,>,<literal,2.7188>,<,>,<symbol,CCC>,<)>');
    equal(poly.parser.parse('log(mean(sum(A_0), 10), 2.7188, CCC)').toString(), 'Call(log,[Call(mean,[Call(sum,[Ident(A_0)]),Const(10)]),Const(2.7188),Ident(CCC)])');
    equal(poly.parser.tokenize('this(should, break').toString(), '<symbol,this>,<(>,<symbol,should>,<,>,<symbol,break>');
    try {
      poly.parser.parse('this(should, break').toString();
      ok(false, 'this(should, break');
    } catch (e) {
      equal(e.message, 'unable to parse: Stream([])');
    }
    try {
      poly.parser.parse(')this(should, break').toString();
      ok(false, ')this(should, break');
    } catch (e) {
      equal(e.message, 'unable to parse: Stream([<)>,<symbol,this>,<(>,<symbol,should>,<,>,<symbol,break>])');
    }
    try {
      poly.parser.parse('this should break').toString();
      return ok(false, 'this should break');
    } catch (e) {
      return equal(e.message, "expected end of stream, but found: Stream([<symbol,should>,<symbol,break>])");
    }
  });

  test("extraction: nothing (smoke test)", function() {
    var layerparser, parser;
    layerparser = {
      type: "point",
      y: {
        "var": "b"
      },
      x: {
        "var": "a"
      },
      color: {
        "const": "blue"
      },
      opacity: {
        "var": "c"
      }
    };
    parser = poly.parser.layerToData(layerparser);
    deepEqual(parser.filter, {});
    deepEqual(parser.meta, {});
    deepEqual(parser.select, ['a', 'b', 'c']);
    deepEqual(parser.stats.stats, []);
    return deepEqual(parser.trans, []);
  });

  test("extraction: simple, one stat (smoke test)", function() {
    var layerparser, parser;
    layerparser = {
      type: "point",
      x: {
        "var": "a"
      },
      y: {
        "var": "sum(b)"
      }
    };
    parser = poly.parser.layerToData(layerparser);
    deepEqual(parser.filter, {});
    deepEqual(parser.meta, {});
    deepEqual(parser.select, ['a', 'sum(b)']);
    deepEqual(parser.stats.stats, [
      {
        key: 'b',
        stat: 'sum',
        name: 'sum(b)'
      }
    ]);
    deepEqual(parser.stats.groups, ['a']);
    return deepEqual(parser.trans, []);
  });

  test("extraction: stats", function() {
    var layerparser, parser;
    layerparser = {
      type: "point",
      y: {
        "var": "b",
        sort: "a",
        guide: "y2"
      },
      x: {
        "var": "a"
      },
      color: {
        "const": "blue"
      },
      opacity: {
        "var": "sum(c)"
      },
      filter: {
        a: {
          gt: 0,
          lt: 100
        }
      }
    };
    parser = poly.parser.layerToData(layerparser);
    deepEqual(parser.filter, layerparser.filter);
    deepEqual(parser.meta, {
      b: {
        sort: 'a',
        asc: true
      }
    });
    deepEqual(parser.select, ['a', 'b', 'sum(c)']);
    deepEqual(parser.stats.groups, ['a', 'b']);
    deepEqual(parser.stats.stats, [
      {
        key: 'c',
        name: 'sum(c)',
        stat: 'sum'
      }
    ]);
    return deepEqual(parser.trans, []);
  });

  test("extraction: transforms", function() {
    var layerparser, parser;
    layerparser = {
      type: "point",
      y: {
        "var": "b",
        sort: "a",
        guide: "y2"
      },
      x: {
        "var": "lag(a, 1)"
      },
      color: {
        "const": "blue"
      },
      opacity: {
        "var": "sum(c)"
      },
      filter: {
        a: {
          gt: 0,
          lt: 100
        }
      }
    };
    parser = poly.parser.layerToData(layerparser);
    deepEqual(parser.filter, layerparser.filter);
    deepEqual(parser.meta, {
      b: {
        sort: 'a',
        asc: true
      }
    });
    deepEqual(parser.select, ['lag(a,1)', 'b', 'sum(c)']);
    deepEqual(parser.stats.groups, ['lag(a,1)', 'b']);
    deepEqual(parser.stats.stats, [
      {
        key: 'c',
        name: 'sum(c)',
        stat: 'sum'
      }
    ]);
    deepEqual(parser.trans, [
      {
        key: 'a',
        lag: '1',
        name: 'lag(a,1)',
        trans: 'lag'
      }
    ]);
    layerparser = {
      type: "point",
      y: {
        "var": "b",
        sort: "a",
        guide: "y2"
      },
      x: {
        "var": "bin(a, 1)"
      },
      color: {
        "const": "blue"
      },
      opacity: {
        "var": "sum(c)"
      },
      filter: {
        a: {
          gt: 0,
          lt: 100
        }
      }
    };
    parser = poly.parser.layerToData(layerparser);
    deepEqual(parser.filter, layerparser.filter);
    deepEqual(parser.meta, {
      b: {
        sort: 'a',
        asc: true
      }
    });
    deepEqual(parser.select, ['bin(a,1)', 'b', 'sum(c)']);
    deepEqual(parser.stats.groups, ['bin(a,1)', 'b']);
    deepEqual(parser.stats.stats, [
      {
        key: 'c',
        name: 'sum(c)',
        stat: 'sum'
      }
    ]);
    deepEqual(parser.trans, [
      {
        key: 'a',
        binwidth: '1',
        name: 'bin(a,1)',
        trans: 'bin'
      }
    ]);
    layerparser = {
      type: "point",
      y: {
        "var": "lag(c , -0xaF1) "
      },
      x: {
        "var": "bin(a, 0.10)"
      },
      color: {
        "var": "mean(lag(c,0))"
      },
      opacity: {
        "var": "bin(a, 10)"
      }
    };
    parser = poly.parser.layerToData(layerparser);
    deepEqual(parser.select, ["bin(a,0.10)", "lag(c,-0xaF1)", "mean(lag(c,0))", "bin(a,10)"]);
    deepEqual(parser.stats.groups, ["bin(a,0.10)", "lag(c,-0xaF1)", "bin(a,10)"]);
    deepEqual(parser.stats.stats, [
      {
        key: "lag(c,0)",
        name: "mean(lag(c,0))",
        stat: "mean"
      }
    ]);
    return deepEqual(parser.trans, [
      {
        "key": "a",
        "binwidth": "10",
        "name": "bin(a,10)",
        "trans": "bin"
      }, {
        "key": "c",
        "lag": "0",
        "name": "lag(c,0)",
        "trans": "lag"
      }, {
        "key": "c",
        "lag": "-0xaF1",
        "name": "lag(c,-0xaF1)",
        "trans": "lag"
      }, {
        "key": "a",
        "binwidth": "0.10",
        "name": "bin(a,0.10)",
        "trans": "bin"
      }
    ]);
  });

  test("extraction: UTF8", function() {
    var layerparser, parser;
    layerparser = {
      type: "point",
      y: {
        "var": "lag(',f+/\\\'c' , -1) "
      },
      x: {
        "var": "bin(汉字漢字, 10.4e20)"
      },
      color: {
        "var": "mean(lag(c, -1))"
      },
      opacity: {
        "var": "bin(\"a-+->\\\"b\", '漢\\\'字')"
      }
    };
    parser = poly.parser.layerToData(layerparser);
    return deepEqual(parser.select, ["bin(汉字漢字,10.4e20", "lag(',f+/\\\'c',-1", "mean(lag(c,-1))", "bin(\"a-+->\\\"b\", '漢\\\'字')"]);
  });

}).call(this);
