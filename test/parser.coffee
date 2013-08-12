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

  equal polyjs.debug.parser.parse('[this is one identifier]').toString(), 'Ident(this is one identifier)'
  equal polyjs.debug.parser.parse('[this is \\[also\\] one identifier]').toString(), 'Ident(this is [also] one identifier)'

  equal polyjs.debug.parser.tokenize('(3 + four * 5 - 6 / 7 % 8) ++ nine').toString(), '<(>,<literal,3>,<infixsymbol,+>,<symbol,four>,<infixsymbol,*>,<literal,5>,<infixsymbol,->,<literal,6>,<infixsymbol,/>,<literal,7>,<infixsymbol,%>,<literal,8>,<)>,<infixsymbol,++>,<symbol,nine>'
  equal polyjs.debug.parser.parse('3 + four * 5 - six').pretty(), '((3 + ([four] * 5)) - [six])'
  equal polyjs.debug.parser.parse('3 - four * 5 + six').pretty(), '(3 - (([four] * 5) + [six]))'
  equal polyjs.debug.parser.parse('(3 + four * 5 - 6 / 7 % 8) ++ nine').pretty(), '(((3 + ([four] * 5)) - ((6 / 7) % 8)) ++ [nine])'
  equal polyjs.debug.parser.parse('3 + four * 5 - 6 / 7 % 8 ++ nine').pretty(), '((3 + ([four] * 5)) - ((6 / 7) % (8 ++ [nine])))'

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

parserEqual = (produced, expected) ->
  parse = polyjs.debug.parser.parse
  filter = {}
  for key, val of expected.filter
    filter[parse key] = val
  deepEqual produced.filter, filter
  sort = {}
  for key, val of expected.sort
    if 'sort' of val
      val.sort = parse val.sort
    sort[parse key] = val
  deepEqual produced.sort, sort
  deepEqual produced.select, (parse str for str in expected.select)
  deepEqual produced.stats.groups, (parse str for str in expected.groups)
  fix = (keyword, dict) ->
    result = []
    for item in dict
      newitem = {}
      for key, val of item
        if key isnt keyword
          newitem[key] = parse val
      newitem[keyword] = item[keyword]
      result.push newitem
    result
  stats = fix('stat', expected.stats)
  deepEqual produced.stats.stats, stats
  trans = fix('trans', expected.trans)
  deepEqual produced.trans, trans

test "extraction: nothing (smoke test)", ->
  layerparser = {
    type: "point",
    y: {var: "b"},
    x: {var: "a"},
    color: {const: "blue"},
    opacity: {var: "c"},
  }
  parser = polyjs.debug.parser.layerToData layerparser
  expected = {filter: {}, sort: {}, select: ['a', 'b', 'c'], groups: ['a', 'b', 'c'], stats: [], trans: []}
  parserEqual parser, expected

test "extraction: simple, one stat (smoke test)", ->
  layerparser = {
    type: "point",
    x: {var: "a"},
    y: {var: "sum(b)"},
  }
  parser = polyjs.debug.parser.layerToData layerparser
  expected = {filter: {}, sort: {}, select: ['a', 'sum(b)'], groups: ['a'], stats: [{key:'b', stat:'sum', name:'sum(b)'}], trans: []}
  parserEqual parser, expected

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
  expected = {filter: layerparser.filter, sort: {b: {sort:'a', asc:false}}, select: ['a', 'b', 'sum(c)'], groups: ['a', 'b'], stats: [key:'c', name:'sum(c)', stat:'sum'], trans: []}
  parserEqual parser, expected

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
  expected = {filter: layerparser.filter, sort: {b: {sort:'a', asc:false}}, select: ['lag(a,1)', 'b', 'sum(c)'], groups: ['lag(a,1)', 'b'], stats: [key:'c', name:'sum(c)', stat:'sum'], trans: [key:'a', lag:'1', name:'lag(a,1)', trans:'lag']}
  parserEqual parser, expected

  layerparser = {
    type: "point",
    y: {var: "b", sort: "a", guide: "y2", asc:true},
    x: {var: "bin(a, 1)"},
    color: {const: "blue"},
    opacity: {var: "sum(c)"},
    filter: {a: {gt: 0, lt: 100}},
  }
  parser = polyjs.debug.parser.layerToData layerparser
  expected = {filter: layerparser.filter, sort: {b: {sort:'a', asc:true}}, select: ['bin(a,1)', 'b', 'sum(c)'], groups: ['bin(a,1)', 'b'], stats: [key:'c', name:'sum(c)', stat:'sum'], trans: [key:'a', binwidth:'1', name:'bin(a,1)', trans:'bin']}
  parserEqual parser, expected

  layerparser =
    type: "point"
    y: {var: "lag(c , -0xaF1) "}
    x: {var: "bin(a, 0.10)"}
    color: {var: "mean(lag(c,0))"}
    opacity: {var: "bin(a, 10)"}
  parser = polyjs.debug.parser.layerToData layerparser
  expected = {filter: {}, sort: {}, select: ["bin(a,0.10)", "lag(c,-0xaF1)", "mean(lag(c,0))", "bin(a,10)"], groups: ["bin(a,0.10)", "lag(c,-0xaF1)", "bin(a,10)"], stats: [key: "lag(c,0)", name: "mean(lag(c,0))", stat: "mean" ], trans: [
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
    ]}
  parserEqual parser, expected

test "extraction: UTF8", ->
  layerparser=
    type: "point"
    y: {var: "lag(',f+/\\\'c' , -1) "}
    x: {var: "bin(汉字漢字, 10.4e20)"}
    color: {var: "mean(lag(c, -1))"}
    opacity: {var: "bin(\"a-+->\\\"b\", '漢\\\'字')"}
  parser = polyjs.debug.parser.layerToData layerparser
  deepEqual parser.select, (polyjs.debug.parser.parse str for str in ["bin(汉字漢字,10.4e20", "lag(',f+/\\\'c',-1", "mean(lag(c,-1))", "bin(\"a-+->\\\"b\", '漢\\\'字')"])

