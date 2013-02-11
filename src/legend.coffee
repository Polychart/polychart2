###
Legends (Guide)
---------
Classes related to the generation and management of legends.

Legend object takes in required input and produces abstract geometrical
objects that can be rendered using the Geometry class. Legends are less
disposable compared to axes and layers, because legends themselves may be
added, removed, or modified.

Each legend assumes that it will render at coordinate (0,0). It is up to the
Legends (GuideSet) object to determine the correct position of a legend.
###

sf = poly.const.scaleFns

class Legend extends poly.Guide
  constructor: (@aes) ->
    @geometry = new poly.Geometry
  make: (params) ->
    {domain, type, guideSpec, @mapping, keys} = params
    @titletext = guideSpec.title ? keys
    @ticks = poly.tick.make domain, guideSpec, type
    @height = @TITLEHEIGHT + @SPACING + @TICKHEIGHT*_.size @ticks
    titleWidth = poly.strSize @titletext
    tickWidth = _.max _.map @ticks, (t) -> poly.strSize t.value
    @maxwidth = Math.max titleWidth, tickWidth
  calculate: () ->
    geoms = {}
    geoms['title'] = marks: 0: @_makeTitle(@titletext)
    for key, tick of @ticks
      marks = {}
      marks.tick = @_makeTick(tick)
      marks.text = @_makeLabel(tick)
      evtData = @_makeEvtData(tick)
      geoms[key] =
        marks: marks
        evtData: evtData
    geoms
  render: (renderer) ->
    @geometry.set @calculate()
    @geometry.render(renderer)
  dispose: (renderer) -> @geometry.dispose(renderer)
  _makeLabel: (tick) ->
    type: 'text'
    x : sf.identity 20
    y : sf.identity (15+tick.index*12) + 1
    text: tick.value
    'text-anchor' : 'start'
  _makeTick: (tick) =>
    obj =
      type: 'circle'
      x : sf.identity 10
      y : sf.identity (15+tick.index*12)
      color: sf.identity 'steelblue' # can be overwritten
    for aes, value of @mapping
      if aes in poly.const.noLegend then continue
      value = value[0] # just use the first for now?
      if aes in @aes
        obj[aes] = tick.location
      else if value.type? and value.type == 'const'
        # take assigned const value of first layer
        obj[aes] = sf.identity value.value
      else if not _.isObject value
        # take the layer default value
        obj[aes] = sf.identity value
      else
        # take teh global default value
        obj[aes] = sf.identity poly.const.defaults[aes]
    obj
  _makeEvtData: (tick) =>
    evtData = {}
    for aes, value of @mapping
      if aes in poly.const.noLegend then continue
      for v in value
        if aes in @aes and v.type is 'map'
          evtData[v.value] = tick.evtData
    evtData
  _makeTitle: (text) ->
    type: 'text'
    x : sf.identity 5
    y : sf.identity 0
    text: text
    'text-anchor' : 'start'
  getDimension: () ->
    position: 'left'
    height: @height
    width: 15+@maxwidth
poly.guide.legend = (aes) -> return new Legend(aes)
