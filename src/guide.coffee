sf = poly.const.scaleFns

class Guide
  constructor: () ->
  getDimension: () -> throw poly.error.impl()

class Axis extends Guide
  constructor: () ->
    @line = null
    @title = null
    @position = 'none'
    @titletext = null
    @ticks = {}
    @pts = {}
  make: (params) =>
    {domain, type, guideSpec, key} = params
    # options
    @titletext = guideSpec.title ? key
    @renderTick = guideSpec.renderTick ? true
    @renderGrid = guideSpec.renderGrid ? true
    @renderLabel = guideSpec.renderLabel ? true
    @renderLine = guideSpec.renderLine ? true
    # ticks
    @ticks = poly.tick.make domain, guideSpec, type
    @maxwidth =_.max _.map @ticks, (t) -> poly.strSize t.value
  render: (axisDim, coord, renderer) =>
    # NOTE: coords are included for making guide rendering for polar coordinates
    # managable. Ideally it should NOT be here and is rather a hack.
    @coord = coord
    axisDim.centerx = axisDim.left + axisDim.width/2
    axisDim.centery = axisDim.top + axisDim.height/2
    axisDim.radius = Math.min(axisDim.width, axisDim.height)/2 -10
    if @renderLine
      if @line? then renderer.remove @line
      @line = @_renderline renderer, axisDim

    if @title?
      @title = renderer.animate @title, @_makeTitle(axisDim, @titletext)
    else
      @title = renderer.add @_makeTitle(axisDim, @titletext)

    {deleted, kept, added} = poly.compare _.keys(@pts), _.keys(@ticks)
    newpts = {}
    for t in kept
      newpts[t] = @_modify renderer, @pts[t], @ticks[t], axisDim
    for t in added
      newpts[t] = @_add renderer, @ticks[t], axisDim
    for t in deleted
      @_delete renderer, @pts[t]
    @pts = newpts
    @rendered = true
  _add: (renderer, tick, axisDim) =>
    obj = {}
    if @renderTick
      obj.tick = renderer.add @_makeTick(axisDim, tick)
    if @renderLabel
      obj.text = renderer.add @_makeLabel(axisDim, tick)
    if @renderGrid
      obj.grid = renderer.add @_makeGrid(axisDim, tick)
      obj.grid.toBack()
    obj
  _delete: (renderer, pt) ->
    if @renderTick
      renderer.remove pt.tick
    if @renderLabel
      renderer.remove pt.text
    if @renderGrid
      renderer.remove pt.grid
  _modify: (renderer, pt, tick, axisDim) =>
    obj = {}
    if @renderTick
      obj.tick = renderer.animate pt.tick, @_makeTick(axisDim, tick)
    if @renderLabel
      obj.text = renderer.animate pt.text, @_makeLabel(axisDim, tick)
    if @renderGrid
      obj.grid = renderer.animate pt.grid, @_makeGrid(axisDim, tick)
      obj.grid.toBack()
    obj
  _renderline : () -> throw poly.error.impl()
  _makeTitle: () -> throw poly.error.impl()
  _makeTick : (obj) ->
    if !obj then throw poly.error.impl()
    obj.type = 'path'
    obj.stroke = sf.identity 'black'
    obj
  _makeLabel: (obj) ->
    if !obj then throw poly.error.impl()
    obj.type = 'text'
    obj
  _makeGrid: (obj) ->
    if !obj then throw poly.error.impl()
    obj.stroke = '#CCC'
    obj['stroke-dasharray'] = '- '
    obj['stroke-dashoffset'] = 3
    obj

class XAxis extends Axis # assumes position = bottom
  make: (params) =>
    {guideSpec} = params
    @position = guideSpec.position ? 'bottom'
    if @position not in ['top', 'bottom', 'none']
      throw poly.error.defn "X-axis position can't be #{@position}."
    super(params)
  _renderline : (renderer, axisDim) ->
    if @position is 'top'
      y = sf.identity axisDim.top
    else
      y = sf.identity axisDim.bottom
    x1 = sf.identity axisDim.left
    x2 = sf.identity axisDim.left+axisDim.width
    renderer.add
      type: 'path'
      y: [y, y]
      x: [x1, x2]
      stroke: sf.identity 'black'
  _makeTitle: (axisDim, text) ->
    if @position is 'top'
      y = sf.identity axisDim.top - 27
    else
      y = sf.identity axisDim.bottom + 27
    type: 'text'
    x : sf.identity axisDim.left+axisDim.width/2
    y : y
    text: text
    'text-anchor' : 'middle'
  _makeTick: (axisDim, tick) ->
    if @position is 'top'
      y1 = sf.identity(axisDim.top)
      y2 = sf.identity(axisDim.top-5)
    else
      y1 = sf.identity(axisDim.bottom)
      y2 = sf.identity(axisDim.bottom+5)
    super
      x : [tick.location, tick.location]
      y : [y1, y2]
  _makeLabel: (axisDim, tick) ->
    if @position is 'top'
      y = sf.identity(axisDim.top-15)
    else
      y = sf.identity(axisDim.bottom+15)
    super
      x : tick.location
      y : y
      text: tick.value
      'text-anchor' : 'middle'
  _makeGrid: (axisDim, tick) ->
    y1 = sf.identity(axisDim.top)
    y2 = sf.identity(axisDim.bottom)
    super
      type: 'path'
      x : [tick.location, tick.location]
      y : [y1, y2]
  getDimension: () ->
    position: @position ? 'bottom'
    height: 30
    width: 'all'

class YAxis extends Axis # assumes position = left
  make: (params) =>
    {guideSpec} = params
    @position = guideSpec.position ? 'left'
    if @position not in ['left', 'right', 'none']
      throw poly.error.defn "X-axis position can't be #{@position}."
    super(params)
  _renderline : (renderer, axisDim) ->
    if @position is 'left'
      x = sf.identity axisDim.left
    else
      x = sf.identity axisDim.right
    y1 = sf.identity axisDim.top
    y2 = sf.identity axisDim.top+axisDim.height
    renderer.add
      type: 'path'
      x: [x, x]
      y: [y1, y2]
      stroke: sf.identity 'black'
  _makeTitle: (axisDim, text) ->
    if @position is 'left'
      x = sf.identity axisDim.left - @maxwidth - 15
    else
      x = sf.identity axisDim.right + @maxwidth + 15
    type: 'text'
    x : x
    y : sf.identity axisDim.top+axisDim.height/2
    text: text
    transform : 'r270'
    'text-anchor' : 'middle'
  _makeTick: (axisDim, tick) ->
    if @position is 'left'
      x1 = sf.identity(axisDim.left)
      x2 = sf.identity(axisDim.left-5)
    else
      x1 = sf.identity(axisDim.right)
      x2 = sf.identity(axisDim.right+5)
    super
      x : [x1, x2]
      y : [tick.location, tick.location]
  _makeLabel: (axisDim, tick) ->
    if @position is 'left'
      x = sf.identity(axisDim.left-7)
    else
      x = sf.identity(axisDim.right+7)
    super
      x : x
      y : tick.location
      text: tick.value
      'text-anchor' : if @position is 'left' then 'end' else 'start'
  _makeGrid: (axisDim, tick) ->
    x1 = sf.identity(axisDim.left)
    x2 = sf.identity(axisDim.right)
    super
      type: 'path'
      y : [tick.location, tick.location]
      x : [x1, x2]
  getDimension: () ->
    position: @position ? 'right'
    height: 'all'
    width: 20+@maxwidth

class RAxis extends Axis # assumes position = left
  _renderline : (renderer, axisDim) ->
    x = sf.identity axisDim.left
    y1 = sf.identity axisDim.top
    y2 = sf.identity axisDim.top+axisDim.height/2
    renderer.add
      type: 'path'
      x: [x, x]
      y: [y1, y2]
      stroke: sf.identity 'black'
  _makeTitle: (axisDim, text) ->
    type: 'text'
    x : sf.identity axisDim.left-@maxwidth-15
    y : sf.identity axisDim.top+axisDim.height/4
    text: text
    transform : 'r270'
    'text-anchor' : 'middle'
  _makeTick: (axisDim, tick) ->
    super
      x : [sf.identity(axisDim.left), sf.identity(axisDim.left-5)]
      y : [tick.location, tick.location]
  _makeLabel: (axisDim, tick) ->
    super
      x : sf.identity(axisDim.left-7)
      y : tick.location
      text: tick.value
      'text-anchor' : 'end'
  _makeGrid: (axisDim, tick) ->
    super
      type: 'circle'
      x: sf.identity axisDim.centerx
      y: sf.identity axisDim.centery
      size: sf.identity @coord.getScale('r') tick.location
      fill: sf.identity('white')
      'stroke-width': 1
  getDimension: () ->
    position: 'left'
    height: 'all'
    width: 20+@maxwidth

class TAxis extends Axis # assumes position = ... um, what is it supposed to be?
  _renderline : (renderer, axisDim) ->
    renderer.add {
      type: 'circle',
      x: sf.identity axisDim.centerx
      y: sf.identity axisDim.centery
      size: sf.identity axisDim.radius
      color: sf.identity('none')
      stroke: sf.identity('black')
      'stroke-width': 1
    }
  _makeTitle: (axisDim, text) ->
    type: 'text'
    x : sf.identity axisDim.left+axisDim.width/2
    y : sf.identity axisDim.bottom + 27
    text: text
    'text-anchor' : 'middle'
  _makeTick: (axisDim, tick) ->
    super
      x : [tick.location, tick.location]
      y : [sf.max(0), sf.max(3)]
  _makeLabel: (axisDim, tick) ->
    super
      x : tick.location
      y : sf.max(12)
      text: tick.value
      'text-anchor' : 'middle'
  _makeGrid: (axisDim, tick) ->
    x1 = sf.identity axisDim.centerx
    y1 = sf.identity axisDim.centery
    theta = @coord.getScale('t')(tick.location) - Math.PI/2
    x2 = sf.identity(axisDim.centerx + axisDim.radius * Math.cos(theta))
    y2 = sf.identity(axisDim.centery + axisDim.radius * Math.sin(theta))
    super
      type: 'path'
      y : [y1, y2]
      x : [x1, x2]
  getDimension: () -> {}

class Legend extends Guide
  TITLEHEIGHT: 15
  TICKHEIGHT: 12
  SPACING: 10
  constructor: (@aes) ->
    @rendered = false
    @title = null
    @ticks = {}
    @pts = {}
  make: (params) =>
    {domain, type, guideSpec, @mapping, keys} = params
    @titletext = guideSpec.title ? keys
    @ticks = poly.tick.make domain, guideSpec, type
    @height = @TITLEHEIGHT + @SPACING + @TICKHEIGHT*_.size @ticks
    titleWidth = poly.strSize @titletext
    tickWidth = _.max _.map @ticks, (t) -> poly.strSize t.value
    @maxwidth = Math.max titleWidth, tickWidth
  render: (dim, renderer, offset) -> # assume position = RIGHT
    legendDim =
      top: dim.paddingTop + dim.guideTop + offset.y
      right: dim.width - dim.guideRight - dim.paddingRight + offset.x
      width: dim.guideRight
      height: dim.chartHeight
    if @title?
      @title = renderer.animate @title, @_makeTitle(legendDim, @titletext)
    else
      @title = renderer.add @_makeTitle(legendDim, @titletext)
    {deleted, kept, added} = poly.compare _.keys(@pts), _.keys(@ticks)
    newpts = {}
    for t in deleted
      @_delete renderer, @pts[t]
    for t in kept
      newpts[t] = @_modify renderer, @pts[t], @ticks[t], legendDim
    for t in added
      newpts[t] = @_add renderer, @ticks[t], legendDim
    @pts = newpts
  remove: (renderer) ->
    for i, pt of @pts
      @_delete renderer, pt
    renderer.remove @title
    @title = null
    @pts = {}
  _add: (renderer, tick, legendDim) ->
    obj = {}
    obj.tick = renderer.add @_makeTick(legendDim, tick)
    obj.text = renderer.add @_makeLabel(legendDim, tick)
    obj
  _delete: (renderer, pt) ->
    renderer.remove pt.tick
    renderer.remove pt.text
  _modify: (renderer, pt, tick, legendDim) ->
    obj = []
    obj.tick = renderer.animate pt.tick, @_makeTick(legendDim, tick)
    obj.text = renderer.animate pt.text, @_makeLabel(legendDim, tick)
    obj
  _makeLabel: (legendDim, tick) ->
    type: 'text'
    x : sf.identity legendDim.right + 15
    y : sf.identity legendDim.top + (15+tick.index*12) + 1
    text: tick.value
    'text-anchor' : 'start'
  _makeTick: (legendDim, tick) =>
    obj =
      type: 'circle'
      x : sf.identity legendDim.right + 7
      y : sf.identity legendDim.top + (15+tick.index*12)
      color: sf.identity 'steelblue' # can be overwritten
    for aes, value of @mapping
      if aes in poly.const.noLegend then continue
      value = value[0] # just use the first for now?
      if aes in @aes
        obj[aes] = tick.location
      else if value.type? and value.type == 'const'
        # take assigned const value of first layer
        obj[aes] = sf.identity value.value
      else if not _.isObject value
        # take the layer default value
        obj[aes] = sf.identity value
      else
        # take teh global default value
        obj[aes] = sf.identity poly.const.defaults[aes]
    if not ('size' in @aes) # override size so we can see!
      obj.size = sf.identity 5
    obj
  _makeTitle: (legendDim, text) ->
    type: 'text'
    x : sf.identity legendDim.right + 5
    y : sf.identity legendDim.top
    text: text
    'text-anchor' : 'start'
  getDimension: () ->
    position: 'right'
    height: @height
    width: 15+@maxwidth


poly.guide = {}
poly.guide.axis = (type) ->
  if type == 'x'
    new XAxis()
  else if type == 'y'
    new YAxis()
  else if type == 'r'
    new RAxis()
  else if type == 't'
    new TAxis()
poly.guide.legend = (aes) -> return new Legend(aes)
