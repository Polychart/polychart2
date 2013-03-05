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
