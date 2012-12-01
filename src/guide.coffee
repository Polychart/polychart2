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
    @oldticks = null
    @rendered = false
    @ticks = {}
    @pts = {}
  make: (params) =>
    {@domain, @factory, @guideSpec} = params
    @oldticks = @ticks
    @ticks = poly.tick.make @domain, @guideSpec, @factory.tickType(@domain)
  render: (dim, renderer) =>
    axisDim =
      top: dim.paddingTop + dim.guideTop
      left : dim.paddingLeft + dim.guideLeft
      bottom : dim.paddingTop + dim.guideTop + dim.chartHeight
      width: dim.chartWidth
      height: dim.chartHeight
    if !@rendered then @_renderline renderer, axisDim

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
    obj.text = renderer.add @_makeText(axisDim, tick)
    obj
  _delete: (renderer, pt) ->
    renderer.remove pt.tick
    renderer.remove pt.text
  _modify: (renderer, pt, tick, axisDim) ->
    obj = []
    obj.tick = renderer.animate pt.tick, @_makeTick(axisDim, tick)
    obj.text = renderer.animate pt.text, @_makeText(axisDim, tick)
    obj
  _renderline : () -> throw new poly.NotImplemented()
  _makeTick : () -> throw new poly.NotImplemented()
  _makeText: () -> throw new poly.NotImplemented()

class XAxis extends Axis
  _renderline : (renderer, axisDim) =>
    y = sf.identity axisDim.bottom
    x1 = sf.identity axisDim.left
    x2 = sf.identity axisDim.left+axisDim.width
    renderer.add { type: 'line', y: [y, y], x: [x1, x2]}
  _makeTick: (axisDim, tick) ->
    type: 'line'
    x : [tick.location, tick.location]
    y : [sf.identity(axisDim.bottom), sf.identity(axisDim.bottom+5)]
  _makeText: (axisDim, tick) ->
    type: 'text'
    x : tick.location
    y : sf.identity(axisDim.bottom+15)
    text: tick.value
    'text-anchor' : 'middle'
class YAxis extends Axis
  _renderline : (renderer, axisDim) =>
    x = sf.identity axisDim.left
    y1 = sf.identity axisDim.top
    y2 = sf.identity axisDim.top+axisDim.height
    renderer.add { type: 'line', x: [x, x], y: [y1, y2] }
  _makeTick: (axisDim, tick) ->
    type: 'line'
    x : [sf.identity(axisDim.left), sf.identity(axisDim.left-5)]
    y : [tick.location, tick.location]
  _makeText: (axisDim, tick) ->
    type: 'text'
    x : sf.identity(axisDim.left-7)
    y : tick.location
    text: tick.value
    'text-anchor' : 'end'


class Legend
  render: (paper, render, scales) ->

poly.guide = {}
poly.guide.axis = (type) ->
  if type == 'x'
    return new XAxis()
  return new YAxis()

@poly = poly
