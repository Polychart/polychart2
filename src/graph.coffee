# Graph Object
class Graph
  constructor: (spec) ->
    if not spec?
      throw poly.error.defn "No graph specification is passed in!"
    @handlers = []
    @panes = null
    @scaleSet = null
    @axes = null
    @legends = null
    @dims = null
    @paper = null
    @coord = spec.coord ? poly.coord.cartesian()
    @initial_spec = spec
    @dataSubscribed = false
    @make spec

  reset : () =>
    if not @initial_spec?
      throw poly.error.defn "No graph specification is passed in!"
    @make @initial_spec

  make: (spec) ->
    spec ?= @initial_spec
    spec = poly.spec.toStrictMode spec
    poly.spec.check spec
    @spec = spec
    # facet?
    @facet = poly.facet.make @spec.facet
    # subscribe to changes to data
    if not @dataSubscribed
      dataChange = @handleEvent 'data'
      for layerSpec, id in spec.layers
        spec.layers[id].data.subscribe dataChange
      @dataSubscribed = true
    # callback after data processing
    merge = _.after(spec.layers.length, @merge)
    @dataprocess = {}
    processedData = {}
    for layerSpec, id in spec.layers
      spec = @spec.layers[id] #repeated
      @dataprocess[id] = new poly.DataProcess spec, spec.strict
      @dataprocess[id].make spec, @facet.groups, (statData, metaData) =>
        processedData[id] =
          statData: statData
          metaData: metaData
        merge()
  merge: (merge) =>
    @makePanes()
    @mergeDomains()
    @render()
  makePanes: () =>
    # prep work to make indices
    indices = @facet.getIndices @dataprocess
    # make panes
    @panes ?= @_makePanes @spec, @dataprocess, indices
    # make data
    datas = @facet.groupData @dataprocess
    # set data
    for key, pane of @panes
      pane.make @spec, datas[key]
  mergeDomains: () =>
    domainsets = _.map @panes, (p) -> p.domains
    domains = poly.domain.merge domainsets
    @scaleSet ?= @_makeScaleSet @spec, domains, @facet
    @scaleSet.make @spec.guides, domains, _.toArray(@panes)[0].layers
    # dimension calculation
    if not @dims
      @dims = @_makeDimensions @spec, @scaleSet, @facet
      @coord.make @dims
      @ranges = @coord.ranges()
    @scaleSet.setRanges @ranges
  render: () =>
    if @spec.render? and @spec.render is false
      return # for debugging purposes
    dom = @spec.dom
    scales = @scaleSet.scales
    @coord.setScales scales
    @scaleSet.coord = @coord
    @scaleSet.makeAxes _.keys @panes # TODO: use indices here? pass in Facet?
    @scaleSet.makeLegends()

    @paper ?= @_makePaper dom, @dims.width, @dims.height, @handleEvent
    clipping = @coord.clipping @dims
    renderer = poly.render @handleEvent, @paper, scales, @coord, true, clipping
    rendererG = poly.render @handleEvent, @paper, scales, @coord, false

    for key, pane of @panes
      pane.render renderer @facet.getOffset(@dims, key)

    @scaleSet.renderAxes @dims, rendererG, @facet
    @scaleSet.renderLegends @dims, rendererG({})

  addHandler : (h) -> @handlers.push h
  removeHandler: (h) ->
    @handlers.splice _.indexOf(@handlers, h), 1

  handleEvent : (type) =>
    # POSSIBLE EVENTS: select, click, mover, mout, data
    graph = @
    handler = (params) ->
      obj = @
      if type == 'select'
        {start, end} = params
        obj.evtData = graph.scaleSet.fromPixels start, end
      else if type == 'data'
        obj.evtData = {}
      else
        obj.evtData = obj.data('e')

      for h in graph.handlers
        if _.isFunction(h)
          h(type, obj)
        else
          h.handle(type, obj)
    _.throttle handler, 1000
  _makePanes: (spec, processedData, indices) ->
    # make panes
    panes = {}
    for identifier, mindex of indices
      panes[identifier] = poly.pane.make spec, mindex
    panes


  _makeScaleSet: (spec, domains, facet) ->
    @coord.make poly.dim.guess(spec, facet.getGrid())
    tmpRanges = @coord.ranges()
    poly.scaleset tmpRanges, @coord
  _makeDimensions: (spec, scaleSet, facet) ->
    axis = scaleSet.makeAxes(_.keys(@panes))
    legend = scaleSet.makeLegends()
    poly.dim.make spec, axis, legend, facet.getGrid()
  _makePaper: (dom, width, height, handleEvent) ->
    if _.isString dom then dom = document.getElementById(dom)
    paper = poly.paper dom, width, height, handleEvent

poly.chart = (spec) -> new Graph(spec)
