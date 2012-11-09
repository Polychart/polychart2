poly = @poly || {}

###
# GLOBALS
###
poly.paper = (dom, w, h) -> Raphael(dom, w, h)

###
Helper function for rendering all the geoms of an object
###
poly.render = (geoms, paper, scales, clipping) ->
  _.each geoms, (geom) ->
    evtData = geom.evtData
    _.each geom.marks, (mark) ->
      poly.point(mark, paper, scales, clipping)

###
Rendering a single point
###
poly.point = (mark, paper, scales, clipping) ->
  pt = paper.circle()
  pt.attr('cx', scales.x(mark.x))
  pt.attr('cy', scales.y(mark.y))
  pt.attr('r', 10)
  pt.attr('fill', 'black')
  pt.attr('clip-rect', clipping)
