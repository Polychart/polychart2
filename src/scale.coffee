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
  constructor: (guideSpec, domains, ranges) ->
    inspec = (a) -> guideSpec and guideSpec[a]? and guideSpec[a].scale?
    @guideSpec = guideSpec
    @factory =
      x : if inspec('x') then guideSpec.x.scale else poly.scale.linear()
      y : if inspec('y') then guideSpec.y.scale else poly.scale.linear()
    @ranges = ranges
    @setDomains domains
  setDomains: (domains) ->
    @domains = domains
    @domainx = @domains.x
    @domainy = @domains.y
  setRanges: (ranges) -> @ranges = ranges
  setXDomain: (d) -> @domainx = d; @getScaleFns()
  setYDomain: (d) -> @domainy = d; @getScaleFns()
  resetDomains: () ->
    @domainx = @domains.x
    @domainy = @domains.y
  getScaleFns: () ->
    @scales = {}
    if @domainx
      @scales.x = @factory.x.construct(@domainx, @ranges.x)
    if @domainy
      @scales.y = @factory.y.construct(@domainy, @ranges.y)
    @scales
  getAxes: () ->
    @getScaleFns()
    axes = {}
    getparams = (a) =>
      domain: @domains[a]
      factory: @factory[a]
      scale: @scales[a]
      guideSpec: if @guideSpec and @guideSpec[a] then @guideSpec[a] else {}
    if @factory.x and @domainx
      params = getparams 'x'
      params.domain = @domainx
      axes.x = poly.guide.axis params
    if @factory.y and @domainy
      params = getparams 'y'
      params.domain = @domainy
      axes.y = poly.guide.axis params
    axes
  getLegends: () ->

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
  _wrapper : (y) -> (val) ->
    space = 2
    if _.isObject(val)
      if value.t is 'scalefn'
        if value.f is 'upper' then return y(val+domain.bw) - space
        if value.f is 'lower' then return y(val) + space
        if value.f is 'middle' then return y(val+domain.bw/2)
      throw new poly.UnexpectedObject("Expected a value instead of an object")
    y(val)
class Linear extends PositionScale
  _constructNum: (domain) ->
    @_wrapper poly.linear(domain.min, @range.min, domain.max, @range.max)
  _constructCat: (domain) -> (x) -> 20
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
    ylin = linear(Math.sqrt domain.max, Math.sqrt domain.min)
    wrapper (x) -> ylin Math.sqrt(x)

class Brewer extends Scale
  _constructCat: (domain) ->

class Gradient extends Scale
  constructor: (params) -> {lower, upper} = params
  _constructCat: (domain) ->

class Gradient2 extends Scale
  constructor: (params) -> {lower, zero, upper} = params
  _constructCat: (domain) ->

class Shape extends Scale
  _constructCat: (domain) ->

class Identity extends Scale
  construct: (domain) -> (x) -> x

poly.scale.linear = (params) -> new Linear(params)
poly.scale.log = (params) -> new Log(params)


###
# EXPORT
###
@poly = poly
