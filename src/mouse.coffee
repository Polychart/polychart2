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
poly.mouseEvents = (graph, debug) ->
  bg = graph.paper.getById(0)
  offset = poly.offset(graph.dom)

  # Reset event
  bg.click graph.handleEvent('reset')

  # Mouse selection drag rectangle
  handler = graph.handleEvent('select')
  dragRect = null
  start = end = null
  startInfo = endInfo = null
  onstart = () -> start = null; end = null
  onmove = (dx, dy, x, y) ->
    if start?
      end = x: start.x + dx, y: start.y + dy
      endInfo = graph.facet.getFacetInfo graph.dims, end.x, end.y
      # Update drag rect if within border
      if startInfo? and endInfo?
        dragRect.attr({
          x: Math.min(start.x, end.x)
          y: Math.min(start.y, end.y)
          width: Math.abs(start.x - end.x)
          height: Math.abs(start.y - end.y)
        })
    else
      start = x: x - offset.left, y: y - offset.top
      startInfo = graph.facet.getFacetInfo graph.dims, start.x, start.y
      # Initalized drag rectangle if start within border
      if startInfo?
        dragRect = graph.paper.rect(start.x, start.y, 0, 0, 2)
        dragRect.attr({
          fill: 'black'
          opacity: 0.2
        })
  onend = () -> if start? and end?
    # Clean up drag rectangle
    if dragRect?
      dragRect.attr
        width: 0
        height: 0
      dragRect.remove()

    # For convenience, make start on top left and end at bottom right
    if start.y > end.y
      start.x = start.x + end.x
      end.x = start.x - end.x
      start.x = start.x - end.x
      start.y = start.y + end.y
      end.y = start.y - end.y
      start.y = start.y - end.y
    
    handler start:start, end:end
  bg.drag onmove, onstart, onend

  # Mouse movement handler --- debugging purposes
  if debug
    mouseText = graph.paper.text(20, 20, "x:\ny:")
    showMousePosition = (e) ->
      mousePos = poly.getXY offset, e
      mouseText.attr({text: "x: " + mousePos.x + "\ny:" + mousePos.y})
    bg.mousemove showMousePosition

