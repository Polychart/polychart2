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

poly.guide.legends = () -> return new Legends()

poly.guide.legend = (aes) -> return new Legend(aes)

class Legends extends poly.GuideSet
  constructor: () ->
    @legends = []
    @deletedLegends = []
  make: (params) ->
    {mapping, domains, layers, guideSpec, scales, layerMapping} = params
    # figure out which groups of aesthetics need to be represented
    aesGroups = @_mergeAes domains, layers
    # now iterate through existing legends AND the aesGroups to see
    #   1) if any existing legends need to be deleted,
    #      in which case move that legend from @legends into @deletedLEgends
    #   2) if any new legends need to be created
    #      in which case KEEP it in aesGroups (otherwise remove)
    idx = 0
    while idx < @legends.length
      legend = @legends[idx]
      legenddeleted = true
      i = 0
      while i < aesGroups.length
        aes = aesGroups[i]
        if _.isEqual aes, legend.aes
          aesGroups.splice i, 1
          legenddeleted = false
          break
        i++
      if legenddeleted
        @deletedLegends.push legend
        @legends.splice(idx, 1)
      else
        idx++
    # create new legends
    for aes in aesGroups
      @legends.push poly.guide.legend aes
    # make each legend
    for legend in @legends
      aes = legend.aes[0]
      legend.make
        domain: domains[aes]
        guideSpec: guideSpec[aes] ? {}
        type: scales[aes].tickType()
        mapping: layerMapping
        keys: poly.getLabel(layers, aes)
  _mergeAes: (domains, layers) ->
    merging = [] # array of {aes: __, mapped: ___}
    for aes of domains
      if aes in poly.const.noLegend then continue
      mapped = _.map layers, (layer) -> layer.mapping[aes]
      if not _.all mapped, _.isUndefined
        merged = false
        for m in merging # slow but ok, <7 aes anyways...
          if _.isEqual(m.mapped, mapped)
            m.aes.push(aes)
            merged = true
            break
        if not merged
          merging.push {aes: [aes], mapped: mapped}
    _.pluck merging, 'aes'
  getDimension: (dims) ->
    maxheight =  dims.height - dims.guideTop - dims.paddingTop
    maxwidth = 0
    offset = { x: 10, y : 0 } # initial spacing
    for legend in @legends
      d = legend.getDimension()
      if d.height + offset.y > maxheight
        offset.x += maxwidth + 5
        offset.y = 0
        maxwidth = 0
      if d.width > maxwidth
        maxwidth = d.width
      offset.y += d.height
    right: offset.x + maxwidth # no height
  render: (dims, renderer, offset={x:10, y:0}) ->
    legend.dispose(renderer()) for legend in @deletedLegends
    @deletedLegends = []
    legendDim =
      top: dims.paddingTop + dims.guideTop
      right: dims.width - dims.guideRight - dims.paddingRight
    maxwidth = 0
    maxheight = dims.height - dims.guideTop - dims.paddingTop
    for legend in @legends # assume position = right
      newdim = legend.getDimension()
      if newdim.height + offset.y > maxheight
        offset.x += maxwidth + 5
        offset.y = 0
        maxwidth = 0
      if newdim.width > maxwidth
        maxwidth = newdim.width
      realoffset =
        x: offset.x + legendDim.right
        y: offset.y + legendDim.top
      legend.render(renderer(realoffset, false, false))
      offset.y += newdim.height
  dispose: (renderer) ->
    legend.dispose(renderer()) for legend in @legends


class Legend extends poly.Guide
  TITLEHEIGHT: 15
  TICKHEIGHT: 12
  SPACING : 10
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
    color: sf.identity 'black'
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
    color: sf.identity 'black'
    text: text
    'text-anchor' : 'start'
  getDimension: () ->
    position: 'left'
    height: @height
    width: 15+@maxwidth
