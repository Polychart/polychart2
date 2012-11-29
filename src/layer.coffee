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
  defaults : defaults

  constructor: (layerSpec, strict) ->
    @initialSpec = poly.layer.toStrictMode layerSpec
    @prevSpec = null
    @dataprocess = new poly.DataProcess @initialSpec, strict
    @pts = {}

  reset : () => @make @initialSpec

  _makeMappings: (spec) =>
    @mapping = {}      # aesthetic mappings
    @consts = {}       # constants supplied by the spec
    for aes in aesthetics
      if spec[aes]
        if spec[aes].var then @mapping[aes] = spec[aes].var
        if spec[aes].const then @consts[aes] = spec[aes].const

  make: (layerSpec, callback) -> # mostly just read and interpret the the spec
    spec = poly.layer.toStrictMode layerSpec
    #if @prevSpec and spec == @prevSpec then return callback()
    @_makeMappings spec
    @dataprocess.make spec, (statData, metaData) =>
      @statData = statData
      @meta = metaData
      @_calcGeoms()
      callback()
    @prevSpec = spec

  _calcGeoms: () -> @geoms = {} # layer level geom calculation
 
  # render and animation functions!
  render: (render) =>
    newpts = {}
    {deleted, kept, added} = poly.compare _.keys(@pts), _.keys(@geoms)
    _.each deleted, (id) => @_delete render, @pts[id]
    _.each added, (id) => newpts[id] = @_add render, @geoms[id]
    _.each kept, (id) =>
      newpts[id] = @_modify render, @pts[id], @geoms[id]
    @pts = newpts
  _delete : (render, points) ->
    _.each points, (pt, id2) -> render.remove pt
  _modify: (render, points, geom) ->
    objs = {}
    _.each geom.marks, (mark, id2) ->
      objs[id2] = render.animate points[id2], mark, geom.evtData
    objs
  _add: (render, geom) ->
    objs = {}
    _.each geom.marks, (mark, id2) ->
      objs[id2] = render.add mark, geom.evtData
    objs

  # helper for getting the value of a particular aesthetic from an item
  _getValue: (item, aes) ->
    if @mapping[aes] then return item[@mapping[aes]]
    if @consts[aes] then return sf.identity(@consts[aes])
    return sf.identity(@defaults[aes])
  _getIdFunc: () ->
    if @mapping['id']? then (item) => @_getValue item, 'id' else poly.counter()

class Point extends Layer
  _calcGeoms: () ->
    idfn = @_getIdFunc()
    @geoms = {}
    _.each @statData, (item) =>
      evtData = {}
      _.each item, (v, k) ->
        evtData[k] = { in : [v] }
      @geoms[idfn item] =
        marks:
          0:
            type: 'circle'
            x: @_getValue item, 'x'
            y: @_getValue item, 'y'
            color: @_getValue item, 'color'
        evtData: evtData

class Line extends Layer
  _calcGeoms: () ->
    # @ys = if @mapping['y'] then _.uniq _.pluck @statData, @mapping['y'] else []
    # TODO: fill in missing points
    group = (@mapping[k] for k in _.without(_.keys(@mapping), 'x', 'y'))
    datas = poly.groupBy @statData, group
    idfn = @_getIdFunc()
    @geoms = {}
    _.each datas, (data) => # produce one line per group
      # use the first data point as a sample
      sample = data[0] # use this as a sample data
      # create the eventData
      evtData = {}
      _.each group, (key) -> evtData[key] = { in : [sample[key]] }
      # identity
      @geoms[idfn sample] =
        marks:
          0:
            type: 'line'
            x: (@_getValue item, 'x' for item in data)
            y: (@_getValue item, 'y' for item in data)
            color: @_getValue sample, 'color'
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
    idfn = @_getIdFunc()
    @geoms = {}
    _.each @statData, (item) =>
      evtData = {}
      _.each item, (v, k) -> if k isnt 'y' then evtData[k] = { in: [v] }
      @geoms[idfn item] =
        marks:
          0:
            type: 'rect'
            x1: sf.lower @_getValue(item, 'x')
            x2: sf.upper @_getValue(item, 'x')
            y1: item.$lower
            y2: item.$upper
            fill: @_getValue item, 'color'
###
# EXPORT
###
@poly = poly
