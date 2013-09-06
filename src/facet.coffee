##
# Faceting
# --------
# Facets can split a graph into multiple, smaller graphs of the same type, and
# is useful for analyzing data of different groups. An instance of the Facet
# class controls rendering of panes.
##
poly.facet = {}
poly.facet.make = () -> new Facet()

class Facet
  constructor: () ->
    @type = 'none'
    @mapping = {}
    @specgroups = []
    @groups = []
    @panes = {}
    @deletedPanes = []
  make: (@spec) ->
    # get the new mapping
    {@type, mapping} = @_getMappings(@spec.facet)
    #if !_.isEqual(mapping, @mapping)
    #  @dispose()
    @mapping = mapping
    @groups = _.values(@mapping)
    @specgroups = {}
    for aes, key of mapping
      if @spec.facet[aes]
        key = poly.parser.unbracket(key)
        @specgroups[key] = @spec.facet[aes]
    if @spec.facet.formatter
      @formatter = @spec.facet.formatter
    # pre set font size & color
    @style = {}
    if @spec.facet.size
      @style.size = @spec.facet.size
    if @spec.facet.color
      @style.color = @spec.facet.color
  calculate: (datas, layers) ->
    # facet indices & their values
    {@values, @indices} = @_makeIndices(datas, @specgroups)
    # rows & columns
    if @type is 'none'
      @rows = @cols = 1
    else
      @cols = @spec.facet.cols
      @rows = @spec.facet.rows
      if @type is 'wrap'
        numFacets = @values[@mapping.var].length
        if not @cols and not @rows
          @cols = Math.min(3, numFacets)
        if @cols
          @rows = Math.ceil(numFacets/@cols)
        else if @rows
          @cols = Math.ceil(numFacets/@rows)
      else #type is 'grid'
        @rows = if @mapping.y then @values[@mapping.y].length else 1
        @cols = if @mapping.x then @values[@mapping.x].length else 1
    # data grouping
    @datas = @_groupData(datas, @indices)
    # add, remove & modify panes
    {deleted, kept, added} = poly.compare _.keys(@panes), _.keys(@indices)
    for key in deleted
      @deletedPanes.push @panes[key]
      delete @panes[key]
    for key in added
      name = if @formatter then @formatter(@indices[key]) else key
      @panes[key] = poly.pane.make(@indices[key], _.extend({title:name}, @style))
    for key, multiindex of @indices
      @panes[key].make(@spec, @datas[key], layers)
  render: (renderer, dims, coord) ->
    if @deletedPanes.length > 0
      renderRemoval = renderer({}, false, false)
      for pane in @deletedPanes
        pane.dispose(renderRemoval)
      @deletedPanes = []
    for key, pane of @panes
      offset = @getOffset(dims, key)
      clipping = coord.clipping offset
      pane.render renderer, offset, clipping, dims
  dispose: (renderer) ->
    for key, pane of @panes
      @deletedPanes.push pane
      delete @panes[key]
    if renderer
      for pane in @deletedPanes
        pane.dispose(renderer)
      @deletedPanes = []
    else
      # need to call render(); to remove from screen
  getGrid: () -> {cols: @cols, rows: @rows}
  getOffset: (dims, id) ->
    {col, row} = @_getRowCol(id)
    x : dims.paddingLeft + dims.guideLeft + (dims.eachWidth + dims.horizontalSpacing) * col
    y : dims.paddingTop + dims.guideTop + (dims.eachHeight + dims.verticalSpacing) * row + dims.verticalSpacing
  edge: (dir) ->
    if @type is 'none'
      return () -> true
    if @type is 'grid'
      row = (id) => _.indexOf @values[@mapping.y], @indices[id][@mapping.y]
      col = (id) => _.indexOf @values[@mapping.x], @indices[id][@mapping.x]
    else #if type is 'wrap'
      col = (id) => _.indexOf(@values[@mapping.var], @indices[id][@mapping.var]) % @cols
      row = (id) => Math.floor(_.indexOf(@values[@mapping.var], @indices[id][@mapping.var]) / @cols)
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
  getEvtData: (col, row) ->
    obj = {}
    for aes, key of @mapping
      if aes in ['x', 'y']
        obj[key] = {in: @values[key][col]}
      else
        obj[key] = {in: @values[key][@rows*row + col]}
    obj
  getFacetInfo: (dims, x, y, preset) ->
    if preset
      if not (preset.col? and preset.row?)
        throw poly.error.impl("Preset rows & columns are not present.")
      col = preset.col
      row = preset.row
    else
      col = (x - dims.paddingLeft - dims.guideLeft) / (dims.eachWidth + dims.horizontalSpacing)
      col = Math.floor col
      row = (y - dims.paddingTop - dims.guideTop - dims.verticalSpacing) / (dims.eachHeight + dims.verticalSpacing)
      row = Math.floor row
    if col < 0 or col >= @cols or row < 0 or row >= @rows
      # Outside of facet
      return null
    offset =
      x: dims.paddingLeft + dims.guideLeft + (dims.eachWidth + dims.horizontalSpacing) * col
      y: dims.paddingTop + dims.guideTop + (dims.eachHeight + dims.verticalSpacing) * row + dims.verticalSpacing
    adjusted =
      x: x - offset.x
      y: y - offset.y

    if not preset and (adjusted.x > dims.eachWidth or adjusted.y > dims.eachHeight)
      # In between facets
      return null
    adjusted.x = Math.max(Math.min(adjusted.x, dims.eachWidth), 0)
    adjusted.y = Math.max(Math.min(adjusted.y, dims.eachHeight), 0)

    return {row, col, offset, adjusted, evtData: @getEvtData(col, row)}
  ###
  Helper functions
  ###
  _getMappings: (spec) ->
    retobj =
      type: 'none'
      mapping: {}
    if _.isObject(spec)
      if spec.type is 'wrap'
        retobj.type = 'wrap'
        if not spec.var
          throw poly.error.defn "You didn't specify a variable to facet on."
        if spec.var then retobj.mapping.var = poly.parser.unbracket spec.var.var
      else if spec.type is 'grid'
        retobj.type = 'grid'
        if not spec.x and spec.y
          throw poly.error.defn "You didn't specify a variable to facet on."
        if spec.x then retobj.mapping.x = poly.parser.unbracket spec.x.var
        if spec.y then retobj.mapping.y = poly.parser.unbracket spec.y.var
    retobj
  _makeIndices: (datas, groups) ->
    values = {}
    for aes, key of groups
      name = poly.parser.unbracket key.var
      if key.levels
        values[name] = key.levels
      else
        v = []
        sortfn = null
        for index, data of datas
          if meta = data.metaData[name]
            if meta and meta.type in ['num', 'date']
              poly.type.compare(meta.type)
          v = _.uniq _.union(v, _.pluck(data.statData, name))
        values[name] = if sortfn? then v.sort(sortfn) else v
    indexValues = poly.cross values
    # format
    indices = {}
    grps = (poly.parser.unbracket x for x in _.pluck groups, 'var')
    stringify = poly.stringify grps
    for val in indexValues
      indices[stringify val] = val
    {values, indices}
  _groupData: (unfaceted, indicies) ->
    groupedData = poly.groupProcessedData unfaceted, @groups
    datas = {}
    for id, mindex of @indices
      pointer = groupedData
      while pointer.grouped is true
        value = mindex[pointer.key]
        pointer = pointer.values[value]
      datas[id] = pointer
    datas
  _getRowCol: (id) ->
    retobj = {row: 0, col: 0}
    if @type is 'wrap'
      value = @indices[id][@mapping.var]
      id = _.indexOf(@values[@mapping.var], value)
      retobj.col = id % @cols
      retobj.row = Math.floor(id/@cols)
    else if @type is 'grid'
      retobj.row = _.indexOf @values[@mapping.y], @indices[id][@mapping.y]
      retobj.col = _.indexOf @values[@mapping.x], @indices[id][@mapping.x]
    retobj

###
Take a processedData from the data processing step and group it for faceting
purposes.

Input is in the format:
processData = {
  layer_id : { statData: [...], metaData: {...} }
  ...
}

Output should be in one of the two format:
  groupedData = {
    grouped: true
    key: group1
    values: {
      value1: groupedData2 # note recursive def'n
      value2: groupedData3
      ...
    }
  }
  OR
  groupedData = {
    layer_id : { statData: [...], metaData: {...} }
    ...
  }
###
poly.groupProcessedData = (processedData, groups) ->
  if groups.length is 0
    return processedData
  currGrp = groups.splice(0, 1)[0]
  uniqueValues = []
  for index, data of processedData
    if currGrp of data.metaData
      uniqueValues = _.union uniqueValues, _.uniq(_.pluck(data.statData, currGrp))
  result =
    grouped: true
    key: currGrp
    values: {}
  for value in uniqueValues
    # construct new processedData
    newProcessedData = {}
    for index, data of processedData
      newProcessedData[index] = metaData : data.metaData
      newProcessedData[index].statData =
        if currGrp of data.metaData
          poly.filter(data.statData, currGrp, value)
        else
          _.clone data.statData
    # construct value
    result.values[value] =
      poly.groupProcessedData(newProcessedData, _.clone groups)
  result
