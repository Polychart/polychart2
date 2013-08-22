module "Spec"
test "extraction: nothing (smoke test)", ->
  layerparser = {
    type: "point",
    y: {var: "b"},
    x: {var: "a"},
    color: {const: "blue"},
    opacity: {var: "c"},
  }
  dspec = polyjs.debug.spec.layerToData layerparser
  expected =
    filter: []
    sort: []
    select: ['a', 'b', 'c']
    stats: []
    groups: ['a', 'b', 'c']
    trans: []
  parserEqual dspec, expected

test "extraction: simple, one stat (smoke test)", ->
  layerparser = {
    type: "point",
    x: {var: "a"},
    y: {var: "sum(b)"},
  }
  dspec = polyjs.debug.spec.layerToData layerparser
  expected =
    filter: []
    sort: []
    select: ['a', 'sum(b)']
    stats: [{name:'sum', expr: 'sum(b)', args:['b']}]
    groups: ['a']
    trans: []
  parserEqual dspec, expected

test "extraction: stats + filter", ->
  layerparser = {
    type: "point",
    y: {var: "b", sort: "a"},
    x: {var: "a"},
    color: {const: "blue"},
    opacity: {var: "sum(c)"},
    filter: {a: {gt: 0, lt: 100}},
  }
  dspec = polyjs.debug.spec.layerToData layerparser
  expected =
    filter: [{expr: 'a', gt: 0, lt: 100}]
    sort: [{var: 'b', sort: 'a', limit: null, asc:false}]
    select: ['a', 'b', 'sum(c)']
    stats: [{name:'sum', expr: 'sum(c)', args:['c']}]
    groups: ['a', 'b']
    trans: []
  parserEqual dspec, expected

test "extraction: transforms", ->
  layerparser = {
    type: "point",
    y: {var: "log(b)", sort: "a", asc:true},
    x: {var: "c + 2"},
    color: {const: "blue"},
    opacity: {var: "count(d)"},
  }
  dspec = polyjs.debug.spec.layerToData layerparser
  expected =
    filter: []
    sort: [{var: 'log(b)', sort: 'a', limit: null, asc:true}]
    select: ['c + 2', 'log(b)', 'count(d)']
    stats: [{name:'count', expr: 'count(d)', args:['d']}]
    groups: ['c + 2', 'log(b)']
    trans: ['c + 2', 'log(b)']
  parserEqual dspec, expected

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
  for f in expected.filter
    f.expr = parse(f.expr)
  deepEqual produced.filter, expected.filter, 'filter'

  for val in expected.sort
    val.var = parse(val.var).name
    val.sort = parse val.sort
  deepEqual produced.sort, expected.sort, 'sort'
  deepEqual produced.select, (parse str for str in expected.select), 'select'

  for stat in expected.stats
    stat.args = (parse(a) for a in stat.args)
    stat.expr = parse stat.expr
  deepEqual produced.stats.stats, expected.stats, 'stats.stats'

  deepEqual produced.stats.groups, (parse str for str in expected.groups), 'stats.groups'
  deepEqual produced.trans, (parse str for str in expected.trans), 'trans'

