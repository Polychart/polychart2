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
    pt = renderer.cartesian[mark.type].render paper, scales, mark
    pt.attr('clip-rect', clipping)
    pt.click () -> eve(id+".click", @, evtData)
    pt.hover () -> eve(id+".hover", @, evtData)
    pt
  remove: (pt) ->
    pt.remove()
  animate: (pt, mark, evtData) ->
    renderer.cartesian[mark.type].animate pt, scales, mark
    pt.unclick() # <-- ?!?!?!
    pt.click () -> eve(id+".click", @, evtData)
    pt.unhover() # <-- ?!?!?!
    pt.hover () -> eve(id+".hover", @, evtData)
    pt

class Renderer
  constructor : ->
  render: (paper, scales, mark) ->
    pt = @_make(paper)
    _.each @attr(scales, mark), (v, k) -> pt.attr(k, v)
    pt
  _make : () -> throw new poly.NotImplemented()
  animate: (pt, scales, mark) -> pt.animate @attr(scales, mark), 300
  attr: (scales, mark) -> throw new poly.NotImplemented()
  _makePath : (xs, ys, type='L') ->
    path = _.map xs, (x, i) -> (if i == 0 then 'M' else type) + x+' '+ys[i]
    path.join(' ') + 'Z'
  _maybeApply : (scale, val) ->
    if scale? then scale(val) else if _.isObject(val) then val.v else val

class Circle extends Renderer # for both cartesian & polar
  _make: (paper) -> paper.circle()
  attr: (scales, mark) ->
    cx: scales.x(mark.x)
    cy: scales.y(mark.y)
    r: @_maybeApply scales.size, mark.size
    fill: @_maybeApply scales.color, mark.color
    stroke: @_maybeApply scales.color, mark.color
    'stroke-width': '0px'

class Line extends Renderer # for both cartesian & polar?
  _make: (paper) -> paper.path()
  attr: (scales, mark) ->
    xs = _.map mark.x, scales.x
    ys = _.map mark.y, scales.y
    path: @_makePath xs, ys
    stroke: 'black'

class HLine extends Renderer # for both cartesian & polar?
  _make: (paper) -> paper.path()
  attr: (scales, mark) ->
    y = scales.y mark.y
    path: @_makePath([0, 100000], [y, y])
    stroke: 'black'
    'stroke-width': '1px'

class VLine extends Renderer # for both cartesian & polar?
  _make: (paper) -> paper.path()
  attr: (scales, mark) ->
    x = scales.x mark.x
    path: @_makePath([x, x], [0, 100000])
    stroke: 'black'
    'stroke-width': '1px'

class Text extends Renderer # for both cartesian & polar
  _make: (paper) -> paper.text()
  attr: (scales, mark) ->
    x: scales.x(mark.x)
    y: scales.y(mark.y)
    text: @_maybeApply  scales.text, mark.text
    'text-anchor' : mark['text-anchor'] ? 'left'
    r: 10
    fill: 'black'

renderer =
  cartesian:
    circle: new Circle()
    line: new Line()
    hline: new HLine()
    vline: new VLine()
    text: new Text()
  polar:
    circle: new Circle()
    line: new Line()
    hline: new HLine()
    vline: new VLine()
    text: new Text()
