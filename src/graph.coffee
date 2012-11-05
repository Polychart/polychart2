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
    poly.data.processData layerSpec.data,
                          layerSpec,
                          spec.strict,
                          (statData, metaData) ->
      layerObj = poly.layer.makeLayer layerSpec, statData, metaData
      layerObj.calculate()
      layers.push layerObj

  # domain calculation and guide merging
  spec.guide ?= []
  poly.guide.makeGuides layers, spec.guide
  mergeGuides
  ###
@poly = poly
