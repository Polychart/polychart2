poly = @poly || {}

###
# CONSTANTS
###
aesthetics = poly.const.aes

###
# GLOBALS
###
poly.scale = {}

poly.scale.make = (guideSpec, domains, ranges) ->
  return new ScaleSet(guideSpec, domains, ranges)

class ScaleSet
  constructor: (tmpRanges, coord) ->
    # note that axes.x is the axis for the x-aesthetic. it may or ma NOT be
    # the x-axis displayed on the screen.
    @axes =
      x: poly.guide.axis coord.axisType('x') # polar?
      y: poly.guide.axis coord.axisType('y') # polar?
    @coord = coord
    @ranges = tmpRanges
    @legends = []
    @deletedLegends = []

  make: (guideSpec, domains, layers) ->
    @guideSpec = guideSpec
    @layers = layers
    @domains = domains
    @domainx = @domains.x
    @domainy = @domains.y
    @scales = @_makeScales(guideSpec, domains, @ranges)
    @reverse=
      x: @scales.x.finv
      y: @scales.y.finv
    @layerMapping = @_mapLayers layers

  setRanges: (ranges) ->
    @ranges = ranges
    @_makeXScale()
    @_makeYScale()
  setXDomain: (d) ->
    @domainx = d
    @_makeXScale()
  setYDomain: (d) ->
    @domainy = d
    @_makeYScale()
  resetDomains: () ->
    @domainx = @domains.x
    @domainy = @domains.y
    @_makeXScale()
    @_makeYScale()
  _makeXScale: () ->
    @scales.x.make(@domainx, @ranges.x)
  _makeYScale: () ->
    @scales.y.make(@domainy, @ranges.y)
  _makeScales : (guideSpec, domains, ranges) ->
    # this function contains information about default scales!
    specScale = (a) ->
      if guideSpec and guideSpec[a]? and guideSpec[a].scale?
        return guideSpec[a].scale
      return null
    scales = {}
    # x 
    scales.x = specScale('x') ? poly.scale.linear()
    scales.x.make(domains.x, ranges.x)
    # y
    scales.y = specScale('y') ? poly.scale.linear()
    scales.y.make(domains.y, ranges.y)
    # color
    if domains.color?
      if domains.color.type == 'cat'
        scales.color = specScale('color') ? poly.scale.color()
      else
        scales.color = specScale('color') ?
          poly.scale.gradient upper:'steelblue', lower:'red'
      scales.color.make(domains.color)
    # size
    if domains.size?
      scales.size = specScale('size') || poly.scale.area()
      scales.size.make(domains.size)
    # text
    scales.text = poly.scale.identity()
    scales.text.make()
    scales

  fromPixels: (start, end) ->
    {x,y} = @coord.getAes start, end, @reverse
    obj = {}
    for map in @layerMapping.x
      if map.type? and map.type == 'map'
        obj[map.value] = x
    for map in @layerMapping.y
      if map.type? and map.type == 'map'
        obj[map.value] = y
    obj

  getSpec : (a) -> if @guideSpec? and @guideSpec[a]? then @guideSpec[a] else {}
  makeAxes: () ->
    @axes.x.make
      domain: @domainx
      type: @scales.x.tickType()
      guideSpec: @getSpec 'x'
      titletext: poly.getLabel @layers, 'x'
    @axes.y.make
      domain: @domainy
      type: @scales.y.tickType()
      guideSpec: @getSpec 'y'
      titletext: poly.getLabel @layers, 'y'
    @axes
  renderAxes: (dims, renderer) ->
    @axes.x.render dims, renderer
    @axes.y.render dims, renderer

  _mapLayers: (layers) ->
    obj = {}
    for aes of @domains
      obj[aes] =
        _.map layers, (layer) ->
          if layer.mapping[aes]?
            { type: 'map', value: layer.mapping[aes]}
          else if layer.consts[aes]?
            { type: 'const', value: layer.const[aes]}
          else
            layer.defaults[aes]
    obj
  _mergeAes: (layers) ->
    merging = [] # array of {aes: __, mapped: ___}
    for aes of @domains
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

  makeLegends: (mapping) -> # ok, this will be a complex f'n. deep breath:
    # figure out which groups of aesthetics need to be represented
    aesGroups = @_mergeAes @layers

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
        domain: @domains[aes]
        guideSpec: @getSpec aes
        type: @scales[aes].tickType()
        mapping: @layerMapping
        titletext: poly.getLabel(@layers, aes)
    @legends
  renderLegends: (dims, renderer) ->
    # NOTE: if this is changed, change dim.coffee dimension calculation
    legend.remove(renderer) for legend in @deletedLegends
    @deletedLegends = []
    offset = { x: 0, y : 0 }
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
      legend.render dims, renderer, offset
      offset.y += newdim.height


###
# CLASSES
###


###
Scales here are objects that can construct functions that takes a value from
the data, and returns another value that is suitable for rendering an
attribute of that value.
###
class Scale
  constructor: (params) ->
    @f = null
  make: (domain) ->
    @domain = domain
    @sortfn = poly.domain.sortfn(domain)
    switch domain.type
      when 'num' then return @_makeNum()
      when 'date' then return @_makeDate()
      when 'cat' then return @_makeCat()
  _makeNum: () ->
    throw new poly.NotImplemented("_makeNum is not implemented")
  _makeDate: () ->
    throw new poly.NotImplemented("_makeDate is not implemented")
  _makeCat: () ->
    throw new poly.NotImplemented("_makeCat is not implemented")
  tickType: () ->
    switch @domain.type
      when 'num' then return @_tickNum @domain
      when 'date' then return @_tickDate @domain
      when 'cat' then return @_tickCat @domain
  _tickNum: () -> 'num'
  _tickDate: () -> 'date'
  _tickCat: () -> 'cat'
  _identityWrapper: (y) -> (x) ->
      if _.isObject(x) and x.t is 'scalefn'
        if x.f is 'identity' then return x.v
      y x

###
Position Scales for the x- and y-axes
###
class PositionScale extends Scale
  constructor: (params) ->
    @f = null
    @finv = null
  make: (domain, range) ->
    @range = range
    super(domain)
  _numWrapper: (domain, y) => (value) =>
    # NOTE: the below spacing makes sure that animation in polar coordinates
    # behave as expected. Test with polar bar charts to see...
    space = 0.001 * (if @range.max > @range.min then 1 else -1)
    if _.isObject(value)
      if value.t is 'scalefn'
        if value.f is 'identity' then return value.v
        if value.f is 'upper' then return y(value.v+domain.bw) - space
        if value.f is 'lower' then return y(value.v) + space
        if value.f is 'middle' then return y(value.v+domain.bw/2)
        if value.f is 'max' then return @range.max + value.v
        if value.f is 'min' then return @range.min + value.v
      throw new poly.UnexpectedObject("Expected a value instead of an object")
    y(value)
  _catWrapper: (step, y) => (value) =>
    space = 0.001 * (if @range.max > @range.min then 1 else -1)
    if _.isObject(value)
      if value.t is 'scalefn'
        if value.f is 'identity' then return value.v
        if value.f is 'upper' then return y(value.v) + step - space
        if value.f is 'lower' then return y(value.v) + space
        if value.f is 'middle' then return y(value.v) + step/2
        if value.f is 'max' then return @range.max + value.v
        if value.f is 'min' then return @range.min + value.v
      throw new poly.UnexpectedObject("wtf is this object?")
    y(value) + step/2

class Linear extends PositionScale
  _makeNum: () ->
    max = @domain.max + (@domain.bw ? 0)
    y = poly.linear(@domain.min, @range.min, max, @range.max)
    x = poly.linear(@range.min, @domain.min, @range.max, max)
    @f = @_numWrapper @domain, y
    @finv = (y1, y2) ->
      xs = [x(y1),x(y2)]
      {ge: _.min(xs), le: _.max(xs)}
  _makeDate: () -> @_makeNum()
  _makeCat: () ->
    step = (@range.max - @range.min) / @domain.levels.length
    y = (x) =>
      i = _.indexOf(@domain.levels, x)
      if i == -1 then null else @range.min + i*step
    x = (y1, y2) =>
      if y2 < y1 then tmp=y2; y2=y1; y1=tmp
      i1 = Math.floor(y1/step)
      i2 = Math.ceil(y2/step)
      {in: @domain.levels[i1..i2]}
    @f = @_catWrapper step, y
    @finv = x

class Log extends PositionScale
  _makeNum: () ->
    lg = Math.log
    ylin = poly.linear lg(@domain.min), @range.min, lg(@domain.max), @range.max
    @f = @_numWrapper (x) -> ylin lg(x)

    ylininv = poly.linear @range.min, lg(@domain.min), @range.max, lg(@domain.max)
    x = (y) -> Math.exp(ylininv(y))
    @finv = (y1, y2) ->
      xs = [x(y1),x(y2)]
      {ge: _.min(xs), le: _.max(xs)}
  _tickNum: () -> 'num-log'

###
Other, legend-type scales for the x- and y-axes
###
class Area extends Scale
  _makeNum: () => #range = [0, 1]
    min = if @domain.min == 0 then 0 else 1
    sq = Math.sqrt
    ylin = poly.linear sq(@domain.min), min, sq(@domain.max), 10
    @f = @_identityWrapper (x) -> ylin sq(x)

class Color extends Scale
  _makeCat: () => #TEMPORARY
    n = @domain.levels.length
    h = (v) => _.indexOf(@domain.levels, v) / n + 1/(2*n)
    @f = (value) => Raphael.hsl(h(value),0.5,0.5)
  _makeNum: () =>
    h = poly.linear @domain.min, 0, @domain.max, 1
    @f = (value) -> Raphael.hsl(0.5,h(value),0.5)

class Brewer extends Scale
  _makeCat: () ->

class Gradient extends Scale
  constructor: (params) ->
    {@lower, @upper} = params
  _makeNum: () =>
    lower = Raphael.color(@lower)
    upper = Raphael.color(@upper)
    r = poly.linear @domain.min, lower.r, @domain.max, upper.r
    g = poly.linear @domain.min, lower.g, @domain.max, upper.g
    b = poly.linear @domain.min, lower.b, @domain.max, upper.b
    @f =
      @_identityWrapper (value) => Raphael.rgb r(value), g(value), b(value)

class Gradient2 extends Scale
  constructor: (params) -> {lower, zero, upper} = params
  _makeCat: () =>

class Shape extends Scale
  _makeCat: () ->

class Identity extends Scale
  make: () ->
    @sortfn = (x) -> x
    @f = @_identityWrapper (x) -> x

poly.scale = _.extend poly.scale,
  linear : (params) -> new Linear(params)
  log : (params) -> new Log(params)
  area : (params) -> new Area(params)
  color : (params) -> new Color(params)
  gradient : (params) -> new Gradient(params)
  identity: (params) -> new Identity(params)


###
# EXPORT
###
@poly = poly

