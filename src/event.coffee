class PolyEvent
  constructor: (name = 'polyjsEvent', obj, type) ->
    @eventName = name
    @bubbles = true
    @cancelable = true
    @detail =
      type: type
      data: obj

  dispatch: (dom) ->
    evt = new CustomEvent @eventName, detail: @detail
    if dom? then dom.dispatchEvent evt

class TitleClickEvent extends PolyEvent
  constructor: (obj, type) ->
    super 'title-click', obj, type

class LegendClickEvent extends PolyEvent
  constructor: (obj, type) ->
    super 'legend-click', obj, type

poly.event = {}
poly.event.make = (type, obj) ->
  if type in ['guide-title', 'guide-titleH', 'guide-titleV']
    return new TitleClickEvent(obj, type)
  else if type in ['legend-label', 'legend-title']
    return new LegendClickEvent(obj, type)
  else
    throw poly.error.defn "No such event #{type}."
