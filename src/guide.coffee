sf = poly.const.scaleFns

class Axis extends poly.Guide
  constructor: () ->
    @line = null
    @title = null
    @position = 'none'
    @titletext = null
    @ticks = {}
    @pts = {}
  make: (params) =>
    {domain, type, guideSpec, key} = params
    # options
    option = (item, def) => guideSpec[item] ? def
    # position
    @position = option('position', @defaultPosition)
    if @position not in @validPositions
      throw poly.error.defn "X-axis position can't be #{@position}."
    @titletext = option('title', key)
    @renderTick = option('renderTick', true)
    @renderGrid = option('renderGrid', true)
    @renderLabel = option('renderLabel', true)
    @renderLine = option('renderLine', true)
    # ticks
    @ticks = poly.tick.make domain, guideSpec, type
    @maxwidth = _.max _.map @ticks, (t) -> poly.strSize t.value
    @maxwidth = Math.max @maxwidth, 0
  render: (axisDim, coord, renderer, override) =>
    if @position is "none" then return
    override ?= {}
    # NOTE: coords are included for making guide rendering for polar coordinates
    # managable. Ideally it should NOT be here and is rather a hack.
    @coord = coord
    axisDim.centerx = axisDim.left + axisDim.width/2
    axisDim.centery = axisDim.top + axisDim.height/2
    axisDim.radius = Math.min(axisDim.width, axisDim.height)/2 -10
    if @renderLine
      if @line? then renderer.remove @line
      if not (override.renderLine is false)
        @line = @_renderline renderer, axisDim
      else
        @line = null
    {deleted, kept, added} = poly.compare _.keys(@pts), _.keys(@ticks)
    newpts = {}
    for t in kept
      newpts[t] = @_modify renderer, @pts[t], @ticks[t], axisDim, override
    for t in added
      newpts[t] = @_add renderer, @ticks[t], axisDim, override
    for t in deleted
      @_delete renderer, @pts[t], override
    @pts = newpts
    @rendered = true
  _add: (renderer, tick, axisDim, override) =>
    obj = {}
    if @renderTick and (override.renderTick ? true)
      obj.tick = renderer.add @_makeTick(axisDim, tick)
    if @renderLabel and (override.renderLabel ? true)
      obj.text = renderer.add @_makeLabel(axisDim, tick)
    if @renderGrid and (override.renderGrid ? true)
      obj.grid = renderer.add @_makeGrid(axisDim, tick)
      obj.grid.toBack()
    obj
  _delete: (renderer, pt) ->
    if pt.tick?
      renderer.remove pt.tick
    if pt.text?
      renderer.remove pt.text
    if pt.grid?
      renderer.remove pt.grid
  _modify: (renderer, pt, tick, axisDim, override) =>
    obj = {}
    if @renderTick
      if not (override.renderTick ? true)
        renderer.remove pt.tick
      else
        obj.tick = renderer.animate pt.tick, @_makeTick(axisDim, tick)
    if @renderLabel
      if not (override.renderLabel ? true)
        renderer.remove pt.text
      else
        obj.text = renderer.animate pt.text, @_makeLabel(axisDim, tick)
    if @renderGrid
      if not (override.renderGrid ? true)
        renderer.remove pt.grid
      else
        obj.grid = renderer.animate pt.grid, @_makeGrid(axisDim, tick)
        obj.grid.toBack()
    obj
  remove: (renderer) ->
    for pt in pts
      @_delete pt
    pts = {}
  _renderline : () -> throw poly.error.impl()
  _makeTick : (obj) ->
    if !obj then throw poly.error.impl()
    obj.type = 'path'
    obj.stroke = sf.identity 'black'
    obj
  _makeLabel: (obj) ->
    if !obj then throw poly.error.impl()
    obj.type = 'text'
    obj
  _makeGrid: (obj) ->
    if !obj then throw poly.error.impl()
    obj.stroke = '#CCC'
    obj['stroke-dasharray'] = '- '
    obj['stroke-dashoffset'] = 3
    obj

class Legend extends poly.Guide
  TITLEHEIGHT: 15
  TICKHEIGHT: 12
  SPACING: 10
  constructor: (@aes) ->
    @rendered = false
    @title = null
    @ticks = {}
    @pts = {}
  make: (params) =>
    {domain, type, guideSpec, @mapping, keys} = params
    @titletext = guideSpec.title ? keys
    @ticks = poly.tick.make domain, guideSpec, type
    @height = @TITLEHEIGHT + @SPACING + @TICKHEIGHT*_.size @ticks
    titleWidth = poly.strSize @titletext
    tickWidth = _.max _.map @ticks, (t) -> poly.strSize t.value
    @maxwidth = Math.max titleWidth, tickWidth
  render: (dim, renderer, offset) -> # assume position = RIGHT
    legendDim =
      top: dim.paddingTop + dim.guideTop + offset.y
      right: dim.width - dim.guideRight - dim.paddingRight + offset.x
      width: dim.guideRight
      height: dim.chartHeight
    if @title?
      @title = renderer.animate @title, @_makeTitle(legendDim, @titletext)
    else
      @title = renderer.add @_makeTitle(legendDim, @titletext)
    {deleted, kept, added} = poly.compare _.keys(@pts), _.keys(@ticks)
    newpts = {}
    for t in deleted
      @_delete renderer, @pts[t]
    for t in kept
      newpts[t] = @_modify renderer, @pts[t], @ticks[t], legendDim
    for t in added
      newpts[t] = @_add renderer, @ticks[t], legendDim
    @pts = newpts
  dispose: (renderer) ->
    for i, pt of @pts
      @_delete renderer, pt
    renderer.remove @title
    @title = null
    @pts = {}
  _add: (renderer, tick, legendDim) ->
    obj = {}
    {tickObj, evtData} = @_makeTick(legendDim, tick)
    obj.tick = renderer.add tickObj, evtData
    obj.text = renderer.add @_makeLabel(legendDim, tick)
    obj
  _delete: (renderer, pt) ->
    renderer.remove pt.tick
    renderer.remove pt.text
  _modify: (renderer, pt, tick, legendDim) ->
    obj = []
    {tickObj, evtData} = @_makeTick(legendDim, tick)
    obj.tick = renderer.animate pt.tick, tickObj, evtData
    obj.text = renderer.animate pt.text, @_makeLabel(legendDim, tick)
    obj
  _makeLabel: (legendDim, tick) ->
    type: 'text'
    x : sf.identity legendDim.right + 15
    y : sf.identity legendDim.top + (15+tick.index*12) + 1
    text: tick.value
    'text-anchor' : 'start'
  _makeTick: (legendDim, tick) =>
    obj =
      type: 'circle'
      x : sf.identity legendDim.right + 7
      y : sf.identity legendDim.top + (15+tick.index*12)
      color: sf.identity 'steelblue' # can be overwritten
    evtData = {}
    for aes, value of @mapping
      if aes in poly.const.noLegend then continue
      value = value[0] # just use the first for now?
      if aes in @aes
        obj[aes] = tick.location
        if value.type is 'map'
          evtData[value.value] = tick.evtData
      else if value.type? and value.type == 'const'
        # take assigned const value of first layer
        obj[aes] = sf.identity value.value
      else if not _.isObject value
        # take the layer default value
        obj[aes] = sf.identity value
      else
        # take teh global default value
        obj[aes] = sf.identity poly.const.defaults[aes]
    if not ('size' in @aes) # override size so we can see!
      obj.size = sf.identity 5
    tickObj: obj
    evtData: evtData
  _makeTitle: (legendDim, text) ->
    type: 'text'
    x : sf.identity legendDim.right + 5
    y : sf.identity legendDim.top
    text: text
    'text-anchor' : 'start'
  getDimension: () ->
    position: 'left'
    height: @height
    width: 15+@maxwidth

class Title extends poly.Guide
  constructor: () ->
    @position = 'none'
    @titletext = null
    @title = null
  make: (params) =>
    {guideSpec, title, position} = params
    option = (item, def) => guideSpec[item] ? def
    @titletext = option('title', title)
    @position = option('position', position) ? @defaultPosition
    if @position is 'out' then @position = 'bottom'
  render: (renderer, dim, offset) =>
    if @position isnt 'none'
      if @title?
        renderer.remove @title
      @title = renderer.add @_makeTitle(dim, offset)
    else if @title?
      renderer.remove @title
  dispose: (renderer) ->
    renderer.remove @title
    @title = null
  _makeTitle: () -> throw poly.error.impl()
  getDimension: () ->
    offset = {}
    if @position isnt 'none'
      offset[@position] = 10
    offset

class TitleH extends Title
  defaultPosition: 'bottom'
  _makeTitle: (dim, offset) ->
    y =
      if @position is 'top'
        dim.paddingTop + dim.guideTop - (offset.top ? 0) - 2
      else
        dim.height - dim.paddingBottom - dim.guideBottom + (offset.bottom ? 0)
    x = dim.paddingLeft + dim.guideLeft + (dim.width - dim.paddingLeft - dim.guideLeft - dim.paddingRight - dim.guideRight) / 2
    type: 'text'
    x : sf.identity x
    y : sf.identity y
    text: @titletext
    'text-anchor' : 'middle'

class TitleV extends Title
  defaultPosition: 'left'
  _makeTitle: (dim, offset) ->
    x =
      if @position is 'left'
        dim.paddingLeft + dim.guideLeft - (offset.left ? 0) - 7
      else
        dim.width - dim.paddingRight - dim.guideRight + (offset.right ? 0)
    y = dim.paddingTop + dim.guideTop + (dim.height - dim.paddingTop - dim.guideTop - dim.paddingBottom - dim.guideBottom) / 2
    type: 'text'
    x : sf.identity x
    y : sf.identity y
    text: @titletext
    'text-anchor' : 'middle'
    transform : 'r270'

class TitleMain extends Title
  _makeTitle: (dim, offset) ->
    x = dim.width / 2
    y = 20
    type: 'text'
    x : sf.identity x
    y : sf.identity y
    text: @titletext
    'font-size' : '13px'
    'font-weight' : 'bold'
    'text-anchor' : 'middle'

class TitleFacet extends Title
  make: (params) =>
    {title} = params
    @titletext = title
  render: (renderer, dim, offset) => # note, this "offset" is a FACET offset!
    if @title?
      @title = renderer.animate @title, @_makeTitle(dim, offset)
    else
      @title = renderer.add @_makeTitle(dim, offset)
  _makeTitle: (dim, offset) ->
    type: 'text'
    x : sf.identity offset.x + dim.chartWidth/2
    y : sf.identity offset.y - 7
    text: @titletext
    'text-anchor' : 'middle'

poly.guide ?= {}
poly.guide.title = (type) ->
  if type in ['y', 'r']
    new TitleV()
  else if type is 'main'
    new TitleMain()
  else if type is 'facet'
    new TitleFacet()
  else # ['x', 't']
    new TitleH()

poly.guide.legend = (aes) -> return new Legend(aes)
