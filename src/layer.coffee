poly = @poly || {}

aesthetics = ['x', 'y', 'color', 'size', 'opacity', 'shape', 'id']
defaults = {
  'x': {v: null, f: 'null'}
  'y': {v: null, f: 'null'}
  'color': 'steelblue'
  'size': 1
  'opacity': 0.7
  'shape': 1
}

toStrictMode = (spec) ->
  _.each aesthetics, (aes) ->
    if spec[aes] and _.isString spec[aes] then spec[aes] = { var: spec[aes] }
  spec

class Layer
  constructor: (layerSpec, statData) ->
    # spec
    @spec = toStrictMode layerSpec
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
    # geoms
    @geoms = null
  calculate: () ->
    @layerDataCalc()
    @geomCalc()
  # calculators
  layerDataCalc: () -> @postcalc = @precalc
  geomCalc: () -> @geoms = {}
  # helpers
  getValue: (item, aes) ->
    if @mapping[aes] then return item[@mapping[aes]]
    if @consts[aes] then return @consts[aes]
    return @defaults[aes]

class Point extends Layer
  geomCalc: () ->
    getGeom = mark_circle @
    @geoms = _.map @postcalc, (item) =>
      geom: getGeom item
      evtData: @getEvtData item
  getEvtData: (item) ->
    evtData = {}
    _.each item, (v, k) ->
      evtData[k] = { in : [v] }
    evtData

mark_circle = (layer) ->
  (item) ->
    type: 'point'
    x: layer.getValue item, 'x'
    y: layer.getValue item, 'y'
    color: layer.getValue item, 'color'
    color: layer.getValue item, 'color'

makeLayer = (layerSpec, statData) ->
  switch layerSpec.type
    when 'point' then return new Point(layerSpec, statData)

poly.layer =
  toStrictMode : toStrictMode
  makeLayer : makeLayer

# EXPORT
@poly = poly
