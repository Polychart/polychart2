###
# GLOBALS
###
poly.dim = {}
poly.dim.make = (spec, axes, legends, facetGrid) ->
  dim =
    width : spec.width ? 400
    height : spec.height ? 400
    paddingLeft : spec.paddingLeft ? 10
    paddingRight : spec.paddingRight ? 10
    paddingTop : spec.paddingTop ? 10
    paddingBottom : spec.paddingBottom ? 10
    horizontalSpacing : spec.horizontalSpacing ? 10
    verticalSpacing : spec.verticalSpacing ? 10
    guideTop : 10
    guideRight : 0
    guideLeft : 5
    guideBottom : 5

  # axes
  done = {}
  for key, axis of axes # loop over everything? pretty inefficient
    for k2, obj of axis
      if done[k2]? then continue
      d = obj.getDimension()
      if d.position == 'left'
        dim.guideLeft += d.width
      else if d.position == 'right'
        dim.guideRight += d.width
      else if d.position == 'bottom'
        dim.guideBottom+= d.height
      else if d.position == 'top'
        dim.guideTop += d.height
      done[k2] = true

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
  dim.guideRight += offset.x + maxwidth

  dim.chartHeight =
    dim.height-dim.paddingTop-dim.paddingBottom-dim.guideTop-dim.guideBottom
  dim.chartWidth=
    dim.width-dim.paddingLeft-dim.paddingRight-dim.guideLeft-dim.guideRight

  # Facet adjustment
  if facetGrid.cols? and facetGrid.cols > 1
    dim.chartWidth -= dim.horizontalSpacing * (facetGrid.cols - 1)
    dim.chartWidth /= facetGrid.cols
  if facetGrid.rows? and facetGrid.rows > 1
    dim.chartHeight -= dim.verticalSpacing * (facetGrid.rows - 1)
    dim.chartHeight /= facetGrid.rows

  dim

poly.dim.guess = (spec, facetGrid) ->
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
    horizontalSpacing : spec.horizontalSpacing ? 10
    verticalSpacing : spec.verticalSpacing ? 10

  dim.chartHeight =
    dim.height-dim.paddingTop-dim.paddingBottom-dim.guideTop-dim.guideBottom
  dim.chartWidth=
    dim.width-dim.paddingLeft-dim.paddingRight-dim.guideLeft-dim.guideRight

  # Facet adjustment
  if facetGrid.cols? and facetGrid.cols > 1
    dim.chartWidth -= dim.horizontalSpacing * (facetGrid.cols - 1)
  if facetGrid.rows? and facetGrid.rows > 1
    dim.chartHeight -= dim.verticalSpacing * (facetGrid.rows - 1)
  dim

###
# CLASSES
###
