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
  # Support for different browser settings
  scrollY = (document.documentElement && document.documentElement.scrollTop) || document.body.scrollTop
  scrollX = (document.documentElement && document.documentElement.scrollLeft) || document.body.scrollLeft
  x: x + scrollX - offset.left
  y: y + scrollY - offset.top
###
Transforms a TouchEvent to MouseEvent
###
poly.touchToMouse = (type, touchInfo, delay=false) ->
  event = touchInfo.lastEvent
  first = (event.touches.length > 0 && event.touches[0]) || (event.changedTouches.length > 0 && event.changedTouches[0])
  evt = document.createEvent 'MouseEvent'
  evt.initMouseEvent(type, event.bubbles, event.cancelable, event.view, event.detail,
                     first.screenX, first.screenY, first.clientX, first.clientY,
                     event.ctrlKey, event.altKey, event.shiftKey, event.metaKey, 1, event.target)
  if delay
    window.clearTimeout touchInfo.pressTimer
    touchInfo.pressTimer = window.setTimeout((() -> event.target.dispatchEvent evt), delay)
  else
    event.target.dispatchEvent evt


