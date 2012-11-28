poly = @poly || {}

###
# GLOBALS
###
poly.paper = (dom, w, h) -> Raphael(dom, w, h)

###
Helper function for rendering all the geoms of an object

TODO: 
- make add & remove animations
- make everything animateWith some standard object
###
poly.render = (id, paper, scales, clipping) ->
  add: (mark, evtData) ->
    pt = renderer[mark.type].render paper, scales, mark
    pt.attr('clip-rect', clipping)
    pt.click () -> eve(id+".click", @, evtData)
    pt.hover () -> eve(id+".hover", @, evtData)
    pt
  remove: (pt) ->
    pt.remove()
  animate: (pt, mark, evtData) ->
    attr = renderer[mark.type].attr scales, mark
    pt.animate attr
    pt.unclick() # <-- ?!?!?!
    pt.click () -> eve(id+".click", @, evtData)
    pt.unhover() # <-- ?!?!?!
    pt.hover () -> eve(id+".hover", @, evtData)
    pt

renderer =
  circle:
    render: (paper, scales, mark) ->
      pt = paper.circle()
      _.each renderer.circle.attr(scales, mark), (v, k) -> pt.attr(k, v)
      pt
    attr: (scales, mark) ->
      cx: scales.x(mark.x)
      cy: scales.y(mark.y)
      r: 10
      fill: 'black'
    animate: (pt, scales, mark) ->
      pt.animate attr
