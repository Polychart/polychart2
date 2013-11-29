##
# Pivot table object and entry point: poly.pivot()
# ------------------------------------------------
# This is the main pivot table object; controls workflow
##

toStrictMode = (spec) ->
  for aes in ['row', 'column', 'value']
    if not spec[aes+'s']
      spec[aes+'s'] = []
      if spec[aes]?
        spec[aes+'s'].push(spec[aes])
  for aes in ['rows', 'columns', 'values']
    for mappedTo, i in spec[aes]
      if _.isString mappedTo
        spec[aes][i] = { var: mappedTo }
  spec.full ?= false
  spec.formatter ?= {}
  for key, val of spec.formatter
    # normalize key names
    key = poly.parser.normalize(key)
    spec.formatter[key] = val
  spec

class PivotProcessedData
  constructor: (@statData, @ticks, @spec) ->
    # Construct the data
    # put data in a structure such that a data point can be fetched by
    # identifying the ROWS then COLS, and also COLS then ROWS
    @rows = (poly.parser.unbracket item.var for item in @spec.rows)
    @columns = (poly.parser.unbracket item.var for item in @spec.columns)
    indexRows = @rows.concat(@columns) # actually used
    indexCols = @columns              # only for header calculation
    @dataIndexByRows = {}
    @dataIndexByCols = {}
    _insertInto = (structure, keys, row) ->
      tmp = tmp_parent = structure
      for key in keys
        tmp[row[key]] ?= {}
        tmp_parent = tmp
        tmp = tmp_parent[row[key]]
      tmp_parent[row[key]] = row
    for row in @statData
      _insertInto(@dataIndexByRows, indexRows, row)
      _insertInto(@dataIndexByCols, indexCols, row)

  makeHeaders: () =>
    full = @spec.full
    _recurse = (accumulator, indexValues, keys, item) =>
      if keys.length is 0
        accumulator.push(indexValues)
      else
        key = keys[0]
        restOfKeys = keys[1..]
        values = _.keys(item) # all possible values (or column headers)
        _.each @ticks[key].ticks, (tickValue, v) =>
          if full or _.contains(values, ""+tickValue.location)
            indexV = _.clone(indexValues)
            indexV[key] = tickValue.value
            _recurse(accumulator, indexV, restOfKeys, item[tickValue.location])
    @rowHeaders=[]
    @colHeaders=[]
    _recurse(@rowHeaders, {}, @rows, @dataIndexByRows)
    _recurse(@colHeaders, {}, @columns, @dataIndexByCols)
    {@rowHeaders, @colHeaders}

  makeFormatters: () =>
    # must have formatter for values
    values = (poly.parser.unbracket item.var for item in @spec.values)
    formatters = {}
    for v in values
      formatters[v] =
        if v of @spec.formatter
          @spec.formatter[v]
        else
          exp = poly.format.getExp(_.min(_.pluck(@statData, v)))
          degree = exp
          poly.format.number(degree)
    # can optionally have formatter for columns & rows
    for v in @columns.concat(@rows)
      if v of @spec.formatter
        formatters[v] = @spec.formatter[v]
    formatters

  get: (rowMindex, colMindex, val) =>
    retvalue = @dataIndexByRows
    for key in @rows
      index = @ticks[key].ticks[rowMindex[key]].location
      if retvalue? and retvalue[index]?
        retvalue = retvalue[index]
    for key in @columns
      index = @ticks[key].ticks[colMindex[key]].location
      if retvalue? and retvalue[index]?
        retvalue = retvalue[index]
    if retvalue? and retvalue[val]?
      retvalue[val]

class Pivot
  constructor: (spec, @callback, @prepare) ->
    if not spec?
      throw poly.error.defn "No pivot table specification is passed in!"
    @make(spec)

  make: (spec) ->
    @spec = toStrictMode(spec)
    ps = new poly.DataProcess(@spec, [], @spec.strict, poly.spec.pivotToData)
    ps.make @spec, [], @render

  generateTicks: (spec, statData, metaData) =>
    ticks = {}
    for aes in ['rows', 'columns']
      for item in spec[aes]
        key = poly.parser.unbracket item.var
        meta = metaData[key]
        values = _.pluck(statData, key)
        domain = poly.domain.single(values, metaData[key], {})
        guideSpec =
          if meta.type is 'cat'
            ticks: domain.levels
          else if meta.type is 'num'
            numticks: (domain.max - domain.min) / meta.bw
          else # meta.type is 'date'
            bw = poly.const.approxTimeInSeconds[meta.bw]
            numticks: (domain.max - domain.min) / bw
        tick = poly.tick.make(domain, guideSpec, metaData[key].type)
        ticks[key] = tick
    ticks

  render: (err, statData, metaData) =>
    # create  ticks
    ticks = @generateTicks(@spec, statData, metaData)
    pivotData = new PivotProcessedData(statData, ticks, @spec)
    {rowHeaders, colHeaders} = pivotData.makeHeaders()
    formatters  = pivotData.makeFormatters()
    pivotMeta =
      ncol: @spec.columns.length
      nrow: @spec.rows.length
      nval: @spec.values.length

    # render a table...
    if not $
      throw poly.error.depn "Pivot Tables require jQuery!"

    table = $('<table></table>').attr('border', '1px solid black')
    table.attr('cellspacing', 0)
    table.attr('cellpadding', 0)
    i = 0
    #  COLUMN headers
    while i < pivotMeta.ncol
      row = $('<tr></tr>')
      key = poly.parser.unbracket @spec.columns[i].var
      ## SPACE in the FIRST ROW
      if i is 0
        if pivotMeta.nrow > 1
          space = $('<td></td>')
          space.attr('rowspan', pivotMeta.ncol)
          space.attr('colspan', pivotMeta.nrow-1)
          row.append(space)
      ## COLUMN header names
      row.append $("<th>#{key}:</th>").attr('align', 'right')
      ## COLUMN header values
      j = 0
      while j < colHeaders.length
        value = colHeaders[j][key]
        colspan = 1
        while ((j+colspan) < colHeaders.length) and (value is colHeaders[j+colspan][key])
          colspan++
        if formatters[key] then value = formatters[key](value)
        cell = $("<td class='heading'>#{value}</td>").attr('colspan', colspan*pivotMeta.nval)
        cell.attr('align', 'center')
        row.append(cell)
        j += colspan

      table.append(row)
      i++

    # VALUE headers
    row = $('<tr></tr>')
    if pivotMeta.nrow is 0
      ## SPACE
      space = $("<td class='spacing'></td>")
      space.attr('rowspan', rowHeaders.length+1)
      row.append(space)

    ## ROW header names
    i = 0
    while i < pivotMeta.nrow
      key = poly.parser.unbracket @spec.rows[i].var
      row.append $("<th>#{key}</th>").attr('align', 'center')
      i++
    k = 0
    while k < colHeaders.length
      for v in @spec.values
        cell = $("<td class='heading'>#{poly.parser.unbracket v.var}</td>")
        cell.attr('align', 'center')
        row.append(cell)
      k++
    table.append(row)

    # REST OF TABLE
    i = 0
    rows_mindex = []
    cols_mindex = []
    while i < rowHeaders.length # total rows
      row = $('<tr></tr>')
      # ROW HEADERS
      for key in @spec.rows
        key = poly.parser.unbracket key.var
        value = rowHeaders[i][key]
        if (i is 0) or value != rowHeaders[i-1][key]
          rowspan = 1
          while (i+rowspan < rowHeaders.length) and value == rowHeaders[i+rowspan][key]
            rowspan++
          # add a cell!!
          if formatters[key] then value = formatters[key](value)
          cell = $("<td class='heading'>#{value}</td>").attr('rowspan', rowspan)
          cell.attr('align', 'center')
          cell.attr('valign', 'middle')
          row.append(cell)

      # ROW VALUES
      j = 0
      while j < colHeaders.length
        cols = colHeaders[j]
        rows = rowHeaders[i]

        for val in @spec.values
          name = poly.parser.unbracket val.var
          v = pivotData.get(rows, cols, name)
          v = if v then formatters[name](v) else '-'
          row.append $("<td class='value'>#{v}</td>").attr('align', 'right')
        j++

      table.append(row)
      i++

    if @prepare then @prepare @

    if @spec.width then table.attr('width', @spec.width)
    if @spec.height then table.attr('height', @spec.height)
    @dom = if _.isString(@spec.dom) then $('#'+@spec.dom) else $(@spec.dom)
    @dom.empty()
    @dom.append(table)
    if @callback then @callback null, @

poly.pivot = (spec, callback, prepare) -> new Pivot(spec, callback, prepare)
