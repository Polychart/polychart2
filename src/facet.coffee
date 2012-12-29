##
# Faceting related functions
#
# Note that even though Facet is a class, it does not do any rendering and can
# be # created every time a graph is re-drawn. This is okay.
##

poly.facet = {}

poly.facet.make = (spec) ->
  if not spec? or not spec.type?
    return new NoFacet()
  switch spec.type
    when 'wrap' then return new Wrap spec
    when 'grid' then return new Grid spec
    else throw poly.error.defn "No such facet type #{spec.type}."

class Facet
  constructor: (@spec) ->
    @values = {}
    @groups = []
  getIndices: (datas) ->
    @values = {}
    for key in @groups
      v = []
      for index, data of datas
        if key of data.metaData
          v = _.union v, _.uniq(_.pluck(data.statData, key))
      @values[key] = v # add sorting here
    indexValues = poly.cross @values
    # format
    @indices = {}
    stringify = poly.stringify @groups
    for val in indexValues
      @indices[stringify val] = val
    @indices
  groupData: (unfaceted) ->
    if not @indices then @getIndices(unfacted, @groups)
    datas = {}
    groupedData = poly.groupProcessedData unfaceted, @groups
    for id, mindex of @indices
      pointer = groupedData
      while pointer.grouped is true
        value = mindex[pointer.key]
        pointer = pointer.values[value]
      datas[id] = pointer
    datas
  getOffset: (dims, col, row) ->
    x : dims.paddingLeft + dims.guideLeft + (dims.chartWidth + dims.horizontalSpacing) * col
    y : dims.paddingTop + dims.guideTop + (dims.chartHeight + dims.verticalSpacing) * row
  getGrid: () -> throw poly.error.impl()
  edge: (dir, col, row) ->
    if dir is 'none' then return -> false
    if dir is 'out' then return -> true
    grp = if dir in ['top', 'bottom'] then col else row
    optimize =
      if dir is 'top' then row
      else if dir is 'bottom' then (k) -> -row(k)
      else if dir is 'left' then col
      else if dir is 'right' then (k) -> -col(k)
    acc = {}
    for key of @indices
      n = grp(key)
      m = optimize(key)
      if not acc[n] or m <acc[n].v
        acc[n] =
          v: m
          k: key
    edge = _.pluck(acc, 'k')
    (identifier) -> identifier in edge

class NoFacet extends Facet
  getOffset: (dims) -> super(dims, 0, 0)
  getGrid: () -> {cols: 1, rows: 1}
  edge: (dir) -> () -> true

class Wrap extends Facet
  constructor: (@spec) ->
    if not @spec.var
      throw poly.error.defn "You didn't specify a variable to facet on."
    @var = @spec.var
    super @spec
    @groups = [@var]
  getGrid: () ->
    if not @values or not @indices
      throw poly.error.input "Need to run getIndices first!"
    @cols = @spec.cols
    @rows = @spec.rows
    numFacets = @values[@var].length
    if not @cols and not @rows
      @cols = Math.min(3, numFacets)
    if @cols
      @rows = Math.ceil(numFacets/@cols)
    else if @rows
      @cols = Math.ceil(numFacets/@rows)
    cols: @cols
    rows: @rows
  edge: (dir) ->
    col = (id) => _.indexOf(@values[@var], @indices[id][@var]) % @cols
    row = (id) => Math.floor(_.indexOf(@values[@var], @indices[id][@var]) / @cols)
    super(dir, col, row)
  getOffset: (dims, identifier) ->
    # buggy?
    value = @indices[identifier][@var]
    id = _.indexOf(@values[@var], value)
    super(dims,id % @cols, Math.floor(id/@cols))

class Grid extends Facet
  constructor: (@spec) ->
    if not @spec.x and @spec.y
      throw poly.error.defn "You didn't specify a variable to facet on."
    @x = @spec.x
    @y = @spec.y
    super @spec
    @groups = _.compact [@x, @y]
  getGrid: () ->
    if not @values or not @indices
      throw poly.error.input "Need to run getIndices first!"
    cols: if @x then @values[@x].length else 1
    rows: if @y then @values[@y].length else 1
  edge: (dir) ->
    row = (id) => _.indexOf @values[@y], @indices[id][@y]
    col = (id) => _.indexOf @values[@x], @indices[id][@x]
    super(dir, col, row)
  getOffset: (dims, identifier) ->
    if not @values or not @indices
      throw poly.error.input "Need to run getIndices first!"
    row = _.indexOf @values[@y], @indices[identifier][@y]
    col = _.indexOf @values[@x], @indices[identifier][@x]
    super(dims, col, row)
