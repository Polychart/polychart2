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
  'opacity': 0.9
  'shape': 1
}

##########
# GLOBALS
##########
poly.layer = {}

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
    else throw poly.error.defn "No such layer #{layerSpec.type}."

###########
# CLASSES
###########

###
Base class for all layers
###
class Layer
  defaults : _.extend(defaults, {'size':7})

  constructor: (layerSpec, strict) ->
    @initialSpec = layerSpec
    @prevSpec = null
    @spec = null
    @pts = {}

  reset : () => @make @initialSpec

  make: (spec, statData, metaData, callback) ->
    @spec = spec
    @_makeMappings @spec
    @prevSpec = @spec
    @statData = statData
    @meta = metaData
    if not @statData?
      throw poly.error.data "No data is passed into the layer"
    @_calcGeoms()
    @prevSpec = @spec
    callback()

  _calcGeoms: () -> @geoms = {} # layer level geom calculation

  getMeta: (key) ->
    if @mapping[key] then @meta[@mapping[key]] else {}
 
  # render and animation functions!
  render: (render) =>
    geoms =
      if @spec.sample is false
        @geoms
      else if _.isNumber @spec.sample
        poly.sample @geoms, @spec.sample
      else
        throw poly.error.defn "A layer's 'sample' definition should be an integer, not #{@spec.sample}"

    newpts = {}
    {deleted, kept, added} = poly.compare _.keys(@pts), _.keys(geoms)
    for id in deleted
      @_delete render, @pts[id]
    for id in added
      newpts[id] = @_add render, geoms[id]
    for id in kept
      newpts[id] = @_modify render, @pts[id], geoms[id]
    @pts = newpts
    sampled :  _.size(geoms) isnt _.size(@geoms)
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
        order[aes] = _.sortBy values, (x) -> x
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
        if k isnt 'y' then evtData[@mapping[k]] = { in: [v] }
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
  _calcGeomsStack: () ->
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
            opacity: @_getValue item, 'opacity'
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
