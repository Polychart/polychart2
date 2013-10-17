###
Interaction
-----------
The functions here makes it easier to create common types of interactions.
###

poly.handler = {}

###
Render a tooltip. This is actually included automatically for every graph.
###
poly.handler.tooltip = () ->
  tooltip = {}
  offset = null
  paper = null

  _boxPadding = 10
  _boxMargin = 20
  _boxRadius = 10
  
  maxHeight = null
  maxWidth = null
  minWidth = null

  _update = (e) ->
    mousePos = poly.getXY offset, e
    if tooltip.text?
      _positionTooltip tooltip, mousePos

  _positionTooltip = (tooltip, mousePos) ->
    [mx, my] = [mousePos.x, mousePos.y]
    if tooltip.text?
      {height} = tooltip.text.getBBox()
      text =
        x: mx
        y: my - height/2 - _boxMargin
      tooltip.text.attr text
      {x, y, width, height} = tooltip.text.getBBox()
      box =
        x: x - _boxPadding/2
        y: y - _boxPadding/2
        width: width + _boxPadding
        height: height + _boxPadding
      if box.y < 0
        box.y = y + 3*_boxPadding + height
        text.y = my + height/2 + 3*_boxMargin/4
      if box.x + box.width > maxWidth
        delta = box.x + box.width - maxWidth
        box.x -= delta/2
        text.x -= delta/2
      if box.x < minWidth
        text.x += minWidth - box.x
        box.x = minWidth
      tooltip.text.attr text
      tooltip.box.attr box
      tooltip

  # Handler for tooltips
  (type, obj, event, graph) ->
    offset = poly.offset graph.dom
    paper = obj.paper
    maxHeight = graph.dims.chartHeight
    maxWidth = graph.dims.chartWidth + graph.dims.guideLeft + graph.dims.paddingLeft
    minWidth = graph.dims.guideLeft + graph.dims.paddingLeft
    if type in ['mover', 'mout']
      if tooltip.text?
        tooltip.text.remove()
        tooltip.box.remove()
      tooltip = {}
      if type is 'mover' and obj.tooltip
        mousePos = poly.getXY offset, event
        # Get the bounding box of the object and mouse position
        {x, y, x2, y2} = obj.getBBox()
        [x1, y1] = [mousePos.x, mousePos.y]
        tooltip.text = paper.text(x1, y1, obj.tooltip(graph.scaleSet.scales)).attr
          'text-anchor':'middle'
          fill:'white'
        # now figure out where the tooltip text is and move it up enough to not
        # obstruct the object
        {x, y, width, height} = tooltip.text.getBBox()
        tooltip.text.attr { y: y1 - height/2 - _boxMargin }
        # bound the text with a rounded rectangle background
        {x, y, width, height} = tooltip.text.getBBox()
        tooltip.box = paper.rect x - _boxPadding/2,
                                 y - _boxPadding/2,
                                 width + _boxPadding,
                                 height + _boxPadding,
                                 _boxRadius
        tooltip.box.attr { fill: '#213' }
        tooltip.text.toFront()

        tooltip = _positionTooltip tooltip, mousePos
        # Add handler on to the object to move box/text on mousemove
        # TODO: Add handler to object so will monitor data changes
        obj.mousemove _update

###
Drilldown. Suitable for bar charts over categorical data, mostly.
This function does not handle the following:
  * drilldown for multiple aesthetics. does this even make sense?
  * breaks if an initial filter overlaps with one of the drilldown levels
###
poly.handler.drilldown = (aes, levels, initial_filter = {}) ->
  if not _.isArray(levels)
    throw poly.error.input("Parameter `levels` should be an array.")
  if aes not in poly.const.aes
    throw poly.error.input("Unknown aesthetic #{aes}.")

  current = 0
  filters = [initial_filter]
  (type, obj, event, graph) ->
    if type is 'reset' and current > 0
      spec = graph.spec
      filters.pop()
      newFilter = filters.unshift()
      # Do we want to preserve the drilldown sequence?
      #newFilter = filters[filters.length - 1]
      current--
      for layer in spec.layers
        layer.filter = newFilter
        layer[aes] = levels[current]
        layer.id = levels[current]
      graph.make graph.spec
    else if type is 'click' and current < levels.length-1
      data = obj.evtData
      spec = graph.spec
      newFilterValue = data[levels[current]]
      if not newFilterValue then return
      newFilter = {}
      newFilter[levels[current]] = newFilterValue
      current++
      newFilter = _.extend(_.clone(filters[filters.length - 1]), newFilter)
      for layer in spec.layers
        layer.filter = newFilter
        layer[aes] = levels[current]
        layer.id = levels[current]
      filters.push(newFilter)
      graph.make graph.spec

###
Zooming and Resetting. Whenever click and drag on range, set to that range.
  * Reset event, that is, restoring to previous values, when click blank spot
  * TODO: Add a friendly interface to restrict zooms
###
poly.handler.zoom = (init_spec, zoomOptions = {x: true, y: true}) ->
  if not init_spec?
    throw poly.error.input "Initial specification missing."
  initGuides =
    x: _.clone init_spec.guides?.x
    y: _.clone init_spec.guides?.y
  initHandlers = undefined
  aes = ['x', 'y']
  # Lambda wrap so that when zoomed, graph reset before other handlers
  _wrapHandlers = (h) -> (type, obj, event, graph) ->
    if type is 'reset'
      if _.isFunction(h) then h('resetZoom', obj, event, graph) else h.handle('resetZoom', obj, event, graph)
    else
      if _.isFunction(h) then h(type, obj, event, graph) else h.handle(type, obj, event, graph)
  (type, obj, event, graph) ->
    initHandlers ?= _.clone graph.handlers
    # Zoom enabled only for Cartesian coordinates
    if graph.coord.type is 'cartesian'
      if type is 'resetZoom'
        spec = graph.spec
        (spec.guides[v] = _.clone initGuides[v]) for v in aes
        graph.handlers = _.clone initHandlers
        graph.make graph.spec
      if type is 'select'
        data = obj.evtData
        guides = graph.spec.guides
        for layer in graph.spec.layers
          for v in aes when (zoomOptions[v] and layer[v]?)
            aesVar = layer[v].var
            if graph.axes.domains[v].type in ['num', 'date']
              if data[aesVar].le - data[aesVar].ge > poly.const.epsilon
                guides[v] ?= {min: null, max: null}
                [guides[v].min, guides[v].max] = [data[aesVar].ge, data[aesVar].le]
            if graph.axes.domains[v].type is 'cat'
              if data[aesVar].in.length isnt 0
                guides[v] ?= {levels: null}
                guides[v].levels = data[aesVar].in
          graph.handlers = _.map(graph.handlers, _wrapHandlers)
          graph.make graph.spec
