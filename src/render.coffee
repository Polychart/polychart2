poly = @poly || {}

###
# GLOBALS
###
poly.paper = (dom, w, h) -> Raphael(dom, w, h)

poly.render = (geoms, paper, scales) ->
  _.each geoms, (geom) ->
    evtData = geom.evtData
    _.each geom.geoms, (mark) ->
      poly.point(mark, paper, scales)

poly.point = (mark, paper, scales) ->
  pt = paper.circle()
  pt.attr('cx', scales.x(mark.x))
  pt.attr('cy', scales.y(mark.y))
  pt.attr('r', 5)
