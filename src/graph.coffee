poly = @poly || {}

# Graph Object
class Graph
  constructor: (spec) ->
    @spec = spec
    # mode
    @strict = spec.strict ? false
    # creation of layers
    @layers = []
    spec.layers ?= []
    _.each spec.layers, (layerSpec) =>
      layerObj = poly.layer.make layerSpec, spec.strict
      @layers.push layerObj
    # calculation of statistics & layers
    merge = _.after(@layers.length, @merge)
    _.each @layers, (layerObj) ->
      layerObj.calculate(merge)

  merge: () =>
    spec = @spec
    # domain calculation and guide merging
    @domains = {}
    if spec.guides # for now, skip when guides are not defined
      spec.guides ?= {}
      @domains = poly.domain.make @layers, spec.guides, spec.strict
    # tick calculation (this needs to change completely)
    @ticks = {}
    _.each @domains, (domain, aes) =>
      @ticks[aes] = poly.tick.make(domain, spec.guides[aes] ? [])
    # dimension calculation
    @dims = poly.dim.make spec, @ticks
    @clipping = poly.dim.clipping @dims
    @ranges = poly.dim.ranges @dims
    # scale creation
    [@axis, @scales] = poly.scale.make(spec.guide, @domains, @ranges)

  render : (dom) =>
    dom = document.getElementById(dom)
    paper = poly.paper(dom, @dims.width, @dims.height)
    _.each @layers, (layer) =>
      poly.render layer.geoms, paper, @scales, @clipping
    # render axes

poly.chart = (spec) ->
  new Graph(spec)

@poly = poly
