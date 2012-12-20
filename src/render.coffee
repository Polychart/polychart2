###
# GLOBALS
###
poly.paper = (dom, w, h, handleEvent) ->
  if not Raphael?
    throw poly.error.depn "The dependency Raphael is not included."
  paper = Raphael(dom, w, h)
  # add click handler for clicking outside of things
  bg = paper.rect(0,0,w,h).attr('stroke-width', 0)
  bg.click handleEvent('reset')
  # add dragging handle for selecting
  handler = handleEvent('select')
  start = end = null
  onstart = () -> start = null; end = null
  onmove = (dx, dy, y, x) ->
    if start? then end = x:x, y:y else start = x:x, y:y
  onend = () -> if start? and end? then handler start:start, end:end
  bg.drag onmove, onstart, onend
  paper
###
Helper function for rendering all the geoms of an object
###
poly.render = (handleEvent, paper, scales, coord, mayflip, clipping) ->
  add: (mark, evtData) ->
    pt = renderer[coord.type][mark.type].render paper, scales, coord, mark, mayflip
    if clipping? then pt.attr('clip-rect', clipping)
    if evtData and _.keys(evtData).length > 0
      pt.data 'e', evtData
      pt.click handleEvent('click')
      pt.hover handleEvent('mover'), handleEvent('mout')
    pt
  remove: (pt) ->
    pt.remove()
  animate: (pt, mark, evtData) ->
    renderer[coord.type][mark.type].animate pt, scales, coord, mark, mayflip
    if evtData and _.keys(evtData).length > 0
      pt.data 'e', evtData
    pt

class Renderer
  constructor : ->
  render: (paper, scales, coord, mark, mayflip) ->
    pt = @_make(paper)
    for k, v of @attr(scales, coord, mark, mayflip)
      pt.attr(k, v)
    pt
  _make : () -> throw poly.error.impl()
  animate: (pt, scales, coord, mark, mayflip) ->
    pt.animate @attr(scales, coord, mark, mayflip), 300
  attr: (scales, coord, mark, mayflip) -> throw poly.error.impl()
  _makePath : (xs, ys, type='L') ->
    path = _.map xs, (x, i) -> (if i == 0 then 'M' else type) + x+' '+ys[i]
    path.join(' ')
  _maybeApply : (scales, mark, key) ->
    val = mark[key]
    if _.isObject(val) and val.f is 'identity'
      val.v
    else if scales[key]?
      scales[key].f(val)
    else
      val

class Circle extends Renderer # for both cartesian & polar
  _make: (paper) -> paper.circle()
  attr: (scales, coord, mark, mayflip) ->
    {x, y} = coord.getXY mayflip, mark
    stroke =
      if mark.stroke
        @_maybeApply(scales, mark, 'stroke')
      else
        @_maybeApply scales, mark, 'color'
    cx: x
    cy: y
    r: @_maybeApply scales, mark, 'size'
    fill: @_maybeApply scales, mark, 'color'
    opacity: @_maybeApply scales, mark, 'opacity'
    stroke: stroke
    'stroke-width': mark['stroke-width'] ? '0px'

class Path extends Renderer # for both cartesian & polar?
  _make: (paper) -> paper.path()
  attr: (scales, coord, mark, mayflip) ->
    {x, y} = coord.getXY mayflip, mark
    stroke =
      if mark.stroke
        @_maybeApply scales, mark, 'stroke'
      else
        @_maybeApply scales, mark, 'color'
    path: @_makePath x, y
    opacity: @_maybeApply scales, mark, 'opacity'
    'stroke-dasharray': @_maybeApply scales, mark, 'stroke-dasharray'
    'stroke-dashoffset': @_maybeApply scales, mark, 'stroke-dashoffset'
    stroke: stroke

class Line extends Renderer # for both cartesian & polar?
  _make: (paper) -> paper.path()
  attr: (scales, coord, mark, mayflip) ->
    [mark.x,mark.y] = poly.sortArrays scales.x.sortfn, [mark.x,mark.y]
    {x, y} = coord.getXY mayflip, mark
    stroke =
      if mark.stroke
        @_maybeApply scales, mark, 'stroke'
      else
        @_maybeApply scales, mark, 'color'
    path: @_makePath x, y
    'stroke-dasharray': @_maybeApply scales, mark, 'stroke-dasharray'
    'stroke-dashoffset': @_maybeApply scales, mark, 'stroke-dashoffset'
    stroke: stroke
    opacity: @_maybeApply scales, mark, 'opacity'

class Area extends Renderer # for both cartesian & polar?
  _make: (paper) -> paper.path()
  attr: (scales, coord, mark, mayflip) ->
    [x, y] = poly.sortArrays scales.x.sortfn, [mark.x,mark.y.top]
    top = coord.getXY mayflip, {x:x, y:y}
    [x, y] = poly.sortArrays ((a) -> -scales.x.sortfn(a)), [mark.x,mark.y.bottom]
    bottom = coord.getXY mayflip, {x:x, y:y}
    x = top.x.concat bottom.x
    y = top.y.concat bottom.y

    path: @_makePath x, y
    stroke: @_maybeApply scales, mark, 'color'
    opacity: @_maybeApply scales, mark, 'opacity'
    fill: @_maybeApply scales, mark, 'color'
    'stroke-width': '0px'

class Rect extends Renderer # for CARTESIAN only
  _make: (paper) -> paper.rect()
  attr: (scales, coord, mark, mayflip) ->
    {x, y} = coord.getXY mayflip, mark
    x: _.min x
    y: _.min y
    width: Math.abs x[1]-x[0]
    height: Math.abs y[1]-y[0]
    fill: @_maybeApply scales, mark, 'color'
    stroke: @_maybeApply scales, mark, 'color'
    opacity: @_maybeApply scales, mark, 'opacity'
    'stroke-width': '0px'

class CircleRect extends Renderer # FOR POLAR ONLY
  _make: (paper) -> paper.path()
  attr: (scales, coord, mark, mayflip) ->
    [x0, x1] = mark.x
    [y0, y1] = mark.y
    mark.x = [x0, x0, x1, x1]
    mark.y = [y0, y1, y1, y0]
    {x, y, r, t} = coord.getXY mayflip, mark
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
    fill: @_maybeApply scales, mark, 'color'
    stroke: @_maybeApply scales, mark, 'color'
    opacity: @_maybeApply scales, mark, 'opacity'
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
    {x, y} = coord.getXY mayflip, mark
    m =
      x: x
      y: y
      r: 10
      text: @_maybeApply  scales, mark, 'text'
      'text-anchor' : mark['text-anchor'] ? 'left'
      fill: @_maybeApply(scales, mark, 'color') or 'black'
    if mark.transform? then m.transform = mark.transform
    m

renderer =
  cartesian:
    circle: new Circle()
    line: new Line()
    area: new Area()
    path: new Path()
    text: new Text()
    rect: new Rect()
    #hline: new HLine()
    #vline: new VLine()
  polar:
    circle: new Circle()
    path: new Path()
    line: new Line()
    area: new Area()
    text: new Text()
    rect: new CircleRect()
