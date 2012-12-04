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
  getXY: (mayflip, scales, mark) ->
    if mayflip
      point =
        x: if _.isArray(mark.x) then _.map mark.x, scales.x else scales.x mark.x
        y: if _.isArray(mark.y) then _.map mark.y, scales.y else scales.y mark.y
      return {
        x: point[@x]
        y: point[@y]
      }
    else
      scalex = scales[@x]
      scaley = scales[@y]
      return {
        x: if _.isArray(mark.x) then _.map mark.x, scalex else scalex mark.x
        y: if _.isArray(mark.y) then _.map mark.y, scaley else scaley mark.y
      }

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
