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
  (type, obj, event) ->
    if type is 'mover' or type is 'mout'
      if tooltip.text?
        tooltip.text.remove()
        tooltip.box.remove()
      tooltip = {}
      if type is 'mover' and obj.tooltip
        paper = obj.paper
        # first get the bounding box of the object
        {x, y, x2, y2} = obj.getBBox()
        # put the tooltip text at the top middle of object
        y1 = y
        x1 = x/2 + x2/2
        tooltip.text = paper.text(x1, y1, obj.tooltip).attr
          'text-anchor':'middle'
          'fill':'white'
        # now figure out where the tooltip text is and move it up enough to not
        # obstruct the object
        {x, y, width, height} =tooltip.text.getBBox()
        y = (y1-height) + 4
        tooltip.text.attr 'y': y
        # bound the text with a rounded rectangle background
        {x, y, width, height} =tooltip.text.getBBox()
        tooltip.box = paper.rect(x-5, y-5, width+10, height+10, 5)
        tooltip.box.attr fill: '#213'
        # move the text to the front of the rectangle
        tooltip.text.toFront()

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
###
poly.handler.zoom = (init_spec) ->
  if not init_spec?
    throw poly.error.input "Initial specification missing."
  xGuides = _.clone init_spec.guides?.x ? undefined
  yGuides = _.clone init_spec.guides?.y ? undefined
  zoomed = false
  (type, obj, event, graph) ->
    data = obj.evtData
    if graph.coord.type is 'cartesian'
      if type is 'reset' and zoomed
        spec = graph.spec
        zoomed = false
        if xGuides? and spec.guides?.x?
          spec.guides.x = _.clone xGuides
        else
          if spec.guides.x?.min? then delete spec.guides.x.min
          if spec.guides.x?.max? then delete spec.guides.x.max
        if yGuides? and spec.guides?.y?
          spec.guides.y = _.clone yGuides
        else
          if spec.guides.y?.min? then delete spec.guides.y.min
          if spec.guides.y?.max? then delete spec.guides.y.max
        graph.make graph.spec
      if type is 'select'
        spec = graph.spec
        zoomed = true
        for layer in spec.layers
          xVar = layer.x?.var
          yVar = layer.y?.var
          if spec.coord.type is 'polar' then xVar = null
          if data[xVar]?.ge and data[xVar]?.le and (data[xVar].le - data[xVar].ge) > poly.const.epsilon
            spec.guides.x ?= {min: data[xVar].ge, max: data[xVar].le}
            spec.guides.x.min = data[xVar].ge
            spec.guides.x.max = data[xVar].le
          if data[yVar]?.ge and data[yVar]?.le and (data[yVar].le - data[yVar].ge) > poly.const.epsilon
            spec.guides.y ?= {min: data[yVar].ge, max: data[yVar].le}
            spec.guides.y.min = data[yVar].ge
            spec.guides.y.max = data[yVar].le
          graph.make spec
