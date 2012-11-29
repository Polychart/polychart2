poly = @poly || {}

# Graph Object
class Graph
  constructor: (spec) ->
    @graphId = _.uniqueId('graph_')
    @layers = null
    @scaleSet = null
    @axes = null
    @legends = null
    @dims = null
    @paper = null
    @initial_spec = spec
    @make spec

  reset : () => @make @initial_spec

  make: (spec) ->
    @spec = spec
    # creation of layers
    spec.layers ?= []
    @layers ?= @_makeLayers @spec
    # calculation of statistics & layers
    merge = _.after(@layers.length, @merge)
    _.each @layers, (layerObj, id) -> layerObj.make spec.layers[id], merge

  merge: () =>
    # make the scales...?
    domains = @_makeDomains @spec, @layers
    if @scaleSet?
      @scaleSet.setDomains domains
    else
      @scaleSet = @_makeScaleSet @spec, domains
    # dimension calculation
    @dims ?= @_makeDimensions @spec, @scaleSet
    @ranges ?= poly.dim.ranges @dims
    # rendering stuff...
    @scaleSet.setRanges @ranges
    @_legacy(domains)


  render : (dom) =>
    @paper ?= @_makePaper dom, @dims.width, @dims.height
    scales = @scaleSet.getScaleFns()
    clipping = poly.dim.clipping @dims
    # render each layer
    render = poly.render @graphId, @paper, scales, clipping
    _.each @layers, (layer) => layer.render(render)
    # render axes

  remake: (spec) ->
    @spec = spec
    remerge = _.after(@layers.length, @remerge)
    _.each @layers, (layer, k) ->
      layer.reset spec.layers[k]
      layer.recalculate remerge
  remerge: () =>
    domains = @_makeDomains @spec, @layers

  animate : () =>
    scales = @scaleSet.getScaleFns()
    clipping = poly.dim.clipping @dims
    render = poly.render @graphId, @paper, scales, @clipping
    _.each @layers, (layer) => layer.animate(@paper, render)

  _makeLayers: (spec) ->
    _.map spec.layers, (layerSpec) -> poly.layer.make(layerSpec, spec.strict)
  _makeDomains: (spec, layers) ->
    domains = {}
    if spec.guides # for now, skip when guides are not defined
      spec.guides ?= {}
      domains = poly.domain.make layers, spec.guides, spec.strict
    domains
  _makeScaleSet: (spec, domains) ->
    tmpRanges = poly.dim.ranges poly.dim.guess spec
    poly.scale.make spec.guides, domains, tmpRanges
  _makeDimensions: (spec, scaleSet) ->
    poly.dim.make spec, scaleSet.getAxes(), scaleSet.getLegends()
  _makePaper: (dom, width, height) ->
    poly.paper document.getElementById(dom), width, height


  _legacy: (domains) =>
    # LEGACY: tick calculation
    @domains = domains
    @scales = @scaleSet.getScaleFns()
    @ticks = {}
    _.each @axes, (v, k) => @ticks[k] = v.ticks

poly.chart = (spec) -> new Graph(spec)

@poly = poly
