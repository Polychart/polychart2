poly = @poly || {}

class Coordinate
  constructor: (params) ->
    params ?= {}
    @flip = params.flip ? false
    [@x, @y] = if @flip then ['y', 'x'] else ['x', 'y']
  make: (dims) -> @dims = dims
  ranges: () ->

class Cartesian extends Coordinate
  ranges: () ->
    ranges = {}
    ranges[@x] =
      min: @dims.paddingLeft + @dims.guideLeft
      max: @dims.paddingLeft + @dims.guideLeft + @dims.chartWidth
    ranges[@y] =
      min: @dims.paddingTop + @dims.guideTop + @dims.chartHeight
      max: @dims.paddingTop + @dims.guideTop
    ranges
  axisType: (aes) -> @[aes]
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
  make: (dims) ->
    @dims = dims
    @cx = @dims.paddingLeft + @dims.guideLeft + @dims.chartWidth/2
    @cy = @dims.paddingTop + @dims.guideTop + @dims.chartHeight/2
  ranges: () ->
    [r, t] = [@x, @y]
    ranges = {}
    ranges[t] = min: 0, max: 2*Math.PI
    ranges[r] =
      min: 0
      max: Math.min(@dims.chartWidth,@dims.chartHeight)/2-10
    ranges
  axisType: (aes) -> if @[aes] == 'x' then 'r' else 't'
  getXY: (mayflip, scales, mark) ->
    _getx = (radius, theta) => @cx + radius * Math.cos(theta - Math.PI/2)
    _gety = (radius, theta) => @cy + radius * Math.sin(theta - Math.PI/2)
    [r, t] = [@x, @y]
    if mayflip
      if _.isArray mark[r] #and _.isArray mark[t]
        points = x: [], y: []
        for radius, i in mark[r]
          radius = scales[r] radius
          theta = scales[t] mark[t][i]
          points.x.push _getx radius, theta
          points.y.push _gety radius, theta
        return points
      radius = scales[r](mark[r])
      theta = scales[t](mark[t])
      return {
        x: _getx radius, theta
        y: _gety radius, theta
      }
    # else if not mayflip
    ident = (obj) -> _.isObject(obj) and obj.t is 'scalefn' and obj.f is 'identity'
    getpos = (x,y) ->
      identx = ident(x)
      identy = ident(y)
      if identx and not identy # here, y is going to be radius.
        x: x.v
        y: _gety(scales[r](y), 0)
      else if identx and identy
        x: x.v
        y: y.v
      else if not identx and identy
        y: y.v
        x: _gety(scales[t](x), 0)
      else
        radius = scales[r] y
        theta = scales[t] x
        x: _getx radius, theta
        y: _gety radius, theta
    if _.isArray mark.x
      points = x:[], y: []
      for xpos,i in mark.x
        ypos = mark.y[i]
        {x,y} = getpos(xpos,ypos)
        points.x.push x
        points.y.push y
      return points
    return getpos(mark.x, mark.y)

poly.coord =
  cartesian : (params) -> new Cartesian(params)
  polar : (params) -> new Polar(params)
