poly = @poly || {}


class Guide
  constructor: (params) ->
    {@scales, @guideSpec} = params
    @position = 'left'
    @ticks = []
  getWidth: () ->  # approximate
  getHeight: () -> # approximate
  render: (paper, render, scales) -> throw new poly.NotImplemented("render is not implemented")

class Axis
  constructor: (params) ->
    {@domain, @factory, @scale, @guideSpec} = params
    @position = 'left'
    @ticks = poly.tick.make @domain, @scale, @guideSpec, @factory.tickType(@domain)
  render: (paper, render, scales) ->

class Legend
  render: (paper, render, scales) ->

poly.guide = {}
poly.guide.axis = (params) -> new Axis(params)

@poly = poly
