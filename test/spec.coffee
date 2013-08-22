module "Spec"
test "extraction: nothing (smoke test)", ->
  layerparser = {
    type: "point",
    y: {var: "b"},
    x: {var: "a"},
    color: {const: "blue"},
    opacity: {var: "c"},
  }
  parser = polyjs.debug.spec.layerToData layerparser
  expected =
    filter: {}
    sort: {}
    select: ['a', 'b', 'c']
    stats: []
    groups: ['a', 'b', 'c']
    trans: []
  parserEqual parser, expected

test "extraction: simple, one stat (smoke test)", ->
  layerparser = {
    type: "point",
    x: {var: "a"},
    y: {var: "sum(b)"},
  }
  parser = polyjs.debug.spec.layerToData layerparser
  expected =
    filter: {}
    sort: {}
    select: ['a', 'sum(b)']
    stats: [{name:'sum', expr: 'a'}]
    groups: ['a']
    trans: []
  parserEqual parser, expected


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
  parser = polyjs.debug.spec.layerToData layerparser
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
  parser = polyjs.debug.spec.layerToData layerparser
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
  parser = polyjs.debug.spec.layerToData layerparser
  expected = {filter: layerparser.filter, sort: {b: {sort:'a', asc:true}}, select: ['bin(a,1)', 'b', 'sum(c)'], groups: ['bin(a,1)', 'b'], stats: [key:'c', name:'sum(c)', stat:'sum'], trans: [key:'a', binwidth:'1', name:'bin(a,1)', trans:'bin']}
  parserEqual parser, expected

  layerparser =
    type: "point"
    y: {var: "lag(c , -0xaF1) "}
    x: {var: "bin(a, 0.10)"}
    color: {var: "mean(lag(c,0))"}
    opacity: {var: "bin(a, 10)"}
  parser = polyjs.debug.spec.layerToData layerparser
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
  parser = polyjs.debug.spec.layerToData layerparser
  deepEqual parser.select, (polyjs.debug.parser.parse str for str in ["bin(汉字漢字,10.4e20", "lag(',f+/\\\'c',-1", "mean(lag(c,-1))", "bin(\"a-+->\\\"b\", '漢\\\'字')"])


parserEqual = (produced, expected) ->
  parse = (e) -> polyjs.debug.parser.getExpression(e).expr
  filter = []
  for key, val of expected.filter
    val.expr = parse(key)
    filter.push val
  deepEqual produced.filter, filter, 'filter'

  sort = []
  for key, val of expected.sort
    val.sort = parse val.sort
    sort.push val
  deepEqual produced.sort, sort, 'sort'
  deepEqual produced.select, (parse str for str in expected.select), 'select'

  stats = []
  for stat in stats
    stats.expr = parse stats.expr
  deepEqual produced.stats.stats, stats, 'stats.stats'

  deepEqual produced.stats.groups, (parse str for str in expected.groups), 'stats.groups'
  deepEqual produced.trans, (parse str for str in expected.trans), 'trans'

