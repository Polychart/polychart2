poly = @poly || {}


class Guide
  constructor: (params) ->
    {@scales, @guideSpec} = params
    @position = 'left'
    @ticks = []
  getWidth: () ->  # approximate
  getHeight: () -> # approximate
  render: (paper, render, scales) -> console.log 'wtf not impl'

class Axis
  render: (paper, render, scales) ->

class Legend
  render: (paper, render, scales) ->

poly.guide = {}
poly.guide.axis = (domain, factory, scale, guideSpec) ->
  poly.tick.make domain, scale, guideSpec, factory.tickType(domain)

@poly = poly
