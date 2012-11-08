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
    layerObj = poly.layer.make layerSpec, spec.strict
    layerObj.calculate()
    layers.push layerObj
  # domain calculation and guide merging
  domains = {}
  ticks = {}
  if spec.guides # for now, skip when guides are not defined
    spec.guides ?= {}
    domains = poly.domain.make layers, spec.guides, spec.strict

  # tick calculation
  _.each domains, (domain, aes) ->
    ticks[aes] = poly.tick.make(domain, spec.guides[aes] ? [])

  # dimension calculation
  dims = poly.dim.make(spec, ticks)

  # scale creation
  scales = poly.scale.make(spec.guide, domains, dims)

  # rendering

  return layers: layers, guides: domains, ticks: ticks, dims: dims, scales: scales

@poly = poly
