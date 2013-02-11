sf = poly.const.scaleFns

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
