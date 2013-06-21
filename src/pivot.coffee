##
# Pivot table object and entry point: poly.pivot()
# ------------------------------------------------
# TODO: write more comments
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

  render: (err, statData, metaData) =>
    # create domains & ticks
    domains = {}
    ticks = {}
    for aes in ['rows', 'columns']
      domains[aes] = []
      ticks[aes] = []
      for item in @spec[aes]
        values = _.pluck(statData, item.var)
        domain = poly.domain.single(values, metaData[item.var], {})
        tick = poly.tick.make(domain, {}, metaData[item.var].type)
        domains[aes].push(domain)
        ticks[aes].push(tick)

    pivotData = new PivotProcessedData(statData, @spec)

    # figure out dimensions of the table
    NUMCOL = @spec.columns.length
    NUMROW = @spec.rows.length
    NUMVAL = @spec.values.length

    COL_FILL = 1
    COL_VALUES = []
    COL_TICKS = []
    for colTicks in ticks.columns
      t = _.size(colTicks.ticks)
      COL_TICKS.push(t)
      COL_FILL *= t
      COL_VALUES.push(COL_FILL)
    COL_TOTAL = COL_FILL
    COL_FILL *= NUMVAL
    COL_TOFILL = 1

    ROW_FILL = 1
    ROW_VALUES = []
    for rowTicks in ticks.rows
      ROW_FILL *= _.size(rowTicks.ticks)
      ROW_VALUES.push(ROW_FILL)

    # render a table...
    if not $
      throw poly.error.depn "Pivot Tables require jQuery!"

    table = $('<table></table>')
    i = 0
    #  COLUMN headers
    while i < NUMCOL
      row = $('<tr></tr>')
      if i is 0 # first row
        space = $('<td></td>')
        if NUMVAL is 1
          space.attr('rowspan', NUMCOL)
        else
          space.attr('rowspan', NUMCOL+1)
        space.attr('colspan', NUMROW)
        row.append(space)
      colTicks = ticks.columns[i]
      size = _.size(colTicks.ticks)
      COL_FILL /= size
      for k in [1..COL_TOFILL]
        for key, tick of colTicks.ticks
          cell = $("<td>#{tick.value}</td>").attr('colspan', COL_FILL)
          row.append(cell)
      COL_TOFILL *= size
      table.append(row)
      i++
    # VALUE headers
    if NUMVAL isnt 1
      row = $('<tr></tr>')
      for k in [1..COL_TOFILL]
        for v in @spec.values
          cell = $("<td>#{v.var}</td>")
          row.append(cell)
      table.append(row)
    # REST OF TABLE
    i = 0
    rows_mindex = []
    cols_mindex = []
    while i < ROW_FILL # total rows
      row = $('<tr></tr>')
      # ROW HEADERS
      for n, index in ROW_VALUES

        m = ROW_FILL / n
        if i % m is 0
          val = _.toArray(ticks.rows[index].ticks)[i / m]
          cell = $("<td>#{val.value}</td>").attr('colspan', m)
          rows_mindex[index] = val.value
          row.append(cell)

      # ROW VALUES
      j = 0
      while j < COL_TOTAL
        for n2, index2 in COL_VALUES
          len = COL_TICKS[index2]
          m2 = COL_TOTAL / n2

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
