###
# GLOBALS
###
poly.paper = (dom, w, h, graph) ->
  if not Raphael?
    throw poly.error.depn "The dependency Raphael is not included."
  paper = Raphael(dom, w, h)
  # Handlers and events for clicking outside of graph geometry
  bg = paper.rect(0,0,w,h).attr
    fill: 'white' # for FireFox
    opacity: 0    # for not showing background
    'stroke-width': 0
  bg.click graph.handleEvent('reset')
  poly.mouseEvents graph, bg, false
  poly.touchEvents graph.handleEvent, bg, true
  paper

###
Mouse Events
###
poly.mouseEvents = (graph, bg, showRect) ->
  # Mouse selection drag rectangle
  handler = graph.handleEvent('select')
  if showRect
    rect = null
  start = end = null
  startInfo = endInfo = null
  onstart = () -> start = null; end = null
  onmove = (dx, dy, x, y) ->
    if startInfo? and start?
      end = x: start.x + dx, y: start.y + dy
      endInfo = graph.facet.getFacetInfo graph.dims, end.x, end.y
      # Update drag rect if within border
      if rect? and endInfo? and endInfo.col is startInfo.col and endInfo.row is startInfo.row and showRect
        attr =
          x: Math.min start.x, end.x
          y: Math.min start.y, end.y
          width: Math.abs(start.x - end.x)
          height: Math.abs(start.y - end.y)
        rect = rect.attr attr
    else
      offset = poly.offset graph.dom
      start = x: x - offset.left, y: y - offset.top
      startInfo = graph.facet.getFacetInfo graph.dims, start.x, start.y
      # Initalize drag rectangle if start within border
      if startInfo? and showRect
        rect = graph.paper.rect(start.x, start.y, 0, 0, 2)
        rect = rect.attr {fill: 'black', opacity: 0.2}
  onend = () -> if start? and end?
    # Clean up drag rectangle
    if rect? and showRect
      rect = rect.hide()
      rect.remove()
    handler start:start, end:end
  bg.drag onmove, onstart, onend

poly.touchEvents = (handleEvent, elem, enable=true) ->
  if enable
    elem.touchstart handleEvent('touchstart')
    elem.touchend handleEvent('touchend')
    elem.touchmove handleEvent('touchmove')
    elem.touchcancel handleEvent('touchcancel')
###
Helper function for rendering all the geoms of an object
###
poly.render = (handleEvent, paper, scales, coord) -> (offset={}, clipping=false, mayflip=true) ->
  if not coord.type?
    throw poly.error.unknown "Coordinate don't have at type?"
  if not renderer[coord.type]?
    throw poly.error.input "Unknown coordinate type #{coord.type}"
  add: (mark, evtData, tooltip, type) ->
    if not renderer[coord.type][mark.type]?
      throw poly.error.input "Coord #{coord.type} has no mark #{mark.type}"
    pt = renderer[coord.type][mark.type].render paper, scales, coord, offset, mark, mayflip
    # data
    pt.data 'm', mark
    if evtData and _.keys(evtData).length > 0
      pt.data 'e', evtData
    if tooltip
      pt.data 't', tooltip
    # clipping
    if clipping? then pt.attr('clip-rect', clipping)
    # handlers
    if type is 'guide'
      pt.click handleEvent('guide-click')
      poly.touchEvents handleEvent, pt, true
    else if type in ['guide-title', 'guide-titleH', 'guide-titleV']
      pt.click handleEvent(type)
      poly.touchEvents handleEvent, pt, true
    else
      pt.click handleEvent('click')
      pt.hover handleEvent('mover'), handleEvent('mout')
      poly.touchEvents handleEvent, pt, true
    pt
  remove: (pt) ->
    pt.remove()
  animate: (pt, mark, evtData, tooltip) ->
    renderer[coord.type][mark.type].animate pt, scales, coord, offset, mark, mayflip
    if clipping? then pt.attr('clip-rect', clipping)
    if evtData and _.keys(evtData).length > 0
      pt.data 'e', evtData
    if tooltip
      pt.data 't', tooltip
    pt.data 'm', mark
    pt

class Renderer
  constructor : ->
  render: (paper, scales, coord, offset, mark, mayflip) ->
    pt = @_make(paper)
    for k, v of @attr(scales, coord, offset, mark, mayflip)
      pt.attr(k, v)
    pt
  _make : () -> throw poly.error.impl()
  animate: (pt, scales, coord, offset, mark, mayflip) ->
    pt.animate @attr(scales, coord, offset, mark, mayflip), 300
  attr: (scales, coord, offset, mark, mayflip) -> throw poly.error.impl()
  _cantRender: (aes) -> throw poly.error.missingdata()
  _makePath : (xs, ys, type='L') ->
    switch type
      when 'spline'
        path = _.map xs, (x, i) -> (if i == 0 then "M #{x} #{ys[i]} R " else '') + "#{x} #{ys[i]}"
      else
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
  _applyOffset: (x, y, offset) ->
    if not offset then return {x: x, y: y}
    offset.x ?= 0
    offset.y ?= 0
    x : if _.isArray(x) then (i+offset.x for i in x) else x+offset.x
    y : if _.isArray(y) then (i+offset.y for i in y) else y+offset.y
  _shared : (scales, mark, attr) ->
    maybeAdd = (aes) =>
      if mark[aes]? and not attr[aes]?
        attr[aes] = @_maybeApply scales, mark, aes
    maybeAdd('opacity')
    maybeAdd('stroke-width')
    maybeAdd('stroke-dasharray')
    maybeAdd('stroke-dashoffset')
    maybeAdd('transform')
    maybeAdd('font-size')
    maybeAdd('font-weight')
    maybeAdd('font-family')
    attr
  _checkPointUndefined: (x, y, type="Point") ->
    if x is undefined or y is undefined
      throw poly.error.missing "#{type} cannot be plotted due to undefined data."
  _checkArrayUndefined: (x, y, type="Line") ->
    if _.all (x[i] is undefined or y[i] is undefined for i in [0..x.length-1])
      throw poly.error.missing "#{type} cannot be plotted due to too many missing points."
  _checkArrayNaN: (xs, ys) ->
    zs = _.map _.zip(xs, ys), (z,i) -> (if isNaN(z[0]) or isNaN(z[1]) then undefined else z)
    {x: (z[0] for z in zs when z?),  y: (z[1] for z in zs when z?)}

# Path animations are atrocious. See http://bost.ocks.org/mike/path/ for
# why. So, for a handful of geometries we need to interpolate the
# transforms. But because we don't use SVG transforms, this creates
# some challenges.
class PathRenderer extends Renderer
  animate: (pt, scales, coord, offset, mark, mayflip) ->
    # we'll split the animation component into two if the set of x-coordinates
    # have changed. otherwise do the animation in one shot.
    oldmark = pt.data('m')
    newattr = @attr(scales, coord, offset, mark, mayflip)
    if not _.isEqual(oldmark.x, mark.x)
      # first we "animate the transform": use the old mark & new scale
      # then we change the attribute to those corresponding to the new mark
      #   without animation.
      scaleattr = @attr(scales, coord, offset, oldmark, mayflip)
      pt.animate scaleattr, 300, () => pt.attr newattr
    else
      pt.animate newattr, 300

class Circle extends Renderer # for both cartesian & polar
  _make: (paper) -> paper.circle()
  attr: (scales, coord, offset, mark, mayflip) ->
    {x, y} = coord.getXY mayflip, mark
    @_checkPointUndefined(x, y, "Circle")
    {x, y} = @_applyOffset(x, y, offset)
    stroke = @_maybeApply scales, mark,
      if mark.stroke then 'stroke' else 'color'
    attr =
      cx: x
      cy: y
      r: @_maybeApply scales, mark, 'size'
      stroke: stroke

    fill = @_maybeApply scales, mark, 'color'
    if fill and fill isnt 'none' then attr.fill = fill
    @_shared scales, mark, attr

class Path extends Renderer # for both cartesian & polar?
  _make: (paper) -> paper.path()
  attr: (scales, coord, offset, mark, mayflip) ->
    {x, y} = coord.getXY mayflip, mark
    @_checkArrayUndefined(x, y, "Path")
    {x, y} = @_applyOffset(x, y, offset)
    stroke = @_maybeApply scales, mark,
      if mark.stroke then 'stroke' else 'color'
    size = @_maybeApply scales, mark,
      if mark.size then 'size' else 'stroke-width'
    @_shared scales, mark,
      path: @_makePath x, y
      stroke: stroke
      'stroke-width': size

class Line extends PathRenderer
  _make: (paper) -> paper.path()
  attr: (scales, coord, offset, mark, mayflip) ->
    [mark.x,mark.y] = poly.sortArrays scales.x.compare, [mark.x,mark.y]
    {x, y} = coord.getXY mayflip, mark
    @_checkArrayUndefined(x, y, "Line")
    for xi, i in x
      yi = y[i]
    {x, y} = @_applyOffset(x, y, offset)
    {x, y} = @_checkArrayNaN(x, y)
    stroke = @_maybeApply scales, mark,
      if mark.stroke then 'stroke' else 'color'
    size = @_maybeApply scales, mark,
      if mark.size then 'size' else 'stroke-width'
    @_shared scales, mark,
      path: @_makePath x, y
      stroke: stroke
      'stroke-width': size

class Spline extends Line
  attr: (scales, coord, offset, mark, mayflip) ->
    [mark.x,mark.y] = poly.sortArrays scales.x.compare, [mark.x,mark.y]
    {x, y} = coord.getXY mayflip, mark
    @_checkArrayUndefined(x, y, "Spline")
    for xi, i in x
      yi = y[i]
    {x, y} = @_applyOffset(x, y, offset)
    {x, y} = @_checkArrayNaN x, y # Remove any non numeric values---needed for splines
    stroke = @_maybeApply scales, mark,
      if mark.stroke then 'stroke' else 'color'
    size = @_maybeApply scales, mark,
      if mark.size then 'size' else 'stroke-width'
    @_shared scales, mark,
      path: @_makePath x, y, 'spline'
      stroke: stroke
      'stroke-width': size

# The difference between Line and PolarLine is that Polar Line MAY plot a circle
class PolarLine extends Line
  attr: (scales, coord, offset, mark, mayflip) ->
    {x, y, r, t} = coord.getXY mayflip, mark
    @_checkArrayUndefined(x, y, "Line")
    {x, y} = @_applyOffset(x, y, offset)
    path =
      if _.max(r) - _.min(r) < poly.const.epsilon
        r = r[0]
        path = "M #{x[0]} #{y[0]}"
        for i in [1..x.length-1]
          large = if Math.abs(t[i]-t[i-1]) > Math.PI then 1 else 0
          dir = if t[i]-t[i-1] > 0 then 1 else 0
          path += "A #{r} #{r} 0 #{large} #{dir} #{x[i]} #{y[i]}"
        path
      else
        @_makePath x, y
    stroke = @_maybeApply scales, mark,
      if mark.stroke then 'stroke' else 'color'
    @_shared scales, mark,
      path: path
      stroke: stroke

class Area extends PathRenderer # for both cartesian & polar?
  _make: (paper) -> paper.path()
  attr: (scales, coord, offset, mark, mayflip) ->
    [x, y] = poly.sortArrays scales.x.compare, [mark.x,mark.y.top]
    top = coord.getXY mayflip, {x:x, y:y}
    top = @_applyOffset(top.x, top.y, offset)
    [x, y] = poly.sortArrays ((a,b) -> -scales.x.compare(a,b)), [mark.x,mark.y.bottom]
    bottom = coord.getXY mayflip, {x:x, y:y}
    bottom = @_applyOffset(bottom.x, bottom.y, offset)
    x = top.x.concat bottom.x
    y = top.y.concat bottom.y
    @_shared scales, mark,
      path: @_makePath x, y
      stroke: @_maybeApply scales, mark, 'color'
      fill: @_maybeApply scales, mark, 'color'
      'stroke-width': '0px'

class Rect extends Renderer # for CARTESIAN only
  _make: (paper) -> paper.rect()
  attr: (scales, coord, offset, mark, mayflip) ->
    {x, y} = coord.getXY mayflip, mark
    @_checkPointUndefined(x[0], y[0], "Bar")
    @_checkPointUndefined(x[1], y[1], "Bar")
    {x, y} = @_applyOffset(x, y, offset)
    stroke = @_maybeApply scales, mark,
      if mark.stroke then 'stroke' else 'color'
    @_shared scales, mark,
      x: _.min x
      y: _.min y
      width: Math.abs x[1]-x[0]
      height: Math.abs y[1]-y[0]
      fill: @_maybeApply scales, mark, 'color'
      stroke: stroke
      'stroke-width': @_maybeApply scales, mark, 'stroke-width' ? '0px'

class CircleRect extends Renderer # FOR POLAR ONLY
  _make: (paper) -> paper.path()
  attr: (scales, coord, offset, mark, mayflip) ->
    [x0, x1] = mark.x
    [y0, y1] = mark.y
    @_checkPointUndefined(x0, y0, "Bar")
    @_checkPointUndefined(x1, y1, "Bar")
    mark.x = [x0, x0, x1, x1]
    mark.y = [y0, y1, y1, y0]
    {x, y, r, t} = coord.getXY mayflip, mark
    {x, y} = @_applyOffset(x, y, offset)
    if coord.flip
      x.push x.splice(0,1)[0]
      y.push y.splice(0,1)[0]
      r.push r.splice(0,1)[0]
      t.push t.splice(0,1)[0]
    if 2*Math.PI -  Math.abs(t[1]-t[0]) < poly.const.epsilon # Check for full pie
      path = "M #{x[0]} #{y[0]} A #{r[0]} #{r[0]} 0 1 1 #{x[0]} #{y[0] + 2 * r[0]} A #{r[1]} #{r[1]} 0 1 1 #{x[1]} #{y[1]}"
      path += "M #{x[2]} #{y[2]} A #{r[2]} #{r[2]} 0 1 0 #{x[2]} #{y[2] + 2*r[2]} A #{r[3]} #{r[3]} 0 1 0 #{x[3]} #{y[3]} Z"
    else
      large = if Math.abs(t[1]-t[0]) > Math.PI then 1 else 0
      path = "M #{x[0]} #{y[0]} A #{r[0]} #{r[1]} 0 #{large} 1 #{x[1]} #{y[1]}"
      large = if Math.abs(t[3]-t[2]) > Math.PI then 1 else 0
      path += "L #{x[2]} #{y[2]} A #{r[2]} #{r[3]} 0 #{large} 0 #{x[3]} #{y[3]} Z"
    stroke = @_maybeApply scales, mark,
      if mark.stroke then 'stroke' else 'color'
    @_shared scales, mark,
      path: path
      fill: @_maybeApply scales, mark, 'color'
      stroke: stroke
      'stroke-width': @_maybeApply scales, mark, 'stroke-width' ? '0px'

class Text extends Renderer # for both cartesian & polar
  _make: (paper) -> paper.text()
  attr: (scales, coord, offset, mark, mayflip) ->
    {x, y} = coord.getXY mayflip, mark
    @_checkPointUndefined(x, y, "Text")
    {x, y} = @_applyOffset(x, y, offset)

    @_shared scales, mark,
      x: x
      y: y
      r: 10
      text: @_maybeApply  scales, mark, 'text'
      'font-size': @_maybeApply  scales, mark, 'size'
      'text-anchor' : mark['text-anchor'] ? 'left'
      fill: @_maybeApply(scales, mark, 'color') or 'black'

renderer =
  cartesian:
    circle: new Circle()
    line: new Line()
    pline: new Line() # may plot a circle in polar coord, but same as line here
    area: new Area()
    path: new Path()
    text: new Text()
    rect: new Rect()
    spline: new Spline()
  polar:
    circle: new Circle()
    path: new Path()
    line: new Line()
    pline: new PolarLine() # pline may plot a circle
    area: new Area()
    text: new Text()
    rect: new CircleRect()
    spline: new Spline()
