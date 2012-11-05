poly = @poly || {}

# GRAPHS
class Graph
  constructor: (spec) ->
    graphSpec = spec

poly.chart = (spec) ->
  # modes
  spec.strict ?= false
  # data and layer calculation
  layers = []
  spec.layers ?= []
  _.each spec.layers, (layerSpec) ->
    callback = (statData, metaData) ->
      layerObj = poly.layer.makeLayer layerSpec, statData, metaData
      layerObj.calculate()
      layers.push layerObj
    poly.data.processData layerSpec.data, layerSpec, spec.strict, callback
  # domain calculation and guide merging
  guides = {}
  ticks = {}
  if spec.guides # for now, skip when guides are not defined
    spec.guides ?= {}
    guides = poly.guide.makeGuides layers, spec.guides, spec.strict

  # tick calculation
  _.each guides, (domain, aes) ->
    ticks[aes] = poly.guide.makeTicks(domain, spec.guides[aes] ? [])

  return layers: layers, guides: guides, ticks: ticks

@poly = poly
