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
    pt = renderer[coord.type][mark.type].render paper, scales, coord, mark, mayflip
    if clipping? then pt.attr('clip-rect', clipping)
    pt.click () -> eve(id+".click", @, evtData)
    pt.hover () -> eve(id+".hover", @, evtData)
    pt
  remove: (pt) ->
    pt.remove()
  animate: (pt, mark, evtData) ->
    renderer[coord.type][mark.type].animate pt, scales, coord, mark, mayflip
    pt.unclick() # <-- ?!?!?!
    pt.click () -> eve(id+".click", @, evtData)
    pt.unhover() # <-- ?!?!?!
    pt.hover () -> eve(id+".hover", @, evtData)
    pt

class Renderer
  constructor : ->
  render: (paper, scales, coord, mark, mayflip) ->
    pt = @_make(paper)
    for k, v of @attr(scales, coord, mark, mayflip)
      pt.attr(k, v)
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
    stroke =
      if mark.stroke
        @_maybeApply(scales.stroke, mark.stroke)
      else
        @_maybeApply scales.color, mark.color
    cx: x
    cy: y
    r: @_maybeApply scales.size, mark.size
    fill: @_maybeApply scales.color, mark.color
    stroke: stroke
    title: 'omgthisiscool!'
    'stroke-width': mark['stroke-width'] ? '0px'

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

class CircleRect extends Renderer # FOR POLAR ONLY
  _make: (paper) -> paper.path()
  attr: (scales, coord, mark, mayflip) ->
    [x0, x1] = mark.x
    [y0, y1] = mark.y
    mark.x = [x0, x0, x1, x1]
    mark.y = [y0, y1, y1, y0]
    {x, y, r, t} = coord.getXY mayflip, scales, mark
    if coord.flip
      x.push x.splice(0,1)[0]
      y.push y.splice(0,1)[0]
      r.push r.splice(0,1)[0]
      t.push t.splice(0,1)[0]
    large = if Math.abs(t[1]-t[0]) > Math.PI then 1 else 0
    path = "M #{x[0]} #{y[0]} A #{r[0]} #{r[0]} 0 #{large} 1 #{x[1]} #{y[1]}"
    large = if Math.abs(t[3]-t[2]) > Math.PI then 1 else 0
    path += "L #{x[2]} #{y[2]} A #{r[2]} #{r[2]} 0 #{large} 0 #{x[3]} #{y[3]} Z"

    path: path
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
    text: new Text()
    rect: new Rect()
    #hline: new HLine()
    #vline: new VLine()
  polar:
    circle: new Circle()
    line: new Line()
    text: new Text()
    rect: new CircleRect()
