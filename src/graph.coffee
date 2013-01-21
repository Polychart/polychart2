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
    @coord = poly.coord.make spec.coord
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
    @processedData = {}
    for layerSpec, id in spec.layers
      spec = @spec.layers[id] #repeated
      @dataprocess[id] = new poly.DataProcess spec, @facet.groups, spec.strict
      @dataprocess[id].make spec, @facet.groups, (statData, metaData) =>
        @processedData[id] =
          statData: statData
          metaData: metaData
        merge()
    # default handlers
    @addHandler polyjs.handler.tooltip()
  merge: () =>
    @makePanes()
    @mergeDomains()
    @render()
  makePanes: () =>
    # prep work to make indices
    indices = @facet.getIndices @processedData
    datas = @facet.groupData @processedData
    formatter = @facet.getFormatter()
    # make panes
    @panes ?= @_makePanes @spec, indices, formatter
    # make data
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
    renderer = poly.render @handleEvent, @paper, scales, @coord

    for key, pane of @panes
      offset = @facet.getOffset(@dims, key)
      clipping = @coord.clipping offset
      pane.render renderer, offset, clipping, @dims

    # axes
    @scaleSet.renderAxes @dims, renderer, @facet
    @scaleSet.renderTitles @dims, renderer
    # legend
    @scaleSet.renderLegends @dims, renderer({}, false, false)
    ### labels
    @scaleSet.renderFacetLabels @dims, rendererG, @facet
    @scaleSet.renderTitle @dims, rendererG, @facet
    ###

  debugRender: (mark) ->
    geom = marks: 0: mark
    scales = @scaleSet.scales
    renderer = poly.render @handleEvent, @paper, scales, @coord
    for key, pane of @panes
      offset = @facet.getOffset(@dims, key)
      clipping = @coord.clipping offset
      r = renderer(offset, clipping, true)
      r.render(geom)

  addHandler : (h) -> @handlers.push h
  removeHandler: (h) ->
    @handlers.splice _.indexOf(@handlers, h), 1

  handleEvent : (type) =>
    # POSSIBLE EVENTS: select, click, mover, mout, data
    graph = @
    handler = (event) ->
      obj = @
      if type == 'select'
        {start, end} = event
        graph.paper.rect(start.y, start.x, end.y-start.y, end.x-start.x)
        obj.evtData = graph.scaleSet.fromPixels start, end
      else if type == 'data'
        obj.evtData = {}
      else
        obj.tooltip = obj.data('t')
        obj.evtData = obj.data('e')

      for h in graph.handlers
        if _.isFunction(h)
          h(type, obj, event)
        else
          h.handle(type, obj, event)
    _.throttle handler, 1000
  _makePanes: (spec, indices, formatter) ->
    # make panes
    panes = {}
    for identifier, mindex of indices
      panes[identifier] = poly.pane.make spec, mindex, formatter
    panes
  _makeScaleSet: (spec, domains, facet) ->
    @coord.make poly.dim.guess(spec, facet.getGrid())
    tmpRanges = @coord.ranges()
    poly.scaleset tmpRanges, @coord
  _makeDimensions: (spec, scaleSet, facet) ->
    scaleSet.makeAxes(_.keys(@panes))
    scaleSet.makeTitles(@spec.title ? '')
    scaleSet.makeLegends()
    poly.dim.make spec, scaleSet, facet.getGrid()
  _makePaper: (dom, width, height, handleEvent) ->
    if _.isString dom then dom = document.getElementById(dom)
    paper = poly.paper dom, width, height, handleEvent

poly.chart = (spec) -> new Graph(spec)
