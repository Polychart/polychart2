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
    {@domain, @factory, @scale, @guideSpec, @type} = params
    @position = if @type == 'x' then 'bottom' else 'left'
    @ticks = poly.tick.make @domain, @scale, @guideSpec, @factory.tickType(@domain)
  _renderHline : (dim, renderer) ->
    hline =
      type: 'hline'
      y: sf.identity dim.paddingTop+dim.guideTop+dim.chartHeight+1
    renderer.add hline, {}
  _renderVline : (dim, renderer) ->
    vline =
      type: 'vline'
      x: sf.identity dim.paddingLeft+dim.guideLeft-1
    renderer.add vline, {}
  render: (dim, renderer) ->
    if @type == 'x' then @_renderHline dim, renderer
    if @type == 'y' then @_renderVline dim, renderer
    # add a line
    _.each @ticks, (t) ->
      #renderer.add(MARK, evtDATA)

class Legend
  render: (paper, render, scales) ->

poly.guide = {}
poly.guide.axis = (params) -> new Axis(params)

@poly = poly
