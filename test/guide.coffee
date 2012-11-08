module "Guides"

jsondata= [
  {x: 2, y: 1},
  {x: 3, y: 3}
]
data = new poly.Data (json: jsondata)
sampleLayer = {data: data, type: 'point', x: 'x', y: 'y'}

test "domain: strict mode num & cat", ->
  spec =
    layers: [ sampleLayer ]
    strict: true
    guides:
      x: { type: 'num', min: 2, max: 4, bw : 3 }
      y: { type: 'cat', levels: [1,2,3], labels: {1: 'One', 2: 'Five'} }
  {domains, ticks} = poly.chart spec
  equal domains.x.type, 'num'
  equal domains.x.min , 2
  equal domains.x.max, 4
  equal domains.x.bw, 3
  equal domains.y.type, 'cat'
  deepEqual domains.y.levels, [1,2,3]
  equal domains.y.sorted, true

  deepEqual _.pluck(ticks.x, 'location'), [2, 2.5, 3, 3.5]
  deepEqual _.pluck(ticks.y, 'location'), [1, 2, 3]
  deepEqual _.pluck(ticks.y, 'value'), ['One', 'Five', 3]
