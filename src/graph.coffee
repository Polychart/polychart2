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
      poly.render layer.marks, paper, @scales

poly.chart = (spec) ->
  new Graph(spec)

@poly = poly
