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
  getIndices: (datas, groups) ->
    @values = {}
    for key in groups
      v = []
      for index, data of datas
        if key of data.metaData
          v = _.union v, _.uniq(_.pluck(data.statData, key))
      @values[key] = v # add sorting here
    indexValues = poly.cross @values
    # format
    @indices = {}
    stringify = poly.stringify groups
    for val in indexValues
      @indices[stringify val] = val
    @indices
  groupData: (unfaceted, groups) ->
    if not @indices then @getIndices(unfacted, groups)
    datas = {}
    groupedData = poly.groupProcessedData unfaceted, groups
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

class NoFacet extends Facet
  groupData: (datas) ->
    super(datas, [])
  getIndices: (datas) ->
    super(datas, [])
  getOffset: (dims) -> super(dims, 0, 0)
  getGrid: () -> {cols: 1, rows: 1}

class Wrap extends Facet
  constructor: (@spec) ->
    if not @spec.var
      throw poly.error.defn "You didn't specify a variable to facet on."
    @var = @spec.var
    super @spec
  groupData: (datas) ->
    super(datas, [@var])
  getIndices: (datas) ->
    super(datas, [@var])
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
  getOffset: (dims, identifier) ->
    value = @indices[identifier][@var]
    id = _.indexOf(@values[@var], value)
    super(dims,Math.ceil(id/@cols),id % @rows)

class Grid extends Facet
  constructor: (@spec) ->
    if not @spec.x and @spec.y
      throw poly.error.defn "You didn't specify a variable to facet on."
    @x = @spec.x
    @y = @spec.y
    super @spec
  groupData: (datas) ->
    groups = _.compact [@x, @y]
    super(datas, groups)
  getIndices: (datas) ->
    groups = _.compact [@x, @y]
    super(datas, groups)
  getGrid: () ->
    if not @values or not @indices
      throw poly.error.input "Need to run getIndices first!"
    cols: if @x then @values[@x].length else 1
    rows: if @y then @values[@y].length else 1
  getOffset: (dims, identifier) ->
    if not @values or not @indices
      throw poly.error.input "Need to run getIndices first!"
    col = _.indexOf @values[@y], @indices[identifier][@y]
    row = _.indexOf @values[@x], @indices[identifier][@x]
    super(dims, col, row)
