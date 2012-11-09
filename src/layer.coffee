poly = @poly || {}

##########
# CONSTANTS
##########

aesthetics = poly.const.aes # list of aesthetics
sf = poly.const.scaleFns    # list of scale functions
defaults = {                # global default values for aesthetics
  'x': sf.novalue()
  'y': sf.novalue()
  'color': 'steelblue'
  'size': 1
  'opacity': 0.7
  'shape': 1
}

##########
# GLOBALS
##########
poly.layer = {}

###
Turns a 'non-strict' layer spec to a strict one. Specifically, the function
(1) wraps aes mapping defined by a string in an object: "col" -> {var: "col"}
(2) puts all the level/min/max filtering into the "filter" group
See the layer spec definition for more information.
###
poly.layer.toStrictMode = (spec) ->
  # wrap all aesthetic in object
  _.each aesthetics, (aes) ->
    if spec[aes] and _.isString spec[aes] then spec[aes] = { var: spec[aes] }
  spec

###
Public interface to making different layer types.
###
poly.layer.make = (layerSpec, strictmode) ->
  switch layerSpec.type
    when 'point' then return new Point(layerSpec, strictmode)
    when 'line' then return new Line(layerSpec, strictmode)
    when 'bar' then return new Bar(layerSpec, strictmode)

###########
# CLASSES
###########

###
Base class for all layers
###
class Layer
  # mostly just read and interpret the the spec
  constructor: (layerSpec, strict) ->
    @strict = strict
    @spec = poly.layer.toStrictMode layerSpec
    @defaults = defaults
    @mapping = {}     # aesthetic mappings
    @consts = {}      # constants supplied by the spec
    for aes in aesthetics
      if @spec[aes]
        if @spec[aes].var then @mapping[aes] = @spec[aes].var
        if @spec[aes].const then @consts[aes] = @spec[aes].const
  # processing the data: calculate statistics and layer level calculations
  calculate: (callback) =>
    @dataprocess = new poly.DataProcess @spec #TODO: remove new
    @dataprocess.process (statData, metaData) =>
      @statData = statData
      @meta = metaData
      @_calcGeoms()
      callback()
  # layer level calculation resulting in geometric objects
  _calcGeoms: () -> @geoms = {}
  # helper for getting the value of a particular aesthetic from an item
  _getValue: (item, aes) ->
    if @mapping[aes] then return item[@mapping[aes]]
    if @consts[aes] then return sf.identity(@consts[aes])
    return sf.identity(@defaults[aes])

class Point extends Layer
  _calcGeoms: () ->
    @geoms = _.map @statData, (item) =>
      evtData = {}
      _.each item, (v, k) ->
        evtData[k] = { in : [v] }
      marks: [
        type: 'point'
        x: @_getValue item, 'x'
        y: @_getValue item, 'y'
        color: @_getValue item, 'color'
      ]
      evtData: evtData

class Line extends Layer
  _calcGeoms: () ->
    # @ys = if @mapping['y'] then _.uniq _.pluck @statData, @mapping['y'] else []
    # TODO: fill in missing points
    group = (@mapping[k] for k in _.without(_.keys(@mapping), 'x', 'y'))
    datas = poly.groupBy @statData, group
    @geoms = _.map datas, (data) => # produce one line per group
      evtData = {}
      _.each group, (key) -> evtData[key] = { in : [data[0][key]] }
      marks: [
        type: 'line'
        x: (@_getValue item, 'x' for item in data)
        y: (@_getValue item, 'y' for item in data)
        color: @_getValue data[0], 'color'
      ]
      evtData: evtData

class Bar extends Layer
  _calcGeoms: () ->
    # first do stacking calculation (assuming position=stack)
    group = if @mapping.x? then [@mapping.x] else []
    datas = poly.groupBy @statData , group
    _.each datas, (data) => # TODO: add sorting?
      tmp = 0
      yval = if @mapping.y? then ((item) => item[@mapping.y]) else (item) -> 0
      _.each data, (item) ->
        item.$lower = tmp
        tmp += yval(item)
        item.$upper = tmp
    @geoms = _.map @statData, (item) =>
      evtData = {}
      _.each item, (v, k) -> if k isnt 'y' then evtData[k] = { in: [v] }
      marks: [
        type: 'rect'
        x1: sf.lower @_getValue(item, 'x')
        x2: sf.upper @_getValue(item, 'x')
        y1: item.$lower
        y2: item.$upper
        fill: @_getValue item, 'color'
      ]
###
# EXPORT
###
@poly = poly
