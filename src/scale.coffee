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
  constructor: (tmpRanges) ->
    @axes = {
      x: poly.guide.axis 'x'
      y: poly.guide.axis 'y'
    }
    @ranges = tmpRanges
    @legends = []

  make: (guideSpec, domains, layers) ->
    @guideSpec = guideSpec
    @layers = layers
    @domains = domains
    @domainx = @domains.x
    @domainy = @domains.y
    @factory = @_makeFactory(guideSpec, domains, @ranges)
    @scales = @getScaleFns()
  setRanges: (ranges) ->
    @ranges = ranges
    @scales = @getScaleFns()
  setXDomain: (d) ->
    @domainx = d
    @scales.x = @_makeXScale()
  setYDomain: (d) ->
    @domainy = d
    @scales.y = @_makeYScale()
  resetDomains: () ->
    @domainx = @domains.x
    @domainy = @domains.y
    @scales.x = @_makeXScale()
    @scales.y = @_makeYScale()

  getScaleFns: () ->
    scales = {}
    if @domainx then scales.x = @_makeXScale()
    if @domainy then scales.y = @_makeYScale()
    _.each ['color', 'size'], (aes) =>
      if @domains[aes] then scales[aes] = @_makeScale aes
    scales
  _makeXScale: () -> @factory.x.construct(@domainx, @ranges.x)
  _makeYScale: () -> @factory.y.construct(@domainy, @ranges.y)
  _makeScale: (aes) -> @factory[aes].construct(@domains[aes])

  makeAxes: () ->
    spec = (a) -> if @guideSpec and @guideSpec[a] then @guideSpec[a] else {}
    @axes.x.make {
      domain: @domainx
      factory: @factory.x
      guideSpec: spec('x')
    }
    @axes.y.make {
      domain: @domainy
      factory: @factory.y
      guideSpec: spec('y')
    }
    @axes
  makeLegends: (mapping) ->
    # we'll have to be able to change this...
    @legends ?= @_makeLegends()

  _makeFactory : (guideSpec, domains, ranges) ->
    specScale = (a) ->
      if guideSpec and guideSpec[a]? and guideSpec[a].scale?
        return guideSpec.x.scale
      return null
    factory =
      x : specScale('x') ? poly.scale.linear()
      y : specScale('y') ? poly.scale.linear()
    if domains.color?
      if domains.color.type == 'cat'
        factory.color = specScale('color') ? poly.scale.color()
      else
        factory.color = specScale('color') ?
          poly.scale.gradient upper:'steelblue', lower:'red'
    if domains.size?
      factory.size = specScale('size') || poly.scale.area()
    factory

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
  guide: () -> # get a guide out of this
  construct: (domain) ->
    switch domain.type
      when 'num' then return @_constructNum domain
      when 'date' then return @_constructDate domain
      when 'cat' then return @_constructCat domain
  _constructNum: (domain) ->
    throw new poly.NotImplemented("_constructNum is not implemented")
  _constructDate: (domain) ->
    throw new poly.NotImplemented("_constructDate is not implemented")
  _constructCat: (domain) ->
    throw new poly.NotImplemented("_constructCat is not implemented")
  tickType: (domain) ->
    switch domain.type
      when 'num' then return @_tickNum domain
      when 'date' then return @_tickDate domain
      when 'cat' then return @_tickCat domain
  _tickNum: () -> 'num'
  _tickDate: () -> 'date'
  _tickCat: () -> 'cat'

###
Position Scales for the x- and y-axes
###
class PositionScale extends Scale
  construct: (domain, range) ->
    @range = range
    super(domain)
  _wrapper : (y) -> (value) ->
    space = 2
    if _.isObject(value)
      if value.t is 'scalefn'
        if value.f is 'identity' then return value.v
        if value.f is 'upper' then return y(value.v+domain.bw) - space
        if value.f is 'lower' then return y(value.v) + space
        if value.f is 'middle' then return y(value.v+domain.bw/2)
      throw new poly.UnexpectedObject("Expected a value instead of an object")
    y(value)

class Linear extends PositionScale
  _constructNum: (domain) ->
    @_wrapper poly.linear(domain.min, @range.min, domain.max, @range.max)
  _wrapper2 : (step, y) -> (value) ->
    space = 2
    if _.isObject(value)
      if value.t is 'scalefn'
        if value.f is 'identity' then return value.v
        if value.f is 'upper' then return y(value.v) + step - space
        if value.f is 'lower' then return y(value.v) + space
        if value.f is 'middle' then return y(value.v) + step/2
      throw new poly.UnexpectedObject("wtf is this object?")
    y(value) + step/2
  _constructCat: (domain) ->
    step = (@range.max - @range.min) / domain.levels.length
    y = (x) =>
      i = _.indexOf(domain.levels, x)
      if i == -1 then null else @range.min + i*step
    @_wrapper2 step, y

class Log extends PositionScale
  _constructNum: (domain) ->
    lg = Math.log
    ylin = poly.linear lg(domain.min), @range.min, lg(domain.max), @range.max
    @_wrapper (x) -> ylin lg(x)
  _tickNum: () -> 'num-log'

###
Other, legend-type scales for the x- and y-axes
###
class Area extends Scale
  _constructNum: (domain) -> #range = [0, 1]
    min = if domain.min == 0 then 0 else 1
    sq = Math.sqrt
    ylin = poly.linear sq(domain.min), min, sq(domain.max), 10
    (x) -> ylin sq(x)

class Color extends Scale
  _constructCat: (domain) -> #TEMPORARY
    n = domain.levels.length
    h = (v) -> _.indexOf(domain.levels, v) / n + 1/(2*n)
    (value) -> Raphael.hsl(h(value),0.5,0.5)
  _constructNum: (domain) ->
    h = poly.linear domain.min, 0, domain.max, 1
    (value) -> Raphael.hsl(0.5,h(value),0.5)

class Brewer extends Scale
  _constructCat: (domain) ->

class Gradient extends Scale
  constructor: (params) ->
    {@lower, @upper} = params
  _constructNum: (domain) =>
    lower = Raphael.color(@lower)
    upper = Raphael.color(@upper)
    r = poly.linear domain.min, lower.r, domain.max, upper.r
    g = poly.linear domain.min, lower.g, domain.max, upper.g
    b = poly.linear domain.min, lower.b, domain.max, upper.b
    (value) => Raphael.rgb r(value), g(value), b(value)

class Gradient2 extends Scale
  constructor: (params) -> {lower, zero, upper} = params
  _constructCat: (domain) ->

class Shape extends Scale
  _constructCat: (domain) ->

class Identity extends Scale
  construct: (domain) -> (x) -> x

poly.scale = _.extend poly.scale,
  linear : (params) -> new Linear(params)
  log : (params) -> new Log(params)
  area : (params) -> new Area(params)
  color : (params) -> new Color(params)
  gradient : (params) -> new Gradient(params)


###
# EXPORT
###
@poly = poly

