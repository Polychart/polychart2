poly = @poly || {}

###
# GLOBALS
###
poly.dim = {}
poly.dim.make = (spec, ticks) ->
  return {
    width: 400
    height: 400
    chartWidth: 300
    chartHeight: 300
    paddingLeft: 10
    paddingRight: 10
    paddingTop: 10
    paddingBottom: 10
    guideLeft: 30
    guideRight: 40
    guideTop: 10
    guideBottom: 30
  }

poly.dim.guess = (spec) ->
  return {
    width: 400
    height: 400
    chartWidth: 300
    chartHeight: 300
    paddingLeft: 10
    paddingRight: 10
    paddingTop: 10
    paddingBottom: 10
    guideLeft: 30
    guideRight: 40
    guideTop: 10
    guideBottom: 30
  }

poly.dim.clipping = (dim) ->
  pl = dim.paddingLeft
  gl = dim.guideLeft
  pt = dim.paddingTop
  gt = dim.guideTop
  gb = dim.guideBottom
  w = dim.chartWidth
  h = dim.chartHeight

  main: [pl+gl, pt+gt, w, h]
  #left: [pl, pt, gl+1, gt+h+gb+1]
  #bottom: [pl, pt+gt+h-1, gl+w+1, gb+1]

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
