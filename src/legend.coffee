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

poly.guide.legend = (aes, position) ->
  if position in ['left', 'right']
    new VerticalLegend(aes)
  else
    new HorizontalLegend(aes)

class Legends extends poly.GuideSet
  constructor: () ->
    @legends = []
    @deletedLegends = []
  make: (params) ->
    {domains, layers, guideSpec, scales, layerMapping, @position, dims} = params
    @postion ?= 'right'
    if @position is 'none' then return
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
      @legends.push poly.guide.legend aes, @position
    # make each legend
    for legend in @legends
      aes = legend.aes[0]
      legend.make
        domain: domains[aes]
        position: @position
        guideSpec: guideSpec[aes] ? {}
        type: scales[aes].tickType()
        mapping: layerMapping
        keys: poly.getLabel(layers, aes)
        dims: dims
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
    retobj = {}
    if @position in ['left', 'right']
      retobj[@position] = @_leftrightWidth(dims)
    else if @position in ['top', 'bottom']
      retobj[@position] = @_topbottomHeight(dims)
    retobj
  _leftrightWidth: (dims) ->
    maxheight =  dims.chartHeight
    maxwidth = 0
    offset = { x: 10, y : 0 } # initial spacing
    for legend in @legends
      d = legend.getDimension(dims)
      if d.height + offset.y > maxheight
        offset.x += maxwidth + 5
        offset.y = 0
        maxwidth = 0
      if d.width > maxwidth
        maxwidth = d.width
      offset.y += d.height
    offset.x + maxwidth
  _topbottomHeight: (dims) ->
    maxwidth = dims.chartWidth
    height = 10 # initial height
    for legend in @legends
      d = legend.getDimension(dims)
      height += d.height + 10 # spacing
    height

  render: (dims, renderer, offset) ->
    legend.dispose(renderer) for legend in @deletedLegends
    @deletedLegends = []
    if @position is 'left' or @position is 'right'
      @_renderV(dims, renderer, offset)
    else if @position is 'top' or @position is 'bottom'
      @_renderH(dims, renderer, offset)
  _renderV: (dims, renderer, offset) ->
    legendDim =
      top: dims.paddingTop + dims.guideTop
      left:
        if @position is 'left'
          dims.paddingLeft
        else
          dims.width - dims.guideRight - dims.paddingRight
    maxwidth = 0
    maxheight = dims.height - dims.guideTop - dims.paddingTop
    offsetY = 10 # initial
    offsetX = if @position is 'right' then offset.right else 0
    for legend in @legends # assume position = right
      newdim = legend.getDimension(dims)
      if newdim.height + offset.y > maxheight
        offsetX += maxwidth + 5
        offsetY = 0
        maxwidth = 0
      if newdim.width > maxwidth
        maxwidth = newdim.width
      realoffset =
        x: offsetX + legendDim.left
        y: offsetY + legendDim.top
      legend.render(renderer(realoffset, false, false), maxwidth)
      offsetY += newdim.height
  _renderH: (dims, renderer, offset) ->
    legendDim =
      left: dims.paddingLeft
      top:
        if @position is 'top'
          dims.paddingTop
        else
          dims.height - dims.guideBottom - dims.paddingBottom
    realoffset =
      x: legendDim.left
      y:
        if @position is 'top'
          offset.top + legendDim.top
        else
          offset.bottom + legendDim.top + 10
    for legend in @legends
      newdim = legend.getDimension(dims)
      legend.render(renderer(realoffset, false, false))
      realoffset.y += newdim.height + 10 # spacing
  dispose: (renderer) ->
    legend.dispose(renderer) for legend in @legends


class Legend extends poly.Guide
  TITLEHEIGHT: 15
  TICKHEIGHT: 12
  SPACING : 10
  constructor: (@aes) ->
    @geometry = new poly.Geometry('guide')
  make: (params) ->
    {domain, type, guideSpec, @mapping, @position, keys} = params
    @titletext = guideSpec.title ? keys
    @ticks = poly.tick.make domain, guideSpec, type
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
  _makeTitle: (text, offset={x:0, y:0}) ->
    type: 'text'
    x : sf.identity offset.x + 5
    y : sf.identity offset.y
    color: sf.identity 'black'
    text: text
    'text-anchor' : 'start'
  _makeLabel: (tick, offset) ->
    if not offset
      offset =
        x: 0
        y: (15+tick.index*12)
    type: 'text'
    x : sf.identity offset.x + 20
    y : sf.identity offset.y + 1
    color: sf.identity 'black'
    text: tick.value
    'text-anchor' : 'start'
  _makeTick: (tick, offset) =>
    if not offset
      offset =
        x : 0
        y : (15+tick.index*12)
    obj =
      type: 'circle'
      x : sf.identity offset.x + 10
      y : sf.identity offset.y
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
        # take the global default value
        obj[aes] = sf.identity poly.const.defaults[aes]
    if _.isObject(obj.size)
      obj.size = sf.identity 5 # not negotiable
    obj
  _makeEvtData: (tick) =>
    evtData = {}
    for aes, value of @mapping
      for v in value
        if aes in @aes and v.type is 'map'
          evtData[v.value] = tick.evtData
    evtData

class VerticalLegend extends Legend
  make: (params) ->
    super(params)
    @height = @TITLEHEIGHT + @SPACING + @TICKHEIGHT*_.size @ticks
    titleWidth = poly.strSize @titletext
    tickWidth = _.max _.map @ticks, (t) -> poly.strSize t.value
    @maxwidth = Math.max titleWidth, tickWidth
  getDimension: () ->
    position: @position
    height: @height
    width: 15+@maxwidth

class HorizontalLegend extends Legend
  TICKSPACING : 25
  make: (params) ->
    super(params)
    @maxwidth = params.dims.width
    @height = @TITLEHEIGHT + @SPACING
    width = 0
    @height += @TICKHEIGHT # first row
    for t in @ticks
      currWidth = poly.strSize(t.value) + @TICKSPACING
      if (width + currWidth) < @maxwidth
        width += currWidth
      else
        @height += @TICKHEIGHT # additional rows
        width = currWidth
    null
  calculate: () ->
    geoms = {}
    geoms['title'] = marks: 0: @_makeTitle(@titletext)
    offset = {x: 0, y: @TITLEHEIGHT}
    for key, tick of @ticks
      marks = {}
      marks.tick = @_makeTick(tick, offset)
      marks.text = @_makeLabel(tick, offset)
      evtData = @_makeEvtData(tick, offset)
      geoms[key] =
        marks: marks
        evtData: evtData
      currWidth = poly.strSize(tick.value) + @TICKSPACING
      if (offset.x + currWidth) < @maxwidth
        offset.x += currWidth
      else
        offset.x = 0
        offset.y += @TICKHEIGHT
    geoms
  getDimension: () ->
    position: @position
    height: @height
    width: 'all'

