poly = @poly || {}

sf = poly.const.scaleFns

class Guide
  constructor: () ->
  getDimension: () -> throw new poly.NotImplemented()

class Axis extends Guide
  constructor: () ->
    @line = null
    @title = null
    @ticks = {}
    @pts = {}
  make: (params) =>
    {domain, type, guideSpec, @titletext} = params
    @ticks = poly.tick.make domain, guideSpec, type
    @maxwidth =_.max _.map @ticks, (t) -> poly.strSize t.value
  render: (dim, renderer) =>
    axisDim =
      top: dim.paddingTop + dim.guideTop
      left : dim.paddingLeft + dim.guideLeft
      bottom : dim.paddingTop + dim.guideTop + dim.chartHeight
      width: dim.chartWidth
      height: dim.chartHeight
    @line ?= @_renderline renderer, axisDim
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
    obj.tick = renderer.add @_makeTick(axisDim, tick)
    obj.text = renderer.add @_makeLabel(axisDim, tick)
    obj
  _delete: (renderer, pt) ->
    renderer.remove pt.tick
    renderer.remove pt.text
  _modify: (renderer, pt, tick, axisDim) =>
    obj = []
    obj.tick = renderer.animate pt.tick, @_makeTick(axisDim, tick)
    obj.text = renderer.animate pt.text, @_makeLabel(axisDim, tick)
    obj
  _renderline : () -> throw new poly.NotImplemented()
  _makeTitle: () -> throw new poly.NotImplemented()
  _makeTick : () -> throw new poly.NotImplemented()
  _makeLabel: () -> throw new poly.NotImplemented()

class XAxis extends Axis # assumes position = bottom
  _renderline : (renderer, axisDim) ->
    y = sf.identity axisDim.bottom
    x1 = sf.identity axisDim.left
    x2 = sf.identity axisDim.left+axisDim.width
    renderer.add { type: 'line', y: [y, y], x: [x1, x2]}
  _makeTitle: (axisDim, text) ->
    type: 'text'
    x : sf.identity axisDim.left+axisDim.width/2
    y : sf.identity axisDim.bottom + 27
    text: text
    'text-anchor' : 'middle'
  _makeTick: (axisDim, tick) ->
    type: 'line'
    x : [tick.location, tick.location]
    y : [sf.identity(axisDim.bottom), sf.identity(axisDim.bottom+5)]
  _makeLabel: (axisDim, tick) ->
    type: 'text'
    x : tick.location
    y : sf.identity(axisDim.bottom+15)
    text: tick.value
    'text-anchor' : 'middle'
  getDimension: () ->
    position: 'bottom'
    height: 30
    width: 'all'

class YAxis extends Axis # assumes position = left
  _renderline : (renderer, axisDim) ->
    x = sf.identity axisDim.left
    y1 = sf.identity axisDim.top
    y2 = sf.identity axisDim.top+axisDim.height
    renderer.add { type: 'line', x: [x, x], y: [y1, y2] }
  _makeTitle: (axisDim, text) ->
    type: 'text'
    x : sf.identity axisDim.left - @maxwidth - 15
    y : sf.identity axisDim.top+axisDim.height/2
    text: text
    transform : 'r270'
    'text-anchor' : 'middle'
  _makeTick: (axisDim, tick) ->
    type: 'line'
    x : [sf.identity(axisDim.left), sf.identity(axisDim.left-5)]
    y : [tick.location, tick.location]
  _makeLabel: (axisDim, tick) ->
    type: 'text'
    x : sf.identity(axisDim.left-7)
    y : tick.location
    text: tick.value
    'text-anchor' : 'end'
  getDimension: () ->
    position: 'left'
    height: 'all'
    width: 20+@maxwidth

class RAxis extends Axis # assumes position = left
  _renderline : (renderer, axisDim) ->
  _makeTitle: (axisDim, text) -> {}
  _makeTick: (axisDim, tick) -> {}
  _makeLabel: (axisDim, tick) -> {}
  getDimension: () -> {}

class TAxis extends Axis # assumes position = ... um, what is it supposed to be?
  _renderline : (renderer, axisDim) ->
  _makeTitle: (axisDim, text) -> {}
  _makeTick: (axisDim, tick) -> {}
  _makeLabel: (axisDim, tick) -> {}
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
    {domain, type, guideSpec, @mapping, @titletext} = params
    @ticks = poly.tick.make domain, guideSpec, type
    @height = @TITLEHEIGHT + @SPACING + @TICKHEIGHT*_.size @ticks
    @maxwidth = _.max _.map @ticks, (t) -> poly.strSize t.value
  render: (dim, renderer, offset) -> # assume position = RIGHT
    legendDim =
      top: dim.paddingTop + dim.guideTop + offset.y
      right : dim.paddingLeft + dim.guideLeft + dim.chartWidth + offset.x
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
  #TODO: handle polar coordinates here
  if type == 'x'
    new XAxis()
  else if type == 'y'
    new YAxis()
  else if type == 'r'
    new XAxis()
  else if type == 't'
    new YAxis()
poly.guide.legend = (aes) -> return new Legend(aes)

@poly = poly
