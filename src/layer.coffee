poly = @poly || {}

###
# CONSTANTS
###
aesthetics = poly.const.aes
sf = poly.const.scaleFns
defaults = {
  'x': sf.novalue()
  'y': sf.novalue()
  'color': 'steelblue'
  'size': 1
  'opacity': 0.7
  'shape': 1
}

###
# GLOBALS
###
poly.layer = {}

# wrap aes mapping defined by a string with an object
poly.layer.toStrictMode = (spec) ->
  _.each aesthetics, (aes) ->
    if spec[aes] and _.isString spec[aes] then spec[aes] = { var: spec[aes] }
  return spec

poly.layer.make = (layerSpec, strictmode) ->
  switch layerSpec.type
    when 'point' then return new Point(layerSpec, strictmode)
    when 'line' then return new Line(layerSpec, strictmode)
    when 'bar' then return new Bar(layerSpec, strictmode)

###
# CLASSES
###
class Layer
  constructor: (layerSpec, strict) ->
    @strict = strict
    @spec = poly.layer.toStrictMode layerSpec
    @dataprocess = new poly.DataProcess layerSpec
    @dataprocess.process @constructorCallback
  constructorCallback: (statData, metaData) =>
    @mapping = {}
    @consts = {}
    for aes in aesthetics
      if @spec[aes]
        if @spec[aes].var then @mapping[aes] = @spec[aes].var
        if @spec[aes].const then @consts[aes] = @spec[aes].const
    @defaults = defaults
    # datas
    @precalc = statData
    @postcalc = null
    @meta = metaData
    # geoms
    @geoms = null
  # calculation related
  calculate: () ->
    @layerDataCalc()
    @geomCalc()
  layerDataCalc: () -> @postcalc = @precalc
  geomCalc: () -> @geoms = {}
  # helpers
  getValue: (item, aes) ->
    if @mapping[aes] then return item[@mapping[aes]]
    if @consts[aes] then return sf.identity(@consts[aes])
    return sf.identity(@defaults[aes])

class Point extends Layer
  geomCalc: () ->
    @geoms = _.map @postcalc, (item) =>
      evtData = {}
      _.each item, (v, k) ->
        evtData[k] = { in : [v] }
      geoms: [
        type: 'point'
        x: @getValue item, 'x'
        y: @getValue item, 'y'
        color: @getValue item, 'color'
      ]
      evtData: evtData

class Line extends Layer
  layerDataCalc: () ->
    @ys = if @mapping['y'] then _.uniq _.pluck @precalc, @mapping['y'] else []
    # TODO: fill in missing points
    @postcalc = _.clone @precalc
  geomCalc: () ->
    group = (@mapping[k] for k in _.without(_.keys(@mapping), 'x', 'y'))
    datas = poly.groupBy @postcalc, group
    @geoms = _.map datas, (data) =>
      evtData = {}
      _.each group, (key) -> evtData[key] = { in : [data[0][key]] }
      geoms: [
        type: 'line'
        x: (@getValue item, 'x' for item in data)
        y: (@getValue item, 'y' for item in data)
        color: @getValue data[0], 'color'
      ]
      evtData: evtData

class Bar extends Layer
  layerDataCalc: () -> #note: this is assuming STACKING position
    @postcalc = _.clone @precalc
    group = if @mapping.x? then [@mapping.x] else []
    datas = poly.groupBy @postcalc , group
    _.each datas, (data) =>
      # TODO: add sorting?
      tmp = 0
      yval = if @mapping.y? then ((item) => item[@mapping.y]) else (item) -> 0
      _.each data, (item) ->
        item.$lower = tmp
        tmp += yval(item)
        item.$upper = tmp
  geomCalc: () ->
    @geoms = _.map @postcalc, (item) =>
      evtData = {}
      _.each item, (v, k) -> if k isnt 'y' then evtData[k] = { in: [v] }
      geoms: [
        type: 'rect'
        x1: sf.lower @getValue(item, 'x')
        x2: sf.upper @getValue(item, 'x')
        y1: item.$lower
        y2: item.$upper
        fill: @getValue item, 'color'
      ]
###
# EXPORT
###
@poly = poly
