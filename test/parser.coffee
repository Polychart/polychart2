module "parsers"
test "expressions", ->
  equal polyjs.debug.parser.tokenize('A').toString(), '<symbol,A>'
  equal polyjs.debug.parser.parse('A').toString(), 'Ident(A)'

  equal polyjs.debug.parser.tokenize('  A').toString(), '<symbol,A>'
  equal polyjs.debug.parser.parse('  A').toString(), 'Ident(A)'

  equal polyjs.debug.parser.tokenize('3.3445').toString(), '<literal,3.3445>'
  equal polyjs.debug.parser.parse('3.3445').toString(), 'Const(3.3445)'

  equal polyjs.debug.parser.tokenize('mean(A )').toString(), '<symbol,mean>,<(>,<symbol,A>,<)>'
  equal polyjs.debug.parser.parse('mean(A )').toString(), 'Call(mean,[Ident(A)])'

  equal polyjs.debug.parser.tokenize(' mean(A )').toString(), '<symbol,mean>,<(>,<symbol,A>,<)>'
  equal polyjs.debug.parser.parse('mean(A )').toString(), 'Call(mean,[Ident(A)])'

  equal polyjs.debug.parser.tokenize('mean( A )  ').toString(), '<symbol,mean>,<(>,<symbol,A>,<)>'
  equal polyjs.debug.parser.parse('mean( A )  ').toString(), 'Call(mean,[Ident(A)])'

  equal polyjs.debug.parser.tokenize('log(mean(sum(A_0), 10), 2.7188, CCC)').toString(), '<symbol,log>,<(>,<symbol,mean>,<(>,<symbol,sum>,<(>,<symbol,A_0>,<)>,<,>,<literal,10>,<)>,<,>,<literal,2.7188>,<,>,<symbol,CCC>,<)>'
  equal polyjs.debug.parser.parse('log(mean(sum(A_0), 10), 2.7188, CCC)').toString(), 'Call(log,[Call(mean,[Call(sum,[Ident(A_0)]),Const(10)]),Const(2.7188),Ident(CCC)])'

  equal polyjs.debug.parser.tokenize('this(should, break').toString(), '<symbol,this>,<(>,<symbol,should>,<,>,<symbol,break>'
  try
    polyjs.debug.parser.parse('this(should, break').toString()
    ok false, 'this(should, break'
  catch e
    equal e.message, 'There is an error in your specification at Stream([])'

  try
    polyjs.debug.parser.parse(')this(should, break').toString()
    ok false, ')this(should, break'
  catch e
    equal e.message, 'There is an error in your specification at Stream([<)>,<symbol,this>,<(>,<symbol,should>,<,>,<symbol,break>])'

  try
    polyjs.debug.parser.parse('this should break').toString()
    ok false, 'this should break'
  catch e
    equal e.message, "There is an error in your specification at Stream([<symbol,should>,<symbol,break>])"

test "extraction: nothing (smoke test)", ->
  layerparser = {
    type: "point",
    y: {var: "b"},
    x: {var: "a"},
    color: {const: "blue"},
    opacity: {var: "c"},
  }
  parser = polyjs.debug.parser.layerToData layerparser
  deepEqual parser.filter, {}
  deepEqual parser.meta, {}
  deepEqual parser.select, ['a', 'b', 'c']
  deepEqual parser.stats.stats, []
  deepEqual parser.trans, []

test "extraction: simple, one stat (smoke test)", ->
  debugger
  layerparser = {
    type: "point",
    x: {var: "a"},
    y: {var: "sum(b)"},
  }
  parser = polyjs.debug.parser.layerToData layerparser
  deepEqual parser.filter, {}
  deepEqual parser.meta, {}
  deepEqual parser.select, ['a', 'sum(b)']
  deepEqual parser.stats.stats, [key:'b', stat:'sum',name:'sum(b)']
  deepEqual parser.stats.groups, ['a']
  deepEqual parser.trans, []

test "extraction: stats", ->
  layerparser = {
    type: "point",
    y: {var: "b", sort: "a", guide: "y2"},
    x: {var: "a"},
    color: {const: "blue"},
    opacity: {var: "sum(c)"},
    filter: {a: {gt: 0, lt: 100}},
  }
  parser = polyjs.debug.parser.layerToData layerparser
  deepEqual parser.filter, layerparser.filter
  deepEqual parser.meta, {b: {sort:'a', asc:false}}
  deepEqual parser.select, ['a', 'b', 'sum(c)']
  deepEqual parser.stats.groups, ['a','b']
  deepEqual parser.stats.stats, [key:'c', name:'sum(c)', stat:'sum']
  deepEqual parser.trans, []

test "extraction: transforms", ->
  layerparser = {
    type: "point",
    y: {var: "b", sort: "a", guide: "y2"},
    x: {var: "lag(a, 1)"},
    color: {const: "blue"},
    opacity: {var: "sum(c)"},
    filter: {a: {gt: 0, lt: 100}},
  }
  parser = polyjs.debug.parser.layerToData layerparser
  deepEqual parser.filter, layerparser.filter
  deepEqual parser.meta, {b: {sort:'a', asc:false}}
  deepEqual parser.select, ['lag(a,1)', 'b', 'sum(c)']
  deepEqual parser.stats.groups, ['lag(a,1)', 'b']
  deepEqual parser.stats.stats, [key:'c', name:'sum(c)', stat:'sum']
  deepEqual parser.trans, [key:'a', lag:'1', name:'lag(a,1)', trans:'lag']

  layerparser = {
    type: "point",
    y: {var: "b", sort: "a", guide: "y2", asc:true},
    x: {var: "bin(a, 1)"},
    color: {const: "blue"},
    opacity: {var: "sum(c)"},
    filter: {a: {gt: 0, lt: 100}},
  }
  parser = polyjs.debug.parser.layerToData layerparser
  deepEqual parser.filter, layerparser.filter
  deepEqual parser.meta, {b: {sort:'a', asc:true}}
  deepEqual parser.select, ['bin(a,1)', 'b', 'sum(c)']
  deepEqual parser.stats.groups, ['bin(a,1)', 'b']
  deepEqual parser.stats.stats, [key:'c', name:'sum(c)', stat:'sum']
  deepEqual parser.trans, [key:'a', binwidth:'1', name:'bin(a,1)', trans:'bin']

  layerparser =
    type: "point"
    y: {var: "lag(c , -0xaF1) "}
    x: {var: "bin(a, 0.10)"}
    color: {var: "mean(lag(c,0))"}
    opacity: {var: "bin(a, 10)"}
  parser = polyjs.debug.parser.layerToData layerparser
  deepEqual parser.select, ["bin(a,0.10)", "lag(c,-0xaF1)", "mean(lag(c,0))", "bin(a,10)"]
  deepEqual parser.stats.groups, ["bin(a,0.10)", "lag(c,-0xaF1)", "bin(a,10)"]
  deepEqual parser.stats.stats, [key: "lag(c,0)", name: "mean(lag(c,0))", stat: "mean" ]
  deepEqual parser.trans,
    [
      {
        "key": "a",
        "binwidth": "10",
        "name": "bin(a,10)",
        "trans": "bin"
      },
      {
        "key": "c",
        "lag": "0",
        "name": "lag(c,0)",
        "trans": "lag"
      },
      {
        "key": "c",
        "lag": "-0xaF1",
        "name": "lag(c,-0xaF1)",
        "trans": "lag"
      },
      {
        "key": "a",
        "binwidth": "0.10",
        "name": "bin(a,0.10)",
        "trans": "bin"
      }
    ]

test "extraction: UTF8", ->
  layerparser=
    type: "point"
    y: {var: "lag(',f+/\\\'c' , -1) "}
    x: {var: "bin(汉字漢字, 10.4e20)"}
    color: {var: "mean(lag(c, -1))"}
    opacity: {var: "bin(\"a-+->\\\"b\", '漢\\\'字')"}
  parser = polyjs.debug.parser.layerToData layerparser
  deepEqual parser.select, ["bin(汉字漢字,10.4e20", "lag(',f+/\\\'c',-1", "mean(lag(c,-1))", "bin(\"a-+->\\\"b\", '漢\\\'字')"]

