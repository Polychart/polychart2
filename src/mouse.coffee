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
  if e.type.indexOf('mouse') isnt -1
    x = e.clientX
    y = e.clientY
  else if e.type.indexOf('touch') isnt -1
    touch = e.changedTouches[0]
    x = touch.clientX
    y = touch.clientY
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

###
Touch Event Handling
###
touchInfo = {
  lastStart: 0
  lastTouch: 0
  lastEvent: null
  pressTimer: 0
}
_oldAlert = window.alert

# Touch events; use of setTimeout in order to accomodate slow ipad response
poly.touch = (type, obj, event, graph) =>
  obj.tooltip = obj.data('t')
  obj.evtData = obj.data('e')
  touchInfo.lastEvent = event
  event.preventDefault()
  if type is 'touchstart'
    touchInfo.lastStart = event.timeStamp
    poly.touchToMouse 'mousedown', touchInfo
    touchInfo.pressTimer = window.setTimeout((()-> poly.touchToMouse 'mouseover', touchInfo), 800)
    # Hack to delay alert so that code may finish
    window.alert = () ->
      window.clearTimeout touchInfo.pressTimer
      args = arguments
      window.setTimeout((() -> _oldAlert.apply(window, args);window.alert = _oldAlert), 100)
  else if type is 'touchmove'
    elem = graph.paper.getById event.target.raphaelid
    offset = poly.offset graph.dom
    touchPos = poly.getXY offset, event
    if event.timeStamp - touchInfo.lastStart > 600 && elem.isPointInside touchPos.x, touchPos.y
      poly.touchToMouse 'mouseover', touchInfo
    else
      window.clearTimeout touchInfo.pressTimer
      poly.touchToMouse 'mouseout', touchInfo
  else if type is 'touchend'
    window.clearTimeout touchInfo.pressTimer
    poly.touchToMouse 'mouseup', touchInfo
    poly.touchToMouse 'mouseout', touchInfo, 400
    if event.timeStamp - touchInfo.lastStart < 800
      poly.touchToMouse 'click', touchInfo
  else if type is 'touchcancel'
    window.clearTimeout touchInfo.pressTimer
    poly.touchToMouse 'mouseout', touchInfo
    poly.touchToMouse 'mouseup', touchInfo, 300
