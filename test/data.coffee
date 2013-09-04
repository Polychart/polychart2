module "Data"

## HELPER FUNCTIONS
parse = (e) -> polyjs.debug.parser.getExpression(e).expr
transformData = (data, spec) ->
  data.getData (err, x)-> if err? then console.err err else x
  polyjs.data.frontendProcess spec, data, (err, x) -> if err? then console.err err else x
fill = (dataSpec) ->
  dataSpec.filter ?= []
  for f in dataSpec.filter
    f.expr = parse(f.expr)
  dataSpec.sort ?= []
  for val in dataSpec.sort
    val.key = parse val.key
    val.sort = parse val.sort
    val.args = (parse(a) for a in val.args ? [])
  dataSpec.select ?= []
  dataSpec.select = (parse str for str in dataSpec.select)
  dataSpec.trans ?= []
  dataSpec.trans = (parse(a) for a in dataSpec.trans)
  dataSpec.stats ?= {}
  dataSpec.stats.stats ?= []
  for stat in dataSpec.stats.stats
    stat.args = (parse(a) for a in stat.args)
    stat.expr = parse stat.expr
  dataSpec.stats.groups ?= []
  dataSpec.stats.groups = (parse(a) for a in dataSpec.stats.groups)
  return dataSpec

test "smoke test", ->
  jsondata= [
    {x: 2, y: 4},
    {x: 2, y: 4}
  ]
  data = polyjs.data (data: jsondata)
  deepEqual data.raw, jsondata

test "transforms -- string functions", ->
  data = polyjs.data data: [
    {x: 'calenDar '}, {x: 'pUppies'}, {x: 3}
  ]
  trans = transformData data, fill(trans:["substr([x], 0, 2)"])
  deepEqual _.pluck(trans.data, "substr([x],0,2)"), ['ca', 'pU', '3']

  trans = transformData data, fill(trans:["length(x)"])
  deepEqual _.pluck(trans.data, "length([x])"), [9,7, 1]

  trans = transformData data, fill(trans:["upper(x)"])
  deepEqual _.pluck(trans.data, "upper([x])"), ['CALENDAR ', 'PUPPIES', '3']

  trans = transformData data, fill(trans:["lower(x)"])
  deepEqual _.pluck(trans.data, "lower([x])"), ['calendar ', 'puppies', '3']

  trans = transformData data, fill(trans:["indexOf(x, 'e')"])
  deepEqual _.pluck(trans.data, 'indexOf([x],"e")'), [3, 5, -1]


  trans = transformData data, fill(trans:["parseNum(x)"])
  deepEqual _.pluck(trans.data, "parseNum([x])"), [NaN, NaN, 3]



test "transforms -- numeric binning", ->
  data = polyjs.data
    data: [
      {x: 12, y: 42},
      {x: 33, y: 56},
    ]
  trans = transformData data, fill(trans:["bin(x, 10)", "bin(y, 5)"])

  deepEqual trans.data, [
      {x: 12, y: 42, 'bin([x],10)': 10, 'bin([y],5)': 40},
      {x: 33, y: 56, 'bin([x],10)': 30, 'bin([y],5)': 55},
    ]

  data = polyjs.data
    data: [
      {x: 1.2, y: 1},
      {x: 3.3, y: 2},
      {x: 3.3, y: 3},
    ]
  trans = transformData data, fill(trans:["bin(x,1)", "lag(y,1)"])
  deepEqual trans.data, [
      {x: 1.2, y: 1, 'bin([x],1)': 1, 'lag([y],1)': undefined},
      {x: 3.3, y: 2, 'bin([x],1)': 3, 'lag([y],1)': 1},
      {x: 3.3, y: 3, 'bin([x],1)': 3, 'lag([y],1)': 2},
    ]

  data = polyjs.data
    data: [
      {x: 1.2, y: 1},
      {x: 3.3, y: 2},
      {x: 3.3, y: 3},
    ]
  trans = transformData data, fill(trans:["bin(x,1)", "lag(y,2)"])
  deepEqual trans.data, [
      {x: 1.2, y: 1, 'bin([x],1)': 1, 'lag([y],2)': undefined},
      {x: 3.3, y: 2, 'bin([x],1)': 3, 'lag([y],2)': undefined},
      {x: 3.3, y: 3, 'bin([x],1)': 3, 'lag([y],2)': 1},
    ]

test "other functions", ->
  data = polyjs.data
    data: [
      {x: 12, y: 42},
      {x: 33, y: 56},
    ]
  trans = transformData data, fill(trans:["x + y"])
  deepEqual trans.data, [
      {x: 12, y: 42, '([x] + [y])': 54},
      {x: 33, y: 56, '([x] + [y])': 89},
    ]

  data = polyjs.data
    data: [
      {x: 12, y: 42},
      {x: 33, y: 56},
    ]
  trans = transformData data, fill(trans:["x * 2 + y"])
  deepEqual trans.data, [
      {x: 12, y: 42, '(([x] * 2) + [y])': 66},
      {x: 33, y: 56, '(([x] * 2) + [y])': 122},
    ]

test "filtering", ->
  data = polyjs.data data: [
    {x: 1.2, y: 1},
    {x: 3.3, y: 2},
    {x: 3.4, y: 3},
  ]
  trans = transformData data, fill(
    trans: ["bin(x,1)", "lag([y], 1)"]
    filter: [
      {expr: 'x', lt: 3}
    ]
  )
  deepEqual trans.data, [
      {x: 1.2, y: 1, 'bin([x],1)': 1, 'lag([y],1)': undefined},
    ]

  trans = transformData data, fill(
    trans: ["bin(x, 1)", "lag(y, 1)"]
    filter: [{expr:'x', lt: 3.35, gt: 1.2}]
  )
  deepEqual trans.data, [
      {x: 3.3, y: 2, 'bin([x],1)': 3, 'lag([y],1)': 1},
    ]

  trans = transformData data, fill(
    trans: ["bin(x, 1)", "lag(y, 1)"]
    filter: [
      { expr: 'x', le: 3.35, ge: 1.2 }
      { expr: 'y', lt: 100 }
    ]
  )
  deepEqual trans.data, [
      {x: 1.2, y: 1, 'bin([x],1)': 1, 'lag([y],1)': undefined},
      {x: 3.3, y: 2, 'bin([x],1)': 3, 'lag([y],1)': 1},
    ]

  data = polyjs.data data:[
    {x: 1.2, y: 1, z: 'A'},
    {x: 3.3, y: 2, z: 'B'},
    {x: 3.4, y: 3, z: 'B'},
  ]
  trans = transformData data, fill(filter: [ {expr:'z', in: ['B']} ])
  deepEqual trans.data, [
      {x: 3.3, y: 2, z:'B'}
      {x: 3.4, y: 3, z:'B'}
    ]

  trans = transformData data,
  trans = transformData data, fill(filter: [ {expr:'z', in: ['A', 'B']} ])
  deepEqual trans.data, [
      {x: 1.2, y: 1, z:'A'}
      {x: 3.3, y: 2, z:'B'}
      {x: 3.4, y: 3, z:'B'}
    ]

test "statistics - count", ->
  data = polyjs.data data:[
    {x: 'A', y: 1, z:1}
    {x: 'A', y: 1, z:2}
    {x: 'A', y: 1, z:1}
    {x: 'A', y: 1, z:2}
    {x: 'A', y: 1, z:1}
    {x: 'A', y: 1, z:2}
    {x: 'B', y: 1, z:1}
    {x: 'B', y: 1, z:2}
    {x: 'B', y: 1, z:1}
    {x: 'B', y: 1, z:2}
    {x: 'B', y: undefined, z:1}
    {x: 'B', y: null, z:2}
  ]
  trans = transformData data, fill(
    stats:
      stats: [
        {name: 'count', expr: 'count(y)', args:['y']}
      ]
      groups: ['x']
  )
  deepEqual trans.data, [
      {x: 'A', 'count([y])': 6}
      {x: 'B', 'count([y])': 4}
    ]

  trans = transformData data, fill(
    stats:
      stats: [
        {name: 'count', expr: 'count(y)', args:['y']}
      ]
      groups: ['x', 'z']
  )
  deepEqual trans.data, [
      {x: 'A', z:1, 'count([y])': 3}
      {x: 'A', z:2, 'count([y])': 3}
      {x: 'B', z:1, 'count([y])': 2}
      {x: 'B', z:2, 'count([y])': 2}
    ]

  trans = transformData data, fill(
    stats:
      stats: [
        {name:'unique', expr: 'unique(y)', args:['y']}
      ],
      groups: ['x', 'z']
  )
  deepEqual trans.data, [
      {x: 'A', z:1, 'unique([y])': 1}
      {x: 'A', z:2, 'unique([y])': 1}
      {x: 'B', z:1, 'unique([y])': 1}
      {x: 'B', z:2, 'unique([y])': 1}
    ]

  trans = transformData data, fill(
    stats:
      stats: [
        {name: 'count', expr: 'count(y)', args:['y']}
        {name:'unique', expr: 'unique(y)', args:['y']}
      ]
      groups: ['x', 'z']
  )
  deepEqual trans.data, [
      {x: 'A', z:1, 'count([y])':3, 'unique([y])': 1}
      {x: 'A', z:2, 'count([y])':3, 'unique([y])': 1}
      {x: 'B', z:1, 'count([y])':2, 'unique([y])': 1}
      {x: 'B', z:2, 'count([y])':2, 'unique([y])': 1}
    ]

  data = polyjs.data data:[
    {x: 'A', y: 1, z:1}
    {x: 'A', y: 2, z:2}
    {x: 'A', y: 3, z:1}
    {x: 'A', y: 4, z:2}
    {x: 'A', y: 5, z:1}
    {x: 'B', y: 1, z:1}
    {x: 'B', y: 2, z:2}
    {x: 'B', y: 3, z:1}
    {x: 'B', y: 4, z:2}
  ]
  trans = transformData data, fill(
    stats:
      stats: [
        {args: ['y'], name: 'min', expr: 'min(y)'}
        {args: ['y'], name: 'max', expr: 'max(y)'}
        {args: ['y'], name: 'median', expr: 'median(y)'}
      ]
      groups: ['x']
  )
  deepEqual trans.data, [
      {x: 'A', 'min([y])': 1, 'max([y])': 5, 'median([y])': 3}
      {x: 'B', 'min([y])': 1, 'max([y])': 4, 'median([y])': 2.5}
    ]

  data = polyjs.data data:[
    {x: 'A', y: 15, z:1}
    {x: 'A', y: 3, z:2}
    {x: 'A', y: 4, z:1}
    {x: 'A', y: 1, z:2}
    {x: 'A', y: 2, z:1}
    {x: 'A', y: 6, z:2}
    {x: 'A', y: 5, z:1}
    {x: 'B', y: 1, z:1}
    {x: 'B', y: 2, z:2}
    {x: 'B', y: 3, z:1}
    {x: 'B', y: 4, z:2}
  ]
  trans = transformData data, fill(
    stats:
      stats: [
        args: ['y'], name: 'box', expr: 'box(y)'
      ]
      groups: ['x']
  )
  deepEqual trans.data, [
      {x: 'A', 'box([y])': {q1:1, q2:2.5, q3:4, q4:5.5, q5:6, outliers:[15]}}
      {x: 'B', 'box([y])': {outliers:[1,2,3,4]}}
    ]

test "meta sorting", ->
  data = polyjs.data data:[
    {x: 'A', y: 3}
    {x: 'B', y: 1}
    {x: 'C', y: 2}
  ]
  trans = transformData data, fill
    sort: [ {key: 'x', sort: 'y', asc: true} ]
  deepEqual _.pluck(trans.data, 'x'), ['B','C','A']

  trans = transformData data, fill
    sort: [ {key: 'x', sort: 'y', asc: true, limit: 2} ]
  deepEqual _.pluck(trans.data, 'x'), ['B','C']

  trans = transformData data, fill
    sort: [ {key: 'x', sort: 'y', asc: false, limit: 1} ]
  deepEqual _.pluck(trans.data, 'x'), ['A']

  data = polyjs.data data:[
    {x: 'A', y: 3}
    {x: 'B', y: 1}
    {x: 'C', y: 2}
    {x: 'C', y: 2}
  ]
  trans = transformData data, fill
    sort: [ {key: 'x', sort: 'sum(y)', stat: 'sum', asc: false, limit: 1, args: ['y']} ]
  deepEqual _.pluck(trans.data, 'x'), ['C', 'C']

  data = polyjs.data data:[
    {x: 'A', y: 3}
    {x: 'B', y: 1}
    {x: 'C', y: 2}
    {x: 'C', y: 2}
  ]
  trans = transformData data, fill
    sort: [ {key: 'x', sort: 'sum(y)', stat: 'sum', args: ['y'], asc: true, limit: 1} ]
  deepEqual _.pluck(trans.data, 'x'), ['B']

