poly.handler = {}


poly.handler.tooltip = () ->
  tooltip = {}
  (type, obj, event) ->
    if type is 'mover' or type is 'mout'
      if tooltip.text?
        tooltip.text.remove()
        tooltip.box.remove()
      tooltip = {}
      if type is 'mover' and obj.tooltip
        paper = obj.paper
        # first get the bounding box of the object
        {x, y, x2, y2} = obj.getBBox()
        # put the tooltip text at the top middle of object
        y1 = y
        x1 = x/2 + x2/2
        tooltip.text = paper.text(x1, y1, obj.tooltip).attr
          'text-anchor':'middle'
          'fill':'white'
        # now figure out where the tooltip text is and move it up enough to not
        # obstruct the object
        {x, y, width, height} =tooltip.text.getBBox()
        y = (y1-height) + 4
        tooltip.text.attr 'y': y
        # bound the text with a rounded rectangle background
        {x, y, width, height} =tooltip.text.getBBox()
        tooltip.box = paper.rect(x-5, y-5, width+10, height+10, 5)
        tooltip.box.attr fill: '#213'
        # move the text to the front of the rectangle
        tooltip.text.toFront()

