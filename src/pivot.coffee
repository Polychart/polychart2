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
  spec

class PivotProcessedData
  constructor: (@statData, @spec) ->
    @processedData = {}
    tmp_parent = null
    tmp_item = null
    for row in @statData
      tmp_parent = @processedData
      tmp = @processedData
      for aes in ['rows', 'columns']
        for item in @spec[aes]
          item = item.var
          tmp[row[item]] ?= {}
          tmp_parent = tmp
          tmp = tmp_parent[row[item]]
      tmp_parent[row[item]] = row
  get: (rows, columns, val) =>
    retvalue = @processedData
    for i in rows
      if retvalue? and retvalue[i]?
        retvalue = retvalue[i]
    for i in columns
      if retvalue? and retvalue[i]?
        retvalue = retvalue[i]
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

  calculateMeta: (spec, ticks) =>
    # calculate some dimensions & other information regarding the pivot table
    colTicks = (_.toArray(v.ticks) for v in ticks.columns)
    rowTicks = (_.toArray(v.ticks) for v in ticks.rows)
    meta =
      ncol: spec.columns.length
      nrow: spec.rows.length
      nval: spec.values.length
      rows: (v.var for v in spec.rows)
      cols: (v.var for v in spec.columns)
      vals: (v.var for v in spec.values)
      colTicks: colTicks
      colTickLen: (v.length for v in colTicks)
      rowTicks: rowTicks
      rowTickLen: (v.length for v in rowTicks)

    tmp = 1
    meta.colFill = []
    for i in meta.colTickLen
      tmp *= i
      meta.colFill.push(tmp)
    meta.colTotal = tmp

    tmp = 1
    meta.rowFill = []
    for i in meta.rowTickLen
      tmp *= i
      meta.rowFill.push(tmp)
    meta.rowTotal = tmp

    meta


  generateTicks: (spec, statData, metaData) =>
    domains = {}
    ticks = {}
    for aes in ['rows', 'columns']
      domains[aes] = []
      ticks[aes] = []
      for item in spec[aes]
        values = _.pluck(statData, item.var)
        domain = poly.domain.single(values, metaData[item.var], {})
        tick = poly.tick.make(domain, {}, metaData[item.var].type)
        domains[aes].push(domain)
        ticks[aes].push(tick)
    ticks

  render: (err, statData, metaData) =>
    # create domains & ticks
    ticks = @generateTicks(@spec, statData, metaData)
    pivotData = new PivotProcessedData(statData, @spec)
    pivotMeta = @calculateMeta(@spec, ticks)

    # render a table...
    if not $
      throw poly.error.depn "Pivot Tables require jQuery!"

    table = $('<table></table>')
    # counters
    i = 0
    filled = 1
    tofill = pivotMeta.colTotal * pivotMeta.nval
    #  COLUMN headers
    while i < pivotMeta.ncol
      row = $('<tr></tr>')
      if i is 0 # first row
        space = $('<td></td>')
        if pivotMeta.nval is 1
          space.attr('rowspan', pivotMeta.ncol)
        else
          space.attr('rowspan', pivotMeta.ncol+1)
        space.attr('colspan', pivotMeta.nrow)
        row.append(space)
      tofill /= pivotMeta.colTickLen[i]
      for k in [1..filled]
        for tick in pivotMeta.colTicks[i]
          cell = $("<td>#{tick.value}</td>").attr('colspan', tofill)
          row.append(cell)
      filled*= pivotMeta.colTickLen[i]
      table.append(row)
      i++

    # VALUE headers
    if pivotMeta.nval isnt 1
      row = $('<tr></tr>')
      for k in [1..filled]
        for v in @spec.values
          cell = $("<td>#{v.var}</td>")
          row.append(cell)
      table.append(row)
    # REST OF TABLE
    i = 0
    rows_mindex = []
    cols_mindex = []
    while i < pivotMeta.rowTotal # total rows
      row = $('<tr></tr>')
      # ROW HEADERS
      for n, index in pivotMeta.rowFill
        m = pivotMeta.rowTotal / n
        if i % m is 0
          val = _.toArray(ticks.rows[index].ticks)[i / m]
          cell = $("<td>#{val.value}</td>").attr('rowspan', m)
          rows_mindex[index] = val.value
          row.append(cell)

      # ROW VALUES
      j = 0
      debugger
      while j < pivotMeta.colTotal
        for n2, index2 in pivotMeta.colFill
          len = pivotMeta.colTickLen[index2]
          m2 = pivotMeta.colTotal / n2

          if j % m2 is 0
            val = _.toArray(ticks.columns[index2].ticks)[(j/m2) % len]
            cols_mindex[index2] = val.value

        for val in @spec.values
          v = pivotData.get(rows_mindex, cols_mindex, val.var)
          row.append $("<td>#{v ? '-'}</td>")
        j++

      table.append(row)
      i++

    @dom = $('#'+@spec.dom)
    @dom.empty()
    @dom.append(table)

poly.pivot = (spec) -> new Pivot(spec)
