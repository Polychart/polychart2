poly = @poly || {}

###
# GLOBALS
###
poly.paper = (dom, w, h) -> Raphael(dom, w, h)

###
Helper function for rendering all the geoms of an object
###
poly.render = (id, paper, scales, clipping) -> (mark, evtData) ->
  pt = null
  switch mark.type
    when 'point' then pt = renderCircle(paper, scales, mark)
  if pt
    pt.attr('clip-rect', clipping)
    pt.click () -> eve(id+".click", @, evtData)
    pt.hover () -> eve(id+".hover", @, evtData)
  pt

renderCircle = (paper, scales, mark) ->
  pt = paper.circle()
  pt.attr('cx', scales.x(mark.x))
  pt.attr('cy', scales.y(mark.y))
  pt.attr('r', 10)
  pt.attr('fill', 'black')

