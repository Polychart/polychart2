poly = @poly || {}

class Coordinate
  constructor: (params) ->
    params ?= {}
    @flip = params.flip ? false
    [@x, @y] = if @flip then ['y', 'x'] else ['x', 'y']
  ranges: (dim) ->

class Cartesian extends Coordinate
  ranges: (dim) ->
    ranges = {}
    ranges[@x] =
      min: dim.paddingLeft + dim.guideLeft
      max: dim.paddingLeft + dim.guideLeft + dim.chartWidth
    ranges[@y] =
      min: dim.paddingTop + dim.guideTop + dim.chartHeight
      max: dim.paddingTop + dim.guideTop
    ranges

class Polar extends Coordinate
  ranges: (dim) ->
    [r, t] = [@x, @y]
    ranges = {}
    ranges[t] = min: 0, max: 2*Math.PI
    ranges[r] =
      min: 0
      max: Math.min(dim.chartWidth,dim.chartHeight)/2
    ranges

poly.coord =
  cartesian : (params) -> new Cartesian(params)
  polar : (params) -> new Polar(params)
