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
  # Local handler function to update on mousemove
  update = (tooltip) -> (e) ->
    mousePos = poly.getXY offset, e
    if tooltip.text.getBBox()
      {x, y, width, height} = tooltip.text.getBBox()
      tooltip.text.attr
        x: mousePos.x
        y: Math.max(0, mousePos.y - 5 - height)
      {x, y, width, height} = tooltip.text.getBBox()
      tooltip.box.attr
        x: Math.max(0, x - 5)
        y: Math.max(0, y - 5)
        width: width + 10
        height: height + 10
  # Main handler for tooltip
  (type, obj, event, graph) ->
    offset = poly.offset graph.dom
    paper = obj.paper
    if type is 'mover' or type is 'mout'
      if tooltip.text?
        tooltip.text.remove()
        tooltip.box.remove()
      tooltip = {}
      if type is 'mover' and obj.tooltip
        # Get the bounding box of the object and mouse position
        {x, y, x2, y2} = obj.getBBox()
        mousePos = poly.getXY offset, event
        x1 = mousePos.x
        y1 = mousePos.y
        tooltip.text = paper.text(x1, y1, obj.tooltip).attr
          'text-anchor':'middle'
          'fill':'white'
        # now figure out where the tooltip text is and move it up enough to not
        # obstruct the object
        {x, y, width, height} = tooltip.text.getBBox()
        y = y1-height - 10
        tooltip.text.attr 'y': y
        # bound the text with a rounded rectangle background
        {x, y, width, height} = tooltip.text.getBBox()
        tooltip.box = paper.rect(x-5, y-5, width+10, height+10, 5)
        tooltip.box.attr fill: '#213'
        # move the text to the front of the rectangle
        tooltip.text.toFront()
        
        # Add handler on to the object to move box/text on mousemove
        # TODO: Add handler to object so will monitor data changes
        obj.mousemove update(tooltip)
      else
        obj.unmousemove null
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
poly.handler.zoom = (init_spec, xZoom = true, yZoom = true) ->
  if not init_spec?
    throw poly.error.input "Initial specification missing."
  aes = if init_spec.coord?.flip? then {x: 'y', y: 'x'} else {x: 'x', y: 'y'}
  xGuides = _.clone init_spec.guides?[aes.x] ? undefined
  yGuides = _.clone init_spec.guides?[aes.y] ? undefined
  zoomed = false
  (type, obj, event, graph) ->
    data = obj.evtData
    console.log graph
    if graph.coord.type is 'cartesian'
      if type is 'reset' and zoomed
        spec = graph.spec
        zoomed = false
        if xGuides? and spec.guides?[aes.x]?
          spec.guides[aes.x] = _.clone xGuides
        else
          if spec.guides[aes.x]?.min? then delete spec.guides[aes.x].min
          if spec.guides[aes.x]?.max? then delete spec.guides[aes.x].max
        if yGuides? and spec.guides?[aes.y]?
          spec.guides[aes.y] = _.clone yGuides
        else
          if spec.guides[aes.y]?.min? then delete spec.guides[aes.y].min
          if spec.guides[aes.y]?.max? then delete spec.guides[aes.y].max
        graph.make graph.spec
      if type is 'select'
        spec = graph.spec
        zoomed = true
        for layer in spec.layers
          xVar = if xZoom then layer[aes.x]?.var else undefined
          yVar = if yZoom then layer[aes.y]?.var else undefined
          if data[xVar]?.ge and data[xVar]?.le and (data[xVar].le - data[xVar].ge) > poly.const.epsilon
            spec.guides[aes.x] ?= {min: data[xVar].ge, max: data[xVar].le}
            spec.guides[aes.x].min = data[xVar].ge
            spec.guides[aes.x].max = data[xVar].le
          if data[yVar]?.ge and data[yVar]?.le and (data[yVar].le - data[yVar].ge) > poly.const.epsilon
            spec.guides[aes.y] ?= {min: data[yVar].ge, max: data[yVar].le}
            spec.guides[aes.y].min = data[yVar].ge
            spec.guides[aes.y].max = data[yVar].le
          graph.make spec
