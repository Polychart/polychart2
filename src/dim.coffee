###
# GLOBALS
###
poly.dim = {}
poly.dim.make = (spec, scaleSet, facetGrid) ->
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
  {left, right, top, bottom}  = scaleSet.axesOffset(dim)
  dim.guideLeft += left ? 0
  dim.guideRight += right ? 0
  dim.guideBottom += bottom ? 0
  dim.guideTop += top ? 0

  # axes
  {left, right, top, bottom}  = scaleSet.titleOffset(dim)
  dim.guideLeft += left ? 0
  dim.guideRight += right ? 0
  dim.guideBottom += bottom ? 0
  dim.guideTop += top ? 0

  # legends
  {left, right, top, bottom}  = scaleSet.legendOffset(dim)
  dim.guideLeft += left ? 0
  dim.guideRight += right ? 0
  dim.guideBottom += bottom ? 0
  dim.guideTop += top ? 0

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
