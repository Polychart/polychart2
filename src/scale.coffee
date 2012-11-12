poly = @poly || {}

###
# CONSTANTS
###
aesthetics = poly.const.aes

###
# GLOBALS
###
poly.scale = {}

poly.scale.make = (guideSpec, domains) ->
  return new ScaleSet(guideSpec, domains)

class ScaleSet
  constructor: (guideSpec, domains) ->
    inspec = (a) -> guideSpec and guideSpec[a]? and guideSpec[a].scale?
    @factory =
      x : if inspec('x') then guideSpec.x.scale else poly.scale.linear()
      y : if inspec('y') then guideSpec.y.scale else poly.scale.linear()
    @domains = domains
    @domainx = @domains.x
    @domainy = @domains.y
  getScaleFns: (ranges) ->
    @ranges = ranges
    @scales = {}
    if @domainx
      @scales.x = @factory.x.construct(@domainx, @ranges.x)
    if @domainy
      @scales.y = @factory.y.construct(@domainy, @ranges.y)
    return @scales
  setXDomain: (d) -> @domainsx = d
  setYDomain: (d) -> @domainsy = d
  resetDomains: () ->
    @domainx = @domains.x
    @domainy = @domains.y
  getAxes: () ->
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
  _constructNum: (domain) -> console.log 'wtf not impl'
  _constructDate: (domain) -> console.log 'wtf not impl'
  _constructCat: (domain) -> console.log 'wtf not impl'

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
      console.log 'wtf'
    y(val)
class Linear extends PositionScale
  _constructNum: (domain) ->
    @_wrapper poly.linear(domain.min, @range.min, domain.max, @range.max)
class Log extends PositionScale
  _constructNum: (domain) ->
    lg = Math.log
    ylin = poly.linear lg(domain.min), @range.min, lg(domain.max), @range.max
    @_wrapper (x) -> ylin lg(x)

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
