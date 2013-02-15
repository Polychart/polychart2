###
DIMENSIONS
----------
Calculate the pixel dimension and layout of a particular chart

Dimension object has the following elements (all numeric in pixels):
  @width: the width of the entire chart, including paddings, guides, etc.
  @height : the height of the entire chart, including paddings, guides, etc.
  @paddingLeft: left padding, not including guides
  @paddingRight: right padding, not including guides
  @paddingTop: top padding, not including guides
  @paddingBottom: bottom padding, not including guides
  @guideLeft: space for guides (axes & legends) on the left side of chart
  @guideRight: space for guides (axes & legends) on the right side of chart
  @guideTop: space for guides (axes & legends) on the top of chart
  @guideBottom: space for guides (axes & legends) on the bottom of chart
  @chartHeight: height of area given for actual chart, includes all facets and
                the spaces between the facets
  @chartWidth: width of area given for actual chart, includes all facets and
               the spaces between the facets
  @eachHeight: the height of the chart area for each facet
  @eachWidth: the width of the chart area for each facet
  @horizontalSpacing: horizontal space between ajacent facets
  @verticalSpacing: horizontal space between ajacent facets
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
    verticalSpacing : spec.verticalSpacing ? 20
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
    dim.eachWidth = dim.chartWidth - dim.horizontalSpacing * (facetGrid.cols)
    dim.eachWidth /= facetGrid.cols
  else
    dim.eachWidth = dim.chartWidth
  if facetGrid.rows? and facetGrid.rows > 1
    dim.eachHeight = dim.chartHeight - dim.verticalSpacing * (facetGrid.rows + 1)
    dim.eachHeight /= facetGrid.rows
  else
    dim.eachHeight = dim.chartHeight - dim.verticalSpacing
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
    dim.eachWidth = dim.chartWidth - dim.horizontalSpacing * (facetGrid.cols - 1)
  else
    dim.eachWidth = dim.chartWidth
  if facetGrid.rows? and facetGrid.rows > 1
    dim.eachHeight = dim.chartHeight - dim.verticalSpacing * (facetGrid.rows - 1)
  else
    dim.eachHeight = dim.chartHeight
  dim
