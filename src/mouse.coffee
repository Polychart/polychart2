
###
Stuff
###
poly.getXY = (offset, e) ->
  x = e.clientX
  y = e.clientY
  scrollY = document.documentElement.scrollTop ? document.body.scrollTop
  scrollX = document.documentElement.scrollLeft ? document.body.scrollLeft
  x: x + scrollX - offset.left
  y: y + scrollY - offset.top
