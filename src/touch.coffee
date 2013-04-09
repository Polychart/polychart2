touchInfo = {
  lastStart: 0
  lastTouch: 0
  lastEvent: null
  pressTimer: 0
}
_oldAlert = window.alert
timer = null

# Touch events; use of setTimeout in order to accomodate slow ipad response
poly.touch = (type, obj, event, graph) =>
  obj.tooltip = obj.data('t')
  obj.evtData = obj.data('e')
  touchInfo.lastEvent = event
  event.preventDefault()
  if type is 'touchstart'
    touchInfo.lastStart = event.timeStamp
    poly.touchToMouse 'mousedown', touchInfo
    timer = window.setTimeout((()-> poly.touchToMouse 'mouseover', touchInfo), 800)
    # Hack to delay alert so that code may finish
    window.alert = () ->
      window.clearTimeout timer
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
