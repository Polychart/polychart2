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
    pt.animate attr, 300
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
      # handle the case when mark.FOO does not exist
      cx: scales.x(mark.x)
      cy: scales.y(mark.y)
      r: 10
      fill: 'black'
    animate: (pt, scales, mark) -> pt.animate attr
  line:
    render: (paper, scales, mark) ->
      pt = paper.path()
      _.each renderer.line.attr(scales, mark), (v, k) -> pt.attr(k, v)
      pt
    attr: (scales, mark) ->
      xs = _.map mark.x scales.x
      ys = _.map mark.y scales.y
      path: _makePath xs, ys
      stroke: 'black'
    animate: (pt, scales, mark) -> pt.animate attr
  hline:
    render: (paper, scales, mark) ->
      pt = paper.path()
      _.each renderer.hline.attr(scales, mark), (v, k) -> pt.attr(k, v)
      pt
    attr: (scales, mark) ->
      y = scales.y mark.y
      path: _makePath([0, 100000], [y, y])
      stroke: 'black'
      'stroke-width': '1px'
    animate: (pt, scales, mark) -> pt.animate attr

  vline:
    render: (paper, scales, mark) ->
      pt = paper.path()
      _.each renderer.vline.attr(scales, mark), (v, k) -> pt.attr(k, v)
      pt
    attr: (scales, mark) ->
      x = scales.x mark.x
      path: _makePath([x, x], [0, 100000])
      stroke: 'black'
      'stroke-width': '1px'
    animate: (pt, scales, mark) -> pt.animate attr

_makePath = (xs, ys) ->
  str = ''
  _.each xs, (x, i) ->
    y = ys[i]
    if str == '' then str+='M'+x+' '+y
    else str +=' L'+x+' '+y
  str + ' Z'

