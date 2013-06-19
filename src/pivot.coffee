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

    # figure out dimensions of the table
    NUMCOL = @spec.columns.length
    NUMROW = @spec.rows.length
    NUMVAL = @spec.values.length

    COL_FILL = 1
    COL_VALUES = []
    for colTicks in ticks.columns
      COL_FILL *= _.size(colTicks.ticks)
      COL_VALUES.push(COL_FILL)
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
    while i < ROW_FILL # total rows
      row = $('<tr></tr>')
      # ROW HEADERS
      for n, index in ROW_VALUES
        m = ROW_FILL / n
        if i % m is 0
          val = _.toArray(ticks.rows[index].ticks)[i / m]
          cell = $("<td>#{val.value}</td>").attr('colspan', m)
          row.append(cell)
      # ROW VALUES
      j = 0
      while j < COL_FILL
        j++

      table.append(row)
      i++

    @dom = $('#'+@spec.dom)
    @dom.empty()
    @dom.append(table)

poly.pivot = (spec) -> new Pivot(spec)
