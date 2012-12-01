poly = @poly || {}

sf = poly.const.scaleFns

class Guide
  constructor: () ->
  getWidth: () ->  # approximate
  getHeight: () -> # approximate
  render: (paper, render, scales) ->
    throw new poly.NotImplemented("render is not implemented")

class Axis extends Guide
  constructor: () ->
    @line = null
    @title = null
    @ticks = {}
    @pts = {}
  make: (params) =>
    {domain, type, guideSpec, @titletext} = params
    @ticks = poly.tick.make domain, guideSpec, type
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
    _.each kept, (t) =>
      newpts[t] = @_modify renderer, @pts[t], @ticks[t], axisDim
    _.each added, (t) => newpts[t] = @_add renderer, @ticks[t], axisDim
    _.each deleted, (t) => @_delete renderer, @pts[t]
    @pts = newpts
    @rendered = true
  _add: (renderer, tick, axisDim) ->
    obj = {}
    obj.tick = renderer.add @_makeTick(axisDim, tick)
    obj.text = renderer.add @_makeLabel(axisDim, tick)
    obj
  _delete: (renderer, pt) ->
    renderer.remove pt.tick
    renderer.remove pt.text
  _modify: (renderer, pt, tick, axisDim) ->
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
class YAxis extends Axis # assumes position = left
  _renderline : (renderer, axisDim) ->
    x = sf.identity axisDim.left
    y1 = sf.identity axisDim.top
    y2 = sf.identity axisDim.top+axisDim.height
    renderer.add { type: 'line', x: [x, x], y: [y1, y2] }
  _makeTitle: (axisDim, text) ->
    type: 'text'
    x : sf.identity axisDim.left - 22
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

class Legend
  constructor: () ->
    @rendered = false
    @ticks = {}
    @pts = {}
  make : (params) ->
  render: (paper, render, scales) ->
  _makeLabel: (tick) ->
  _makeBox: (tick) ->

poly.guide = {}
poly.guide.axis = (type) ->
  #TODO: handle polar coordinates here
  if type == 'x'
    return new XAxis()
  return new YAxis()

@poly = poly
