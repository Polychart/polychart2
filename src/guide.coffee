poly = @poly || {}

sf = poly.const.scaleFns

class Guide
  constructor: (params) ->
    {@scales, @guideSpec} = params
    @position = 'right'
    @ticks = []
  getWidth: () ->  # approximate
  getHeight: () -> # approximate
  render: (paper, render, scales) ->
    throw new poly.NotImplemented("render is not implemented")

class Axis extends Guide
  constructor: (params) ->
    {@type} = params
    @position = if @type == 'x' then 'bottom' else 'left'
    @oldticks = null
    @rendered = false
    @ticks = {}
    @pts = {}
    @make params
  make: (params) =>
    {@domain, @factory, @scale, @guideSpec} = params
    @oldticks = @ticks
    @ticks = poly.tick.make @domain, @guideSpec, @factory.tickType(@domain)
  _renderline : (renderer, axisDim) =>
    if @type == 'x'
      y = sf.identity axisDim.bottom
      x1 = sf.identity axisDim.left
      x2 = sf.identity axisDim.left+axisDim.width
      renderer.add { type: 'line', y: [y, y], x: [x1, x2]}
    else
      x = sf.identity axisDim.left
      y1 = sf.identity axisDim.top
      y2 = sf.identity axisDim.top+axisDim.height
      renderer.add { type: 'line', x: [x, x], y: [y1, y2] }
  render: (dim, renderer) =>
    axisDim =
      top: dim.paddingTop + dim.guideTop
      left : dim.paddingLeft + dim.guideLeft
      bottom : dim.paddingTop + dim.guideTop + dim.chartHeight
      width: dim.chartWidth
      height: dim.chartHeight
    if !@rendered then @_renderline renderer, axisDim

    {deleted, kept, added} = poly.compare _.keys(@pts), _.keys(@ticks)
    geomfn = @_tickToGeomFn axisDim
    textfn = @_tickToTextFn axisDim
    newpts = {}

    _.each kept, (t) =>
      newpts[t] = @_modify renderer, @pts[t], @ticks[t], geomfn, textfn
    _.each added, (t) => newpts[t] = @_add renderer, @ticks[t], geomfn, textfn
    _.each deleted, (t) => @_delete renderer, @pts[t]
    @pts = newpts
    @rendered = true

  _tickToGeomFn: (axisDim) =>
    if @type == 'x'
      return (tick) ->
        type: 'line'
        x : [tick.location, tick.location]
        y : [sf.identity(axisDim.bottom), sf.identity(axisDim.bottom+5)]
    (tick) ->
      type: 'line'
      x : [sf.identity(axisDim.left), sf.identity(axisDim.left-5)]
      y : [tick.location, tick.location]

  _tickToTextFn: (axisDim) =>
    if @type == 'x'
      return (tick) ->
        type: 'text'
        x : tick.location
        y : sf.identity(axisDim.bottom+15)
        text: tick.value
        'text-anchor' : 'middle'
    (tick) ->
      type: 'text'
      x : sf.identity(axisDim.left-7)
      y : tick.location
      text: tick.value
      'text-anchor' : 'end'

  _add: (renderer, tick, geomfn, textfn) ->
    obj = {}
    obj.tick = renderer.add geomfn(tick)
    obj.text = renderer.add textfn(tick)
    obj
  _delete: (renderer, pt) ->
    renderer.remove pt.tick
    renderer.remove pt.text
  _modify: (renderer, pt, tick, geomfn, textfn) ->
    obj = []
    obj.tick = renderer.animate pt.tick, geomfn(tick)
    obj.text = renderer.animate pt.text, textfn(tick)
    obj


class Legend
  render: (paper, render, scales) ->

poly.guide = {}
poly.guide.axis = (params) -> new Axis(params)

@poly = poly
