poly = @poly || {}

###
# GLOBALS
###
poly.dim = {}
poly.dim.make = (spec, ticks) ->
  return {
    width: 320
    height: 320
    chartWidth: 300
    chartHeight: 300
    paddingLeft: 10
    paddingRight: 10
    paddingTop: 10
    paddingBottom: 10
    guideLeft: 10
    guideRight: 10
    guideTop: 10
    guideBottom: 10
  }

poly.dim.guess = (spec) ->
  return {
    width: 320
    height: 320
    chartWidth: 300
    chartHeight: 300
    paddingLeft: 10
    paddingRight: 10
    paddingTop: 10
    paddingBottom: 10
    guideLeft: 10
    guideRight: 10
    guideTop: 10
    guideBottom: 10
  }

poly.dim.clipping = (dim) ->
  x = dim.paddingLeft + dim.guideLeft
  y = dim.paddingTop + dim.guideTop
  w = dim.width
  h = dim.height
  return [x, y, w, h]

poly.dim.ranges = (dim) ->
  x:
    min: dim.paddingLeft + dim.guideLeft
    max: dim.paddingLeft + dim.guideLeft + dim.chartWidth
  y:
    min: dim.paddingTop + dim.guideTop + dim.chartHeight
    max: dim.paddingTop + dim.guideTop

###
# CLASSES
###

###
# EXPORT
###
@poly = poly
