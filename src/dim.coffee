poly = @poly || {}

###
# GLOBALS
###
poly.dim = {}
poly.dim.make = (spec, axes, legends) ->
  dim =
    width : spec.width ? 400
    height : spec.height ? 400
    paddingLeft : spec.paddingLeft ? 10
    paddingRight : spec.paddingRight ? 10
    paddingTop : spec.paddingTop ? 10
    paddingBottom : spec.paddingBottom ? 10

    # assume axes positions & left and bottom
    guideLeft : axes.y.getDimension().width+5
    guideBottom : axes.x.getDimension().height+5
    guideTop : 10
    guideRight : 0

  # NOTE: if this is changed, change scale.coffee's legend render
  maxheight =  dim.height - dim.guideTop - dim.paddingTop
  maxwidth = 0
  offset = { x : 0, y : 0}
  for legend in legends
    d = legend.getDimension()
    if d.height + offset.y > maxheight
      offset.x += maxwidth + 5
      offset.y = 0
      maxwidth = 0
    if d.width > maxwidth
      maxwidth = d.width
    offset.y += d.height
  dim.guideRight = offset.x + maxwidth
  dim.chartHeight =
    dim.height-dim.paddingTop-dim.paddingBottom-dim.guideTop-dim.guideBottom
  dim.chartWidth=
    dim.width-dim.paddingLeft-dim.paddingRight-dim.guideLeft-dim.guideRight
  return dim

poly.dim.guess = (spec) ->
  return {
    width : spec.width ? 400
    height : spec.height ? 400
    paddingLeft : spec.paddingLeft ? 10
    paddingRight : spec.paddingRight ? 10
    paddingTop : spec.paddingTop ? 10
    paddingBottom : spec.paddingBottom ? 10
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

###
# CLASSES
###

###
# EXPORT
###
@poly = poly
