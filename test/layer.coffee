module "Layer"
test "point", ->
  jsondata= [
    {x: 2, y: 4},
    {x: 3, y: 3}
  ]
  data = new poly.Data (json: jsondata)
  spec =
    layers: [
      data: data, type: 'point', x: 'x', y: 'y'
    ]
  layers = poly.chart spec
  layer = layers[0]

  equal layer.geoms.length, 2
  equal layer.geoms[0].geom.type, 'point'
  equal layer.geoms[0].geom.x, 2
  equal layer.geoms[0].geom.y, 4
  equal layer.geoms[0].geom.color, layer.defaults.color
  deepEqual layer.geoms[0].evtData.x.in, [2]
  deepEqual layer.geoms[0].evtData.y.in, [4]

  equal layer.geoms[1].geom.type, 'point'
  equal layer.geoms[1].geom.x, 3
  equal layer.geoms[1].geom.y, 3
  equal layer.geoms[1].geom.color, layer.defaults.color
  deepEqual layer.geoms[1].evtData.x.in, [3]
  deepEqual layer.geoms[1].evtData.y.in, [3]

test "lines", ->
  # single line
  jsondata= [
    {x: 2, y: 4},
    {x: 3, y: 3}
  ]
  data = new poly.Data (json: jsondata)
  spec =
    layers: [
      data: data, type: 'line', x: 'x', y: 'y'
    ]
  layers = poly.chart spec
  layer = layers[0]

  equal layer.geoms.length, 1
  equal layer.geoms[0].geom.type, 'line'
  deepEqual layer.geoms[0].geom.x, [2, 3]
  deepEqual layer.geoms[0].geom.y, [4, 3]
  equal layer.geoms[0].geom.color, layer.defaults.color
  deepEqual layer.geoms[0].evtData, {}

  # one grouping
  jsondata= [
    {x: 2, y: 4, z: 'A'}
    {x: 3, y: 3, z: 'A'}
    {x: 1, y: 4, z: 2}
    {x: 5, y: 3, z: 2}
  ]
  data = new poly.Data (json: jsondata)
  spec =
    layers: [
      data: data, type: 'line', x: 'x', y: 'y', color: 'z'
    ]
  layers = poly.chart spec
  layer = layers[0]

  equal layer.geoms.length, 2
  equal layer.geoms[0].geom.type, 'line'
  deepEqual layer.geoms[0].geom.x, [2, 3]
  deepEqual layer.geoms[0].geom.y, [4, 3]
  deepEqual layer.geoms[0].geom.color, 'A'
  deepEqual layer.geoms[0].evtData.z.in, ['A']
  deepEqual layer.geoms[1].geom.x, [1, 5]
  deepEqual layer.geoms[1].geom.y, [4, 3]
  deepEqual layer.geoms[1].geom.color, 2
  deepEqual layer.geoms[1].evtData.z.in, [2]

