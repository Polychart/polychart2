(function() {

  module("Specs");

  test("expressions", function() {
    equal(poly.spec.tokenize('A').toString(), '<symbol,A>');
    equal(poly.spec.parse('A').toString(), 'Ident(A)');
    equal(poly.spec.tokenize('  A').toString(), '<symbol,A>');
    equal(poly.spec.parse('  A').toString(), 'Ident(A)');
    equal(poly.spec.tokenize('3.3445').toString(), '<literal,3.3445>');
    equal(poly.spec.parse('3.3445').toString(), 'Const(3.3445)');
    equal(poly.spec.tokenize('mean(A )').toString(), '<symbol,mean>,<(>,<symbol,A>,<)>');
    equal(poly.spec.parse('mean(A )').toString(), 'Call(mean,[Ident(A)])');
    equal(poly.spec.tokenize(' mean(A )').toString(), '<symbol,mean>,<(>,<symbol,A>,<)>');
    equal(poly.spec.parse('mean(A )').toString(), 'Call(mean,[Ident(A)])');
    equal(poly.spec.tokenize('mean( A )  ').toString(), '<symbol,mean>,<(>,<symbol,A>,<)>');
    equal(poly.spec.parse('mean( A )  ').toString(), 'Call(mean,[Ident(A)])');
    equal(poly.spec.tokenize('log(mean(sum(A_0), 10), 2.7188, CCC)').toString(), '<symbol,log>,<(>,<symbol,mean>,<(>,<symbol,sum>,<(>,<symbol,A_0>,<)>,<,>,<literal,10>,<)>,<,>,<literal,2.7188>,<,>,<symbol,CCC>,<)>');
    equal(poly.spec.parse('log(mean(sum(A_0), 10), 2.7188, CCC)').toString(), 'Call(log,[Call(mean,[Call(sum,[Ident(A_0)]),Const(10)]),Const(2.7188),Ident(CCC)])');
    equal(poly.spec.tokenize('this(should, break').toString(), '<symbol,this>,<(>,<symbol,should>,<,>,<symbol,break>');
    try {
      poly.spec.parse('this(should, break').toString();
      ok(false, 'this(should, break');
    } catch (e) {
      equal(e.message, 'unable to parse: Stream([])');
    }
    try {
      poly.spec.parse(')this(should, break').toString();
      ok(false, ')this(should, break');
    } catch (e) {
      equal(e.message, 'unable to parse: Stream([<)>,<symbol,this>,<(>,<symbol,should>,<,>,<symbol,break>])');
    }
    try {
      poly.spec.parse('this should break').toString();
      return ok(false, 'this should break');
    } catch (e) {
      return equal(e.message, "expected end of stream, but found: Stream([<symbol,should>,<symbol,break>])");
    }
  });

  test("extraction: nothing (smoke test)", function() {
    var layerSpec, spec;
    layerSpec = {
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
    spec = poly.spec.layerToData(layerSpec);
    deepEqual(spec.filter, {});
    deepEqual(spec.meta, {});
    deepEqual(spec.select, ['a', 'b', 'c']);
    deepEqual(spec.stats.stats, []);
    return deepEqual(spec.trans, []);
  });

  test("extraction: stats", function() {
    var layerSpec, spec;
    layerSpec = {
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
    spec = poly.spec.layerToData(layerSpec);
    deepEqual(spec.filter, layerSpec.filter);
    deepEqual(spec.meta, {
      b: {
        sort: 'a',
        asc: true
      }
    });
    deepEqual(spec.select, ['a', 'b', 'sum(c)']);
    deepEqual(spec.stats.groups, ['a', 'b']);
    deepEqual(spec.stats.stats, [
      {
        key: 'c',
        name: 'sum(c)',
        stat: 'sum'
      }
    ]);
    return deepEqual(spec.trans, []);
  });

  test("extraction: transforms", function() {
    var layerSpec, spec;
    layerSpec = {
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
    spec = poly.spec.layerToData(layerSpec);
    deepEqual(spec.filter, layerSpec.filter);
    deepEqual(spec.meta, {
      b: {
        sort: 'a',
        asc: true
      }
    });
    deepEqual(spec.select, ['lag(a,1)', 'b', 'sum(c)']);
    deepEqual(spec.stats.groups, ['lag(a,1)', 'b']);
    deepEqual(spec.stats.stats, [
      {
        key: 'c',
        name: 'sum(c)',
        stat: 'sum'
      }
    ]);
    deepEqual(spec.trans, [
      {
        key: 'a',
        lag: '1',
        name: 'lag(a,1)',
        trans: 'lag'
      }
    ]);
    layerSpec = {
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
    spec = poly.spec.layerToData(layerSpec);
    deepEqual(spec.filter, layerSpec.filter);
    deepEqual(spec.meta, {
      b: {
        sort: 'a',
        asc: true
      }
    });
    deepEqual(spec.select, ['bin(a,1)', 'b', 'sum(c)']);
    deepEqual(spec.stats.groups, ['bin(a,1)', 'b']);
    deepEqual(spec.stats.stats, [
      {
        key: 'c',
        name: 'sum(c)',
        stat: 'sum'
      }
    ]);
    deepEqual(spec.trans, [
      {
        key: 'a',
        binwidth: '1',
        name: 'bin(a,1)',
        trans: 'bin'
      }
    ]);
    layerSpec = {
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
    spec = poly.spec.layerToData(layerSpec);
    deepEqual(spec.select, ["bin(a,0.10)", "lag(c,-0xaF1)", "mean(lag(c,0))", "bin(a,10)"]);
    deepEqual(spec.stats.groups, ["bin(a,0.10)", "lag(c,-0xaF1)", "bin(a,10)"]);
    deepEqual(spec.stats.stats, [
      {
        key: "lag(c,0)",
        name: "mean(lag(c,0))",
        stat: "mean"
      }
    ]);
    return deepEqual(spec.trans, [
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
    var layerSpec, spec;
    layerSpec = {
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
    spec = poly.spec.layerToData(layerSpec);
    return deepEqual(spec.select, ["bin(汉字漢字,10.4e20", "lag(',f+/\\\'c',-1", "mean(lag(c,-1))", "bin(\"a-+->\\\"b\", '漢\\\'字')"]);
  });

}).call(this);
