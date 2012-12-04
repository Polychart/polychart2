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
poly.render = (id, paper, scales, coord, mayflip, clipping) ->
  add: (mark, evtData) ->
    pt = renderer.cartesian[mark.type].render paper, scales, coord, mark, mayflip
    if clipping? then pt.attr('clip-rect', clipping)
    pt.click () -> eve(id+".click", @, evtData)
    pt.hover () -> eve(id+".hover", @, evtData)
    pt
  remove: (pt) ->
    pt.remove()
  animate: (pt, mark, evtData) ->
    renderer.cartesian[mark.type].animate pt, scales, coord, mark, mayflip
    pt.unclick() # <-- ?!?!?!
    pt.click () -> eve(id+".click", @, evtData)
    pt.unhover() # <-- ?!?!?!
    pt.hover () -> eve(id+".hover", @, evtData)
    pt

class Renderer
  constructor : ->
  render: (paper, scales, coord, mark, mayflip) ->
    pt = @_make(paper)
    _.each @attr(scales, coord, mark, mayflip), (v, k) -> pt.attr(k, v)
    pt
  _make : () -> throw new poly.NotImplemented()
  animate: (pt, scales, coord, mark, mayflip) ->
    pt.animate @attr(scales, coord, mark, mayflip), 300
  attr: (scales, coord, mark, mayflip) -> throw new poly.NotImplemented()
  _makePath : (xs, ys, type='L') ->
    path = _.map xs, (x, i) -> (if i == 0 then 'M' else type) + x+' '+ys[i]
    path.join(' ')
  _maybeApply : (scale, val) ->
    if scale? then scale(val) else if _.isObject(val) then val.v else val

class Circle extends Renderer # for both cartesian & polar
  _make: (paper) -> paper.circle()
  attr: (scales, coord, mark, mayflip) ->
    {x, y} = coord.getXY mayflip, scales, mark
    cx: x
    cy: y
    r: @_maybeApply scales.size, mark.size
    fill: @_maybeApply scales.color, mark.color
    stroke: @_maybeApply scales.color, mark.color
    title: 'omgthisiscool!'
    'stroke-width': '0px'

class Line extends Renderer # for both cartesian & polar?
  _make: (paper) -> paper.path()
  attr: (scales, coord, mark, mayflip) ->
    {x, y} = coord.getXY mayflip, scales, mark
    path: @_makePath x, y
    stroke: 'black'

class Rect extends Renderer # for CARTESIAN only
  _make: (paper) -> paper.rect()
  attr: (scales, coord, mark, mayflip) ->
    {x, y} = coord.getXY mayflip, scales, mark
    x: _.min x
    y: _.min y
    width: Math.abs x[1]-x[0]
    height: Math.abs y[1]-y[0]
    fill: @_maybeApply scales.color, mark.color
    stroke: @_maybeApply scales.color, mark.color
    'stroke-width': '0px'

"""
class HLine extends Renderer # for both cartesian & polar?
  _make: (paper) -> paper.path()
  attr: (scales, coord, mark) ->
    y = scales.y mark.y
    path: @_makePath([0, 100000], [y, y])
    stroke: 'black'
    'stroke-width': '1px'

class VLine extends Renderer # for both cartesian & polar?
  _make: (paper) -> paper.path()
  attr: (scales, coord, mark) ->
    x = scales.x mark.x
    path: @_makePath([x, x], [0, 100000])
    stroke: 'black'
    'stroke-width': '1px'
"""

class Text extends Renderer # for both cartesian & polar
  _make: (paper) -> paper.text()
  attr: (scales, coord, mark, mayflip) ->
    {x, y} = coord.getXY mayflip, scales, mark

    m =
      x: x
      y: y
      text: @_maybeApply  scales.text, mark.text
      'text-anchor' : mark['text-anchor'] ? 'left'
      r: 10
      fill: 'black'
    if mark.transform? then m.transform = mark.transform
    m

renderer =
  cartesian:
    circle: new Circle()
    line: new Line()
    #hline: new HLine()
    #vline: new VLine()
    text: new Text()
    rect: new Rect()
  polar:
    circle: new Circle()
    line: new Line()
    text: new Text()
