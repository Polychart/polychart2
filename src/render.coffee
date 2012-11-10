poly = @poly || {}

###
# GLOBALS
###
poly.paper = (dom, w, h) -> Raphael(dom, w, h)

###
Helper function for rendering all the geoms of an object
###
poly.render = (geoms, paper, scales, clipping) ->
  render = renderMark paper, scales, clipping
  _.each geoms, (geom) ->
    _.each geom.marks, (mark) ->
      render mark, geom.evtData

###
Rendering a single point
###
renderMark = (paper, scales, clipping) -> (mark, evtData) ->
  pt = null
  switch mark.type
    when 'point' then pt = renderPoint(paper, scales, mark)
  if pt
    pt.attr('clip-rect', clipping)
    pt.data('data', evtData)
  pt

renderPoint = (paper, scales, mark) ->
  pt = paper.circle()
  pt.attr('cx', scales.x(mark.x))
  pt.attr('cy', scales.y(mark.y))
  pt.attr('r', 10)
  pt.attr('fill', 'black')

