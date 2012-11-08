poly = @poly || {}

# GRAPHS
class Graph
  constructor: (spec) ->
    @spec = spec
    # mode
    spec.strict ?= false
    @strict = spec.strict
    # data and layer calculation
    @layers = []
    spec.layers ?= []
    _.each spec.layers, (layerSpec) =>
      layerObj = poly.layer.make layerSpec, spec.strict
      layerObj.calculate()
      @layers.push layerObj
    # domain calculation and guide merging
    @domains = {}
    if spec.guides # for now, skip when guides are not defined
      spec.guides ?= {}
      @domains = poly.domain.make @layers, spec.guides, spec.strict
    # tick calculation
    @ticks = {}
    _.each @domains, (domain, aes) =>
      @ticks[aes] = poly.tick.make(domain, spec.guides[aes] ? [])
    # dimension calculation
    @dims = poly.dim.make(spec, @ticks)
    # scale creation
    @scales = poly.scale.make(spec.guide, @domains, @dims)
    # rendering
  render : (dom) =>
    dom = document.getElementById(dom)
    paper = poly.paper(dom, 300, 300)
    _.each @layers, (layer) =>
      poly.render layer.geoms, paper, @scales

poly.chart = (spec) ->
  new Graph(spec)

@poly = poly
