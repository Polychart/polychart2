poly = @poly || {}

###
# CONSTANTS
###
aesthetics = poly.const.aes

###
# GLOBALS
###
poly.scale = {}

poly.scale.make = (guideSpec, domains, range) ->
  scales = {}
  axis = {}
  # x axis
  if domains.x
    axis.s = poly.scale.linear() # TODO: read from spec
    scales.x = axis.s.make(domains.x, range.x)
  # y axis
  if domains.y
    axis.s = poly.scale.linear()# TODO: read from spec
    scales.y = axis.s.make(domains.y, range.y)
  # How to scales work?
  [axis, scales]

###
# CLASSES
###
class Scale
  constructor: (params) ->
  construct: (domain) ->
    switch domain.type
      when 'num' then return @_constructNum domain
      when 'date' then return @_constructDate domain
      when 'cat' then return @_constructCat domain
  _constructNum: (domain) -> console.log 'wtf not impl'
  _constructDate: (domain) -> console.log 'wtf not impl'
  _constructCat: (domain) -> console.log 'wtf not impl'

class Axis extends Scale
  make: (domain, range) ->
    @originalDomain = domain
    @range = range
    @construct domain
  remake: (domain) ->
    @construct domain
  # wrapper for provideing scalefns
  wrapper : (y) -> (val) ->
    space = 2
    if _.isObject(val)
      if value.t is 'scalefn'
        if value.f is 'upper' then return y(val+domain.bw) - space
        if value.f is 'lower' then return y(val) + space
        if value.f is 'middle' then return y(val+domain.bw/2)
      console.log 'wtf'
    y(val)
class Linear extends Axis
  _constructNum: (domain) ->
    @wrapper poly.linear(domain.min, @range.min, domain.max, @range.max)
class Log extends Axis
  _constructNum: (domain) ->
    lg = Math.log
    ylin = poly.linear lg(domain.min), @range.min, lg(domain.max), @range.max
    @wrapper (x) -> ylin lg(x)


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
