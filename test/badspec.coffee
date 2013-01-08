module "Bad Spec"

data = polyjs.data json: [{a:2, b:1}]

test "no data", ->
  try
    polyjs.chart
      render: false
      layers: [
        type: 'point', x: 'x', y: 'y'
      ]
    ok false, 'no data to plot'
  catch err
    deepEqual err.name, 'DefinitionError'


test "referencing unknown variable", ->
  try
    polyjs.chart
      render: false
      layers: [
        data: data, type: 'point', x: 'x', y: 'c'
      ]
    ok false, 'referencing unknown var'
  catch err
    deepEqual err.name, 'DefinitionError'

  try
    polyjs.chart
      render: false
      layers: [
        data: data, type: 'point', x: 'x', y: 'sum(x)'
      ]
    ok false, 'referencing unknown var'
  catch err
    deepEqual err.name, 'DefinitionError'

  try
    polyjs.chart
      render: false
      layers: [
        data: data, type: 'point', x: 'b', y: 'sum(a)'
      ]
  catch err
    ok false, 'NOT referencing unknown var'

  try
    polyjs.chart
      render: false
      layers: [
        data: data, type: 'point', x: 'b', y: 'sum(lag(a,2))'
      ]
  catch err
    ok false, 'NOT referencing unknown var'

test "no layers", ->
  try
    polyjs.chart
      render: false
    ok false, 'no layer!'
  catch err
    deepEqual err.name, 'DefinitionError'

  try
    polyjs.chart
      render: false
      layers: []
    ok false, 'no layer!'
  catch err
    deepEqual err.name, 'DefinitionError'

  try
    polyjs.chart
      render: false
      layer: {data:data, type:'point', x:'a', y:'b'}
  catch err
    ok false, 'layer exists'

test "jibberish data", ->
  try
    data2 = {}
    polyjs.chart
      render: false
      layer: {data:data2, type:'foodish', x:'a', y:'b'}
    ok false, 'jibberish'
  catch err
    deepEqual err.name, 'DefinitionError'

test "jibberish layer", ->
  try
    polyjs.chart
      render: false
      layer: {data:data, type:'foodish', x:'a', y:'b'}
    ok false, 'jibberish'
  catch err
    deepEqual err.name, 'DefinitionError'
