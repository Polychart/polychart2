class PolyEvent
  constructor: () ->
    @eventName = 'polyjsEvent'
    @bubbles = true
    @cancelable = true
    @detail =
      type: null
      data: null

  dispatch: (dom) ->
    evt = new CustomEvent @eventName, detail: @detail
    if dom? then dom.dispatchEvent evt

class TitleClickEvent extends PolyEvent
  constructor: (obj, type) ->
    super()
    @eventName = 'title-click'
    @detail =
      type: type
      data: obj

poly.event = {}
poly.event.make = (type, obj) ->
  if type in ['guide-title', 'guide-titleH', 'guide-titleV']
    return new TitleClickEvent(obj, type)
  throw poly.error.defn "No such event #{type}."
