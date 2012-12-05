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

  dim.guideTop = 10
  dim.guideRight = 0
  dim.guideLeft = 5
  dim.guideBottom = 5

  # axes
  for key, obj of axes
    d = obj.getDimension()
    if d.position == 'left'
      dim.guideLeft += d.width
    else if d.position == 'right'
      dim.guideRight += d.width
    else if d.position == 'bottom'
      dim.guideBottom+= d.height
    else if d.position == 'top'
      dim.guideTop += d.height

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
  dim

poly.dim.guess = (spec) ->
  dim =
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
  dim.chartHeight =
    dim.height-dim.paddingTop-dim.paddingBottom-dim.guideTop-dim.guideBottom
  dim.chartWidth=
    dim.width-dim.paddingLeft-dim.paddingRight-dim.guideLeft-dim.guideRight
  dim

###
# CLASSES
###

###
# EXPORT
###
@poly = poly
