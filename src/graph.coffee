##
#
# Graph Object And Entry Point: poly.chart()
# ------------------------------------------
# This is the main graph object and controls the main visualization workflow.
##

class Graph
  ###
  The constructor does not do any real work. It just sets a bunch of variables
  to its default value and call @make(), which actually does the real work.
  ###
  constructor: (spec) ->
    if not spec?
      throw poly.error.defn "No graph specification is passed in!"
    @handlers = []
    @scaleSet = null
    @axes = null
    @legends = null
    @dims = null
    @paper = null
    @coord = null
    @facet = poly.facet.make()
    @dataSubscribed = []
    @make spec

    # Post make work, things that do not have to be updated
    # Default handlers
    @addHandler poly.handler.tooltip()
    @addHandler poly.handler.zoom(spec)

  ###
  Remove all existing items on the graph, if necessary
  ###
  maybeDispose: (spec) =>
    renderer = poly.render @handleEvent, @paper, @scaleSet.scales, @coord
    renderer = renderer()
    if @coord and !_.isEqual(@coord.spec, spec.coord)
      if @scaleSet
        @scaleSet.disposeGuides(renderer)
        @scaleSet = null
      @coord = null
  ###
  Begin work to plot the graph. This function does only half of the work:
  i.e. things that needs to be done prior to data process. Because data
  process may be asynchronous, we pass in @merge() as a callback for when
  data processing is complete.
  ###
  make: (spec, @callback) ->
    if spec?
      spec = poly.spec.toStrictMode spec
      poly.spec.check spec
      @spec = spec
    else spec = @spec
    # check if we need to re-plot the graph from scratch
    if @scaleSet
      @maybeDispose(spec)
    @coord ?= poly.coord.make @spec.coord
    @facet.make(spec)

    # subscribe to changes to data -- bad heuristics!
    dataChange = @handleEvent 'data'
    datas = (layerSpec.data for layerSpec, id in spec.layers)
    for d in _.difference(datas, @dataSubscribed)
      d.subscribe dataChange
    @dataSubscribed = datas

    # callback after data processing
    merge = _.after(spec.layers.length, @merge)
    @dataprocess = {}
    @processedData = {}
    _.each spec.layers, (layerSpec, id) =>
      # using _ instead of a for loop to scope the id
      spec = @spec.layers[id] #repeated
      groups = _.values @facet.specgroups
      @dataprocess[id] = new poly.DataProcess spec, groups, spec.strict
      @dataprocess[id].make spec, groups, (statData, metaData) =>
        @processedData[id] =
          statData: statData
          metaData: metaData
        merge()
  ###
  Complete work to plot the graph. This includes three stages:
    1) Create each "pane". Each "pane" is a facet containing a smallversion
       of the chart, filtered to only data that falls within that facet.
    2) Merge the domains from each layer and each pane. This is used to
       define scales and determine the min/max point of each axis.
    3) Actually render the chart.
  ###
  merge: () =>
    @layers = _.map @spec.layers, (layerSpec) => poly.layer.make(layerSpec, @spec.strict, @spec.guides)
    @facet.calculate(@processedData, @layers)
    @mergeDomains()
    @render()
  mergeDomains: () =>
    domainsets = _.map @facet.panes, (p) -> p.domains
    domains = poly.domain.merge domainsets
    if not @scaleSet
      tmpDims = poly.dim.guess(@spec, @facet.getGrid())
      @coord.make tmpDims
      tmpRanges = @coord.ranges()
      @scaleSet = poly.scaleset tmpRanges, @coord
    @scaleSet.make @spec.guides, domains, @layers
    # dimension calculation
    #if not @dims
    @dims = @_makeDimensions @spec, @scaleSet, @facet, tmpDims
    @coord.make @dims
    @ranges = @coord.ranges()
    # end
    @scaleSet.setRanges @ranges
  render: () =>
    if @spec.render? and @spec.render is false
      return # for debugging purposes
    scales = @scaleSet.scales
    @coord.setScales scales
    @scaleSet.coord = @coord
    {@axes, @titles, @legends} = @scaleSet.makeGuides(@spec, @dims)

    @dom = @spec.dom
    @paper ?= @_makePaper @dom, @dims.width, @dims.height, @
    renderer = poly.render @handleEvent, @paper, scales, @coord

    @facet.render(renderer, @dims, @coord)
    @scaleSet.renderGuides @dims, renderer, @facet
    if @callback
      @callback()

  addHandler : (h) -> if h not in @handlers then @handlers.push h
  removeHandler: (h) ->
    @handlers.splice _.indexOf(@handlers, h), 1

  handleEvent : (type) =>
    # POSSIBLE EVENTS: select, click, guide-click, mover, mout, data, reset
    graph = @
    handler = (event) ->
      obj = @
      if type == 'select'
        {start, end} = event
        f1 = graph.facet.getFacetInfo(graph.dims, start.x, start.y)
        if not f1 then return # Did not start in a facet
        {col, row, evtData, adjusted} = f1
        adjStart = _.clone adjusted
        {adjusted} = graph.facet.getFacetInfo(graph.dims, end.x, end.y, {col, row})
        adjEnd = _.clone adjusted
        if graph.coord.type is 'cartesian'
          obj.evtData = graph.scaleSet.fromPixels adjStart, adjEnd
        else
          obj.evtData = null
      else if type == 'data'
        obj.evtData = {}
      else if type in ['reset', 'click', 'mover', 'mout', 'guide-click']
        obj.tooltip = obj.data('t')
        obj.evtData = obj.data('e')
        # if type is 'reset'
        #   {x, y} = poly.getXY(poly.offset(graph.dom), event)
        #   f = graph.facet.getFacetInfo(graph.dims, x, y)
        #   if not f then return

      for h in graph.handlers
        if _.isFunction(h)
          h(type, obj, event, graph)
        else
          h.handle(type, obj, event, graph)
    _.throttle handler, 300
  _makeScaleSet: (spec, domains, facet) ->
    tmpRanges = @coord.ranges()
    poly.scaleset tmpRanges, @coord
  _makeDimensions: (spec, scaleSet, facet, tmpDims) ->
    scaleSet.makeGuides(spec, tmpDims)
    poly.dim.make spec, scaleSet, facet.getGrid()
  _makePaper: (dom, width, height, handleEvent) ->
    paper = poly.paper dom, width, height, handleEvent

poly.chart = (spec) -> new Graph(spec)
