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
    @scaleSet ?= @_makeScaleSet()
    @scaleSet.make @spec.guides, domains, @layers
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
    renderer = poly.render @graphId, @paper, scales, clipping.main
    _.each @layers, (layer) => layer.render(renderer)
    # render axes
    axes = @scaleSet.makeAxes()
    legends = @scaleSet.makeLegends()

    axes.y.render @dims, poly.render @graphId, @paper, scales#, clipping.left
    axes.x.render @dims, poly.render @graphId, @paper, scales#, clipping.bottom

  _makeLayers: (spec) ->
    _.map spec.layers, (layerSpec) -> poly.layer.make(layerSpec, spec.strict)
  _makeDomains: (spec, layers) ->
    spec.guides ?= {}
    poly.domain.make layers, spec.guides, spec.strict
  _makeScaleSet: (spec, domains) ->
    tmpRanges = poly.dim.ranges poly.dim.guess spec
    poly.scale.make tmpRanges
  _makeDimensions: (spec, scaleSet) ->
    poly.dim.make spec, scaleSet.makeAxes(), scaleSet.makeLegends()
  _makePaper: (dom, width, height) ->
    poly.paper document.getElementById(dom), width, height
  _legacy: (domains) =>
    # LEGACY: tick calculation
    @domains = domains
    @scales = @scaleSet.getScaleFns()
    axes = @scaleSet.makeAxes()
    @ticks = {}
    _.each axes, (v, k) => @ticks[k] = v.ticks

poly.chart = (spec) -> new Graph(spec)

@poly = poly
