poly = @poly || {}

# Graph Object
class Graph
  constructor: (spec) ->
    @graphId = _.uniqueId('graph_')
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
    # make the scales...?
    tmpRanges = poly.dim.ranges poly.dim.guess @spec
    @scaleSet = poly.scale.make spec.guides, @domains, tmpRanges
    # make the legends & axes?
    @axes = @scaleSet.getAxes()
    @legends = @scaleSet.getLegends()
    # dimension calculation
    @dims = poly.dim.make spec, @axes, @legends # calls guessdim internally
    # rendering stuff...
    @scaleSet.setRanges poly.dim.ranges(@dims)
    @scales = @scaleSet.getScaleFns()

    # LEGACY: tick calculation
    @ticks = {}
    _.each @axes, (v, k) => @ticks[k] = v.ticks

  render : (dom) =>
    dom = document.getElementById(dom)
    paper = poly.paper(dom, @dims.width, @dims.height)
    @clipping = poly.dim.clipping @dims
    # render each layer
    render = poly.render @graphId, paper, @scales, @clipping
    _.each @layers, (layer) => layer.render(paper, render)
    # render axes

poly.chart = (spec) ->
  new Graph(spec)

@poly = poly
