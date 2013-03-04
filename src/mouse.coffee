###
Get the offset of the element
###
poly.offset = (elem) ->
  box = {top: 0, left: 0}
  doc = elem && elem.ownerDocument
  if !doc then return
  docElem = doc.documentElement
  if typeof elem.getBoundingClientRect isnt "undefined"
    box = elem.getBoundingClientRect()
  win =
    if doc isnt null and doc is doc.window
      doc
    else
      doc.nodeType is 9 and doc.defaultView
  top: box.top + win.pageYOffset - docElem.clientTop
  left: box.left + win.pageXOffset - docElem.clientLeft
#
###
Get the raphael (x,y) position of a mouse event
###
poly.getXY = (offset, e) ->
  x = e.clientX
  y = e.clientY
  scrollY = document.documentElement.scrollTop ? document.body.scrollTop
  scrollX = document.documentElement.scrollLeft ? document.body.scrollLeft
  x: x + scrollX - offset.left
  y: y + scrollY - offset.top
###
Mouse Event Handlers
###
poly.mouseEvents = (graph, bg, debug = false) ->
  offset = poly.offset(graph.dom)

  # Mouse selection drag rectangle
  handler = graph.handleEvent('select')
  dragRect = null
  rect = null
  start = end = null
  startInfo = endInfo = null
  col = row = null
  onstart = () -> start = null; end = null
  onmove = (dx, dy, x, y) ->
    if startInfo? and start?
      end = x: start.x + dx, y: start.y + dy
      endInfo = graph.facet.getFacetInfo graph.dims, end.x, end.y
      # Update drag rect if within border
      if endInfo? and endInfo.col is startInfo.col and endInfo.row is startInfo.row
        attr =
          x: Math.min start.x, end.x
          y: Math.min start.y, end.y
          width: Math.abs(start.x - end.x)
          height: Math.abs(start.y - end.y)
        rect = poly.drawRect(graph.paper, attr, rect)
    else
      start = x: x - offset.left, y: y - offset.top
      startInfo = graph.facet.getFacetInfo graph.dims, start.x, start.y
      # Initalized drag rectangle if start within border
      if startInfo?
        attr = {x: start.x, y: start.y, w: 0, h: 0, r: 2}
        rect = poly.drawRect(graph.paper, attr)
        rect = poly.drawRect(graph.paper, {fill: 'black', opacity: 0.2}, rect)
  onend = () -> if start? and end?
    # Clean up drag rectangle
    if rect?
      rect = poly.drawRect(graph.paper, 'remove', rect)
    handler start:start, end:end
  bg.drag onmove, onstart, onend

  # Mouse movement handler --- debugging purposes
  if debug
    attr = {x: 20, y: 20, text: "x:\ny:"}
    mouseText = poly.drawText(graph.paper, attr)
    showMousePosition = (e) ->
      mousePos = poly.getXY offset, e
      attr = {text: "x: " + mousePos.x + "\ny: " + mousePos.y}
      mouseText = poly.drawText(graph.paper, attr, mouseText)
    bg.mousemove showMousePosition

