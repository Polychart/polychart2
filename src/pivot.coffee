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
  spec

class PivotProcessedData
  constructor: (@statData, @ticks, @spec) ->
    # Construct the data
    # put data in a structure such that a data point can be fetched by
    # identifying the ROWS then COLS, and also COLS then ROWS
    @rows = (item.var for item in @spec.rows)
    @columns = (item.var for item in @spec.columns)
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
        _.each @ticks[key].ticks, (ignore, v) =>
          if full or (v in values)
            indexV = _.clone(indexValues)
            indexV[key] = v
            _recurse(accumulator, indexV, restOfKeys, item[v])
    @rowHeaders=[]
    @colHeaders=[]
    _recurse(@rowHeaders, {}, @rows, @dataIndexByRows)
    _recurse(@colHeaders, {}, @columns, @dataIndexByCols)
    {@rowHeaders, @colHeaders}

  makeFormatters: () =>
    values = (item.var for item in @spec.values)
    formatters = {}
    for v in values
      exp = poly.format.getExp(_.min(_.pluck(@statData, v)))
      degree = exp
      formatters[v] = poly.format.number(degree)

    formatters

  get: (rowMindex, colMindex, val) =>
    retvalue = @dataIndexByRows
    for key in @rows
      if retvalue? and retvalue[rowMindex[key]]?
        retvalue = retvalue[rowMindex[key]]
    for key in @columns
      if retvalue? and retvalue[colMindex[key]]?
        retvalue = retvalue[colMindex[key]]
    if retvalue? and retvalue[val]?
      retvalue[val]

class Pivot
  constructor: (spec) ->
    if not spec?
      throw poly.error.defn "No pivot table specification is passed in!"
    @make(spec)

  make: (spec, @callback) ->
    @spec = toStrictMode(spec)
    ps = new poly.DataProcess(@spec, [], @spec.strict, poly.parser.pivotToData)
    ps.make @spec, [], @render

  generateTicks: (spec, statData, metaData) =>
    ticks = {}
    for aes in ['rows', 'columns']
      for item in spec[aes]
        key = item.var
        values = _.pluck(statData, key)
        domain = poly.domain.single(values, metaData[key], {})
        tick = poly.tick.make(domain, {}, metaData[key].type)
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
      key = @spec.columns[i].var
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
        cell = $("<td>#{value}</td>").attr('colspan', colspan*pivotMeta.nval)
        cell.attr('align', 'center')
        row.append(cell)
        j += colspan

      table.append(row)
      i++

    # VALUE headers
    row = $('<tr></tr>')
    if pivotMeta.nrow is 0
      ## SPACE
      space = $("<td></td>")
      space.attr('rowspan', rowHeaders.length+1)
      row.append(space)

    ## ROW header names
    i = 0
    while i < pivotMeta.nrow
      key = @spec.rows[i].var
      row.append $("<th>#{key}</th>").attr('align', 'center')
      i++
    k = 0
    while k < colHeaders.length
      for v in @spec.values
        cell = $("<td>#{v.var}</td>")
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
        key = key.var
        value = rowHeaders[i][key]
        if (i is 0) or value != rowHeaders[i-1][key]
          rowspan = 1
          while (i+rowspan < rowHeaders.length) and value == rowHeaders[i+rowspan][key]
            rowspan++
          # add a cell!!
          cell = $("<td>#{value}</td>").attr('rowspan', rowspan)
          cell.attr('align', 'center')
          cell.attr('valign', 'middle')
          row.append(cell)

      # ROW VALUES
      j = 0
      while j < colHeaders.length
        cols = colHeaders[j]
        rows = rowHeaders[i]

        for val in @spec.values
          v = pivotData.get(rows, cols, val.var)
          v = if v then formatters[val.var](v) else '-'
          row.append $("<td>#{v}</td>").attr('align', 'right')
        j++

      table.append(row)
      i++

    @dom = $('#'+@spec.dom)
    @dom.empty()
    @dom.append(table)

poly.pivot = (spec) -> new Pivot(spec)
