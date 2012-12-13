poly = @poly || {}

###
# CONSTANTS
###
aesthetics = poly.const.aes

###
# GLOBALS
###
poly.scale =
  linear : (params) -> new Linear(params)
  log : (params) -> new Log(params)
  area : (params) -> new Area(params)
  color : (params) -> new Color(params)
  gradient : (params) -> new Gradient(params)
  identity: (params) -> new Identity(params)
  opacity: (params) -> new Opacity(params)

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
  _dateWrapper: (domain, y) => (value) =>
    space = 0.001 * (if @range.max > @range.min then 1 else -1)
    if _.isObject(value)
      if value.t is 'scalefn'
        if value.f is 'identity' then return value.v
        if value.f is 'upper'
          v = moment.unix(value.v).endOf(domain.bw).unix()
          return y(v) - space
        if value.f is 'lower'
          v = moment.unix(value.v).startOf(domain.bw).unix()
          return y(v) + space
        if value.f is 'middle'
          v1 = moment.unix(value.v).endOf(domain.bw).unix()
          v2 = moment.unix(value.v).startOf(domain.bw).unix()
          return y(v1/2 + v2/2)
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
    y = poly.linear(@domain.min, @range.min, @domain.max, @range.max)
    x = poly.linear(@range.min, @domain.min, @range.max, @domain.max)
    @f = @_numWrapper @domain, y
    @finv = (y1, y2) ->
      xs = [x(y1),x(y2)]
      {ge: _.min(xs), le: _.max(xs)}
  _makeDate: () ->
    y = poly.linear(@domain.min, @range.min, @domain.max, @range.max)
    x = poly.linear(@range.min, @domain.min, @range.max, @domain.max)
    @f = @_dateWrapper @domain, y
    @finv = (y1, y2) ->
      xs = [x(y1),x(y2)]
      {ge: _.min(xs), le: _.max(xs)}
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

class Opacity extends Scale
  _makeNum: () => #range = [0, 1]
    min = if @domain.min == 0 then 0 else 0.1
    max = 1
    @f = @_identityWrapper poly.linear(@domain.min, min, @domain.max, max)

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

###
# EXPORT
###
@poly = poly

