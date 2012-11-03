poly = @poly || {}

# GRAPHS
class Graph
  constructor: (spec) ->
    graphSpec = spec

poly.chart = (spec) ->
  # data and layer calculation
  layers = []
  spec.layers = spec.layers || []
  _.each spec.layers, (layerSpec) ->
    poly.data.processData layerSpec.data, layerSpec, (statData, meta) ->
      layerObj = poly.layer.makeLayer layerSpec, statData
      layerObj.calculate()
      layers.push layerObj
  return layers
  ###
  # domain calculation and guide merging
  _.each layers (layerObj) ->
    makeGuides layerObj
  mergeGuides
  ###
@poly = poly
