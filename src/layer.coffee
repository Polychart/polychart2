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
  'size': 2
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
  for aes in aesthetics
    if spec[aes] and _.isString spec[aes] then spec[aes] = { var: spec[aes] }
  spec

###
Public interface to making different layer types.
###
poly.layer.make = (layerSpec, strictmode) ->
  switch layerSpec.type
    when 'point' then return new Point(layerSpec, strictmode)
    when 'text' then return new Text(layerSpec, strictmode)
    when 'line' then return new Line(layerSpec, strictmode)
    when 'path' then return new Path(layerSpec, strictmode)
    when 'area' then return new Area(layerSpec, strictmode)
    when 'bar' then return new Bar(layerSpec, strictmode)
    when 'tile' then return new Tile(layerSpec, strictmode)
    when 'box' then return new Box(layerSpec, strictmode)

###########
# CLASSES
###########

###
Base class for all layers
###
class Layer
  defaults : _.extend(defaults, {'size':7})

  constructor: (layerSpec, strict) ->
    @initialSpec = poly.layer.toStrictMode layerSpec
    @prevSpec = null
    @dataprocess = new poly.DataProcess @initialSpec, strict
    @pts = {}

  reset : () => @make @initialSpec

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

  getMeta: (key) ->
    if @mapping[key] then @meta[@mapping[key]] else {}
 
  # render and animation functions!
  render: (render) =>
    newpts = {}
    {deleted, kept, added} = poly.compare _.keys(@pts), _.keys(@geoms)
    for id in deleted
      @_delete render, @pts[id]
    for id in added
      newpts[id] = @_add render, @geoms[id]
    for id in kept
      newpts[id] = @_modify render, @pts[id], @geoms[id]
    @pts = newpts
  _delete : (render, points) ->
    for id2, pt of points
      render.remove pt
  _modify: (render, points, geom) ->
    objs = {}
    for id2, mark of geom.marks
      objs[id2] = render.animate points[id2], mark, geom.evtData
    objs
  _add: (render, geom) ->
    objs = {}
    for id2, mark of geom.marks
      objs[id2] = render.add mark, geom.evtData
    objs

  # helper function to get @mapping and @consts
  _makeMappings: (spec) =>
    @mapping = {}      # aesthetic mappings
    @consts = {}       # constants supplied by the spec
    for aes in aesthetics
      if spec[aes]
        if spec[aes].var then @mapping[aes] = spec[aes].var
        if spec[aes].const then @consts[aes] = spec[aes].const
  # helper for getting the value of a particular aesthetic from an item
  _getValue: (item, aes) ->
    if @mapping[aes] then return item[@mapping[aes]]
    if @consts[aes] then return sf.identity(@consts[aes])
    return sf.identity(@defaults[aes])
  # helper function to get an element's "id"
  _getIdFunc: () ->
    if @mapping['id']? then (item) => @_getValue item, 'id' else poly.counter()
  # data helper functions
  _fillZeros: (data, all_x) ->
    data_x = (@_getValue item, 'x' for item in data)
    missing = _.difference(all_x, data_x)
    x : data_x.concat missing
    y : (@_getValue item, 'y' for item in data).concat (0 for x in missing)
  _stack: (group) ->
    # handle +/- separately?
    datas = poly.groupBy @statData , group
    for key, data of datas
      tmp = 0
      yval = if @mapping.y? then ((item) => item[@mapping.y]) else (item) -> 0
      for item in data
        item.$lower = tmp
        tmp += yval(item)
        item.$upper = tmp

class Point extends Layer
  _calcGeoms: () ->
    idfn = @_getIdFunc()
    @geoms = {}
    for item in @statData
      evtData = {}
      for k, v of item
        evtData[k] = { in : [v] }
      @geoms[idfn item] =
        marks:
          0:
            type: 'circle'
            x: @_getValue item, 'x'
            y: @_getValue item, 'y'
            color: @_getValue item, 'color'
            size: @_getValue item, 'size'
        evtData: evtData

class Path extends Layer
  _calcGeoms: () ->
    group = (@mapping[k] for k in _.without(_.keys(@mapping), 'x', 'y'))
    datas = poly.groupBy @statData, group
    idfn = @_getIdFunc()
    @geoms = {}
    for k, data of datas
      # use the first data point as a sample
      sample = data[0] # use this as a sample data
      # create the eventData
      evtData = {}
      for key in group
        evtData[key] = { in : [sample[key]] }
      @geoms[idfn sample] =
        marks:
          0:
            type: 'path'
            x: (@_getValue item, 'x' for item in data)
            y: (@_getValue item, 'y' for item in data)
            color: @_getValue sample, 'color'
        evtData: evtData

class Line extends Layer
  _calcGeoms: () ->
    # @ys = if @mapping['y'] then _.uniq _.pluck @statData, @mapping['y'] else []
    all_x = _.uniq (@_getValue item, 'x' for item in @statData)
    group = (@mapping[k] for k in _.without(_.keys(@mapping), 'x', 'y'))
    datas = poly.groupBy @statData, group
    idfn = @_getIdFunc()
    @geoms = {}
    for k, data of datas
      # use the first data point as a sample
      sample = data[0] # use this as a sample data
      # create the eventData
      evtData = {}
      for key in group
        evtData[key] = { in : [sample[key]] }
      # fill zeros
      {x, y} = @_fillZeros(data, all_x)
      @geoms[idfn sample] =
        marks:
          0:
            type: 'line'
            x: x
            y: y
            color: @_getValue sample, 'color'
        evtData: evtData

class Bar extends Layer
  _calcGeoms: () ->
    # first do stacking calculation (assuming position=stack)
    group = if @mapping.x? then [@mapping.x] else []
    @_stack group
    # now actually render
    idfn = @_getIdFunc()
    @geoms = {}
    for item in @statData
      evtData = {}
      for k, v of item
        if k isnt 'y' then evtData[@mapping[k]] = { in: [v] }
      @geoms[idfn item] =
        marks:
          0:
            type: 'rect'
            x: [sf.lower(@_getValue(item, 'x')), sf.upper(@_getValue(item, 'x'))]
            y: [item.$lower, item.$upper]
            color: @_getValue item, 'color'
        evtData: evtData

class Area extends Layer
  _calcGeoms: () ->
    all_x = _.uniq (@_getValue item, 'x' for item in @statData)
    counters = {} # handle +/- separately?
    for key in all_x
      counters[key] = 0
    group = (@mapping[k] for k in _.without(_.keys(@mapping), 'x', 'y'))
    datas = poly.groupBy @statData, group

    idfn = @_getIdFunc()
    @geoms = {}
    for k, data of datas
      sample = data[0] # use this as a sample data
      # create the eventData
      evtData = {}
      for key in group
        evtData[key] = { in : [sample[key]] }
      # stacking
      y_previous = (counters[x] for x in all_x)
      for item in data
        x = @_getValue(item, 'x')
        y = @_getValue(item, 'y')
        counters[x] += y
      y_next = (counters[x] for x in all_x)
      @geoms[idfn sample] =
        marks:
          0:
            type: 'area'
            x: all_x
            y: {bottom: y_previous, top: y_next}
            color: @_getValue sample, 'color'
        evtData: evtData

class Text extends Layer
  _calcGeoms: () ->
    idfn = @_getIdFunc()
    @geoms = {}
    for item in @statData
      evtData = {}
      for k, v of item
        evtData[k] = { in : [v] }
      @geoms[idfn item] =
        marks:
          0:
            type: 'text'
            x: @_getValue item, 'x'
            y: @_getValue item, 'y'
            text: @_getValue item, 'text'
            color: @_getValue item, 'color'
            size: @_getValue item, 'size'
            'text-anchor': 'center'
        evtData: evtData

class Tile extends Layer
  _calcGeoms: () ->
    idfn = @_getIdFunc()
    @geoms = {}
    for item in @statData
      evtData = {}
      x = @_getValue item, 'x'
      y = @_getValue item, 'y'
      @geoms[idfn item] =
        marks:
          0:
            type: 'rect'
            x: [sf.lower(@_getValue(item, 'x')), sf.upper(@_getValue(item, 'x'))]
            y: [sf.lower(@_getValue(item, 'y')), sf.upper(@_getValue(item, 'y'))]
            color: @_getValue item, 'color'
            size: @_getValue item, 'size'
        evtData: evtData

class Box extends Layer
  _calcGeoms: () ->
    #group = if @mapping.x? then [@mapping.x] else []
    # enforce ONE value per x?
    idfn = @_getIdFunc()
    @geoms = {}
    for item in @statData
      evtData = {} # later
      x = @_getValue item, 'x'
      y = @_getValue item, 'y'
      xl = sf.lower(x)
      xu = sf.upper(x)
      xm = sf.middle(x)
      @geoms[idfn item] =
        marks:
          iqr:
            type: 'path'
            x: [xl, xl, xu, xu, xl]
            y: [y.q2, y.q4, y.q4, y.q2, y.q2]
            stroke: @_getValue item, 'color'
            fill: 'none'
            size: @_getValue item, 'size'
          lower:
            type: 'line'
            x: [xm, xm]
            y: [y.q1, y.q2]
            color: @_getValue item, 'color'
            size: @_getValue item, 'size'
          upper:
            type: 'line'
            x: [xm, xm]
            y: [y.q4, y.q5]
            color: @_getValue item, 'color'
            size: @_getValue item, 'size'
          middle:
            type: 'line'
            x: [xl, xu]
            y: [y.q3, y.q3]
            color: @_getValue item, 'color'
            size: @_getValue item, 'size'
        evtData: evtData
      for point, index in y.outliers
        @geoms[idfn item].marks[index] =
          type: 'circle'
          x: xm
          y: point
          color: @_getValue item, 'color'
            size: @_getValue item, 'size'

###
# EXPORT
###
@poly = poly
