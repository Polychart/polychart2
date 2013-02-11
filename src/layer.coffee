###
Layer
------------------------------------------
A "Layer" is a visual representation of some data. It is sometimes referred
to as a glymph, geometry, or mark, and was (erronously) referred to as "chart
type" in Polychart graph builder.

Each layer needs to be initiated with a specification object. Once initiated,
the layer's @calculate() function takes a dataset + metadata, and produces
one or more objects representing geometric objects. These geometrical objects
have the appropriate data mapped to each appropriate aesthetics, but the scale
has not yet been applied.

These geometrical objects are be rendered on the screen using the Geometry class
found in abstract.coffee

Layers can be reused: i.e. created once and applied to many versions of the same
data set. It is also disposable, and does not contain state information -- only
state that needs to be preserved for consistency is the geometry.
###

###
Shared constants
###

aesthetics = poly.const.aes # list of aesthetics
sf = poly.const.scaleFns    # list of scale functions
defaults = {                # global default values for aesthetics
  'x': sf.novalue()
  'y': sf.novalue()
  'color': 'steelblue'
  'size': 7
  'opacity': 0.9
  'shape': 1
}

###
Base class for all layers
###
class Layer
  defaults: defaults
  constructor: (spec) ->
    @spec = spec
    @mapping = {}      # aesthetic mappings
    @consts = {}       # constants supplied by the spec
    for aes in aesthetics
      if spec[aes]
        if spec[aes].var then @mapping[aes] = spec[aes].var
        if spec[aes].const then @consts[aes] = spec[aes].const
  calculate: (@statData, @meta) ->
    @_calcGeoms()
    meta = {}
    for aes, key of @mapping
      meta[aes] = @meta[key]
    geoms: @geoms
    meta: meta
  _calcGeoms: () ->
    throw poly.error.impl()
  _tooltip: (item) -> 'foo'
  _mappings: (spec) ->
  # helper for getting the value of a particular aesthetic from an item
  _getValue: (item, aes) ->
    if @mapping[aes]          then item[@mapping[aes]]
    else if @consts[aes]      then sf.identity @consts[aes]
    else if aes in ['x', 'y'] then defaults[aes]
    else                           sf.identity defaults[aes]
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
  _dodge: (group) ->
    groupAes = _.without _.keys(@mapping), 'x', 'y', 'id'
    groupKey = _.toArray(_.pick(@mapping, groupAes))
    yval = if @mapping.y? then ((item) => item[@mapping.y]) else (item) -> 0
    for key, datas of poly.groupBy @statData, group
      order = {}
      numgroup = 1
      for aes in groupAes
        values = _.uniq (@_getValue item, aes for item in datas)
        numgroup *= values.length
        values.sort poly.type.compare(@meta[@mapping[aes]].type)
        order[aes] = values
      orderfn = (item) =>
        m = numgroup
        n = 0
        for aes in groupAes
          m /= order[aes].length
          n += m * _.indexOf order[aes], @_getValue(item, aes)
        n
      for item in datas
        item.$n = orderfn(item)
        item.$m = numgroup

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
            opacity: @_getValue item, 'opacity'
        evtData: evtData
        tooltip: @_tooltip(item)

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
            opacity: @_getValue sample, 'opacity'
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
            opacity: @_getValue sample, 'opacity'
        evtData: evtData

class Bar extends Layer
  _calcGeoms: () ->
    if @mapping.x
      m = @meta[@mapping.x]
      if m.type isnt 'cat' and not m.binned
        #TODO: this need to be an error; however it doesn't take care of the
        #case that the binwidth is specified in the guidespec
        console.log "Bar chart x-values need to be binned. Use the bin() transform!"
    @position = @spec.position ? 'stack'
    if @position is 'stack'
      @_calcGeomsStack()
    else if @position is 'dodge'
      @_calcGeomsDodge()
    else
      throw poly.error.defn "Bar chart position #{@position} is unknown."
  _calcGeomsDodge: () ->
    group = if @mapping.x? then [@mapping.x] else []
    @_dodge group
    @_stack group.concat "$n"
    @geoms = {}
    idfn = @_getIdFunc()
    for item in @statData
      evtData = {}
      for k, v of item
        if k isnt 'y' then evtData[k] = { in: [v] }
      lower = sf.lower @_getValue(item, 'x'), item.$n, item.$m
      upper = sf.upper @_getValue(item, 'x'), item.$n, item.$m
      @geoms[idfn item] =
        marks:
          0:
            type: 'rect'
            x: [lower, upper]
            y: [item.$lower, item.$upper]
            color: @_getValue item, 'color'
            opacity: @_getValue item, 'opacity'
        evtData: evtData
        tooltip: @_tooltip(item)

  _calcGeomsStack: () ->
    group = if @mapping.x? then [@mapping.x] else []
    @_stack group
    # now actually render
    idfn = @_getIdFunc()
    @geoms = {}
    for item in @statData
      evtData = {}
      for k, v of item
        if k isnt 'y' then evtData[k] = { in: [v] }
      @geoms[idfn item] =
        marks:
          0:
            type: 'rect'
            x: [sf.lower(@_getValue(item, 'x')), sf.upper(@_getValue(item, 'x'))]
            y: [item.$lower, item.$upper]
            color: @_getValue item, 'color'
            opacity: @_getValue item, 'opacity'
        evtData: evtData
        tooltip: @_tooltip(item)

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
            opacity: @_getValue sample, 'opacity'
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
            opacity: @_getValue item, 'opacity'
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
      for k, v of item
        if k isnt 'y' and k isnt 'x' then evtData[k] = { in: [v] }

      @geoms[idfn item] =
        marks:
          0:
            type: 'rect'
            x: [sf.lower(@_getValue(item, 'x')), sf.upper(@_getValue(item, 'x'))]
            y: [sf.lower(@_getValue(item, 'y')), sf.upper(@_getValue(item, 'y'))]
            color: @_getValue item, 'color'
            size: @_getValue item, 'size'
            opacity: @_getValue item, 'opacity'
        evtData: evtData
        tooltip: @_tooltip(item)

class Box extends Layer
  _calcGeoms: () ->
    #group = if @mapping.x? then [@mapping.x] else []
    # enforce ONE value per x?
    idfn = @_getIdFunc()
    @geoms = {}
    for item in @statData
      evtData = {} # later
      for k, v of item
        if k isnt 'y' then evtData[k] = { in: [v] }
      x = @_getValue item, 'x'
      y = @_getValue item, 'y'
      color = @_getValue item, 'color'
      size = @_getValue item, 'size'
      opacity = @_getValue item, 'opacity'
      xl = sf.lower(x)
      xu = sf.upper(x)
      xm = sf.middle(x)
      geom = marks: {} , evtData: evtData
      if y.q1 # and therefore y.q2, y.q3, etc...
        geom.marks =
          iqr:
            type: 'rect'
            x: [xl, xu]
            y: [y.q2, y.q4]
            stroke: color
            color: sf.identity 'white'
            size: size
            opacity: opacity
            'stroke-width': '1px'
          q1:
            type: 'pline'
            x: [xl, xu]
            y: [y.q1, y.q1]
            color: color
            size: size
            opacity: opacity
          lower:
            type: 'pline'
            x: [xm, xm]
            y: [y.q1, y.q2]
            color: color
            size: size
            opacity: opacity
          q5:
            type: 'pline'
            x: [xl, xu]
            y: [y.q5, y.q5]
            color: color
            size: size
            opacity: opacity
          upper:
            type: 'pline'
            x: [xm, xm]
            y: [y.q4, y.q5]
            color: color
            size: size
            opacity: opacity
          middle:
            type: 'pline'
            x: [xl, xu]
            y: [y.q3, y.q3]
            color: color
            size: size
            opacity: opacity
      for point, index in y.outliers
        geom.marks[index] =
          type: 'circle'
          x: xm
          y: point
          color: color
          size: sf.identity 3
          opacity: opacity
      @geoms[idfn item] = geom

###
Public interface to making different layer types.
TODO: this should be changed to make it easier to make other
      types of layers.
###
poly.layer = {}
poly.layer.classes = {
  'point' : Point
  'text' : Text
  'line' : Line
  'path' : Path
  'area' : Area
  'bar' : Bar
  'tile' : Tile
  'box' : Box
}
poly.layer.make = (layerSpec, strictmode) ->
  type = layerSpec.type
  if type of poly.layer.classes
    return new poly.layer.classes[type](layerSpec, strictmode)
  throw poly.error.defn "No such layer #{layerSpec.type}."
