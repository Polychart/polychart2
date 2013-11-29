###
Wrapper around the data processing piece that keeps track of the kind of
data processing to be done.
###

class DataProcess
  ## save the specs
  constructor: (layerSpec, grouping, strictmode, @parseMethod=poly.spec.layerToData) ->
    @layerMeta  = _.extend {}, layerSpec.meta, _additionalInfo: layerSpec.additionalInfo
    @dataObj    = layerSpec.data
    @prevSpec   = null
    @strictmode = strictmode
    @statData   = null
    @metaData   = {}

  ## calculate things...
  make : (spec, grouping, callback) =>
    wrappedCallback = @_wrap callback
    if @strictmode
      wrappedCallback
        data: @dataObj.raw
        meta: @dataObj.meta
    if @dataObj.computeBackend
      dataSpec = @parseMethod spec, grouping
      if @layerMeta then dataSpec.meta = @layerMeta
      backendProcess(dataSpec, @dataObj, wrappedCallback)
    else
      dataSpec = @parseMethod spec, grouping
      @dataObj.getData (err, data) ->
        if err? then return wrappedCallback err, null

        # Hack to get 'count(*)' to behave properly
        if 'count(*)' in dataSpec.select
          for obj in data.data
            obj['count(*)'] = 1
          data.meta['count(*)'] = {}
          data.meta['count(*)']['type'] = 'num'
          dataSpec.stats.stats.push {key: 'count(*)', name: 'count(*)', stat: 'count'}
        frontendProcess(dataSpec, data, wrappedCallback)

  _wrap : (callback) => (err, params) =>
    if err? then return callback err, null, null

    # save a copy of the data/meta before going to callback
    {data, meta} = params
    @statData = data
    @metaData = meta
    callback null, @statData, @metaData

poly.DataProcess = DataProcess

###
Temporary
###
poly.data.process = (dataObj, layerSpec, strictmode, callback) ->
  d = new DataProcess layerSpec, strictmode
  d.process callback
  d

###
TRANSFORMS
----------
Functions to interpret the arithmetic and other expressions --
###

evaluate =
  ident: (name) -> (row) ->
    if name of row
      return row[name]
    throw poly.error.defn "Referencing unknown column: #{name}"
  const: (value) -> () -> value
  conditional: (cond, conseq, altern) -> (row) ->
    if cond(row) then conseq(row) else altern(row)
  infixop:
    "+": (lhs, rhs) -> (row) -> lhs(row) + rhs(row)
    "-": (lhs, rhs) -> (row) -> lhs(row) - rhs(row)
    "*": (lhs, rhs) -> (row) -> lhs(row) * rhs(row)
    "/": (lhs, rhs) -> (row) -> lhs(row) / rhs(row)
    "%": (lhs, rhs) -> (row) -> lhs(row) % rhs(row)
    ">": (lhs, rhs) -> (row) -> lhs(row) > rhs(row)
    ">=": (lhs, rhs) -> (row) -> lhs(row) >= rhs(row)
    "<": (lhs, rhs) -> (row) -> lhs(row) < rhs(row)
    "<=": (lhs, rhs) -> (row) -> lhs(row) <= rhs(row)
    "!=": (lhs, rhs) -> (row) -> lhs(row) != rhs(row)
    "==": (lhs, rhs) -> (row) -> lhs(row) == rhs(row)
    "=": (lhs, rhs) -> (row) -> lhs(row) == rhs(row)
    "++": (lhs, rhs) -> (row) -> lhs(row) + rhs(row)
  trans:
    "substr": (args) -> (row) ->
      str = args[0](row).toString()
      start = args[1](row)
      end = args[2](row)
      str.substr(start, end)
    "length": (args) -> (row) ->
      str = args[0](row).toString()
      _.size(str)
    "upper": (args) -> (row) ->
      str = args[0](row).toString()
      str.toUpperCase()
    "lower": (args) -> (row) ->
      str = args[0](row).toString()
      str.toLowerCase()
    "indexOf": (args) -> (row) ->
      haystack = args[0](row).toString()
      needle = args[1](row).toString()
      haystack.indexOf(needle)
    "parseNum": (args) -> (row) ->
      str = args[0](row).toString()
      +str
    "parseDateDefault": (args) -> (row) ->
      str = args[0](row)
      moment(str).unix()
    "parseDate": (args) -> (row) ->
      str = args[0](row)
      format = args[1](row)
      moment(str, format).unix()
    "year": (args) -> (row) ->
      ts = args[0](row)
      moment.unix(ts).year()
    "month": (args) -> (row) ->
      ts = args[0](row)
      moment.unix(ts).month()+1 # make it 1-indexed
    "dayOfMonth": (args) -> (row) ->
      ts = args[0](row)
      moment.unix(ts).date()
    "dayOfYear": (args) -> (row) ->
      ts = args[0](row)
      moment.unix(ts).dayOfYear()
    "dayOfWeek": (args) -> (row) ->
      ts = args[0](row)
      moment.unix(ts).day()
    "hour": (args) -> (row) ->
      ts = args[0](row)
      moment.unix(ts).hour()
    "minute": (args) -> (row) ->
      ts = args[0](row)
      moment.unix(ts).minute()
    "second": (args) -> (row) ->
      ts = args[0](row)
      moment.unix(ts).second()


    "log": (args) -> (row) -> Math.log(args[0](row))
    "lag": (args) ->
      lastn = []
      (row) ->
        val = args[0](row)
        lag = args[1](row) # need to be a const!
        currentLag = _.size(lastn)
        if currentLag is 0
          lastn = (undefined for i in [1..lag])
        else if currentLag isnt lag
          throw poly.error.defn "Lag period needs to be constant, but isn't!"
        lastn.push(val)
        lastn.shift()
    "bin": (args) -> (row) ->
      val = args[0](row)
      bw = args[1](row) # we actually need args[1] to be a const... :(
      # numeric
      if _.isNumber(bw)
        return Math.floor(val/bw)*bw
      # non-numeric
      _timeBinning = (n, timerange) =>
        m = moment.unix(val).startOf(timerange)
        m[timerange] n * Math.floor(m[timerange]()/n)
        m.unix()
      switch bw
        when 'week' then moment.unix(val).day(0).unix()
        when 'twomonth' then _timeBinning 2, 'month'
        when 'quarter' then _timeBinning 4, 'month'
        when 'sixmonth' then _timeBinning 6, 'month'
        when 'twoyear' then _timeBinning 2, 'year'
        when 'fiveyear' then _timeBinning 5, 'year'
        when 'decade' then _timeBinning 10, 'year'
        else moment.unix(val).startOf(bw).unix()

createFunction = (node) ->
  [nodeType, payload] = node
  fn =
    if nodeType is 'ident'
      evaluate.ident(payload.name)
    else if nodeType is 'const'
      value = poly.type.coerce(payload.value, {type: payload.type})
      evaluate.const(value)
    else if nodeType is 'infixop'
      lhs = createFunction(payload.lhs)
      rhs = createFunction(payload.rhs)
      evaluate.infixop[payload.opname](lhs, rhs)
    else if nodeType is 'conditional'
      cond = createFunction(payload.cond)
      conseq = createFunction(payload.conseq)
      altern = createFunction(payload.altern)
      evaluate.conditional(cond, conseq, altern)
    else if nodeType is 'call'
      args = (createFunction(arg) for arg in payload.args)
      evaluate.trans[payload.fname](args) # should all be transforms
  if fn then return fn
  throw poly.error.defn "Unknown operation of type: #{nodeType}"

###
FILTERS
----------
Key:value pair of available filtering operations to filtering function. The
filtering function returns true iff the data item satisfies the filtering
criteria.
###
filters =
  'lt' : (x, value) -> x < value
  'le' : (x, value) -> x <= value
  'gt' : (x, value) -> x > value
  'ge' : (x, value) -> x >= value
  'in' : (x, value) -> x in value

###
Helper function to figures out which filter to create, then creates it
###
filterFactory = (filterSpec) ->
  filterFuncs = []
  _.each filterSpec, (filter) ->
    key = poly.parser.unbracket filter.expr.name
    spec = _.pick(filter, 'lt', 'gt', 'le', 'ge', 'in')
    _.each spec, (value, predicate) ->
      return if predicate not of filters
      filter = (item) -> filters[predicate](item[key], value)
      filterFuncs.push filter
  (item) ->
    for f in filterFuncs
      if not f(item) then return false
    return true

###
STATISTICS
----------
Key:value pair of available statistics operations to a function that creates
the appropriate statistical function given the spec. Each statistics function
produces one atomic value for each group of data.
###
statistics =
  sum : (values) -> _.reduce(_.without(values, undefined, null),
                                                 ((v, m) -> v + m), 0)
  mean: (values) ->
    values = _.without(values, undefined, null)
    return _.reduce(values, ((v, m) -> v + m), 0) / values.length
  count : (values) -> _.without(values, undefined, null).length
  unique : (values) -> (_.uniq(_.without(values, undefined, null))).length
  min: (values) -> _.min(values)
  max: (values) -> _.max(values)
  median: (values) -> poly.median(values)
  box: (values) ->
    len = values.length
    if len > 5
      mid = len/2
      sortedValues = _.sortBy(values, (x)->x)
      quarter = Math.ceil(mid)/2
      if quarter % 1 != 0
          quarter = Math.floor(quarter)
          q2 = sortedValues[quarter]
          q4 = sortedValues[(len-1)-quarter]
      else
          q2 = (sortedValues[quarter] + sortedValues[quarter-1])/2
          q4 = (sortedValues[len-quarter] + sortedValues[(len-quarter)-1])/2
      iqr = q4-q2
      lowerBound = q2-(1.5*iqr)
      upperBound = q4+(1.5*iqr)
      splitValues = _.groupBy(sortedValues,
                              (v) -> v >= lowerBound and v <= upperBound)
      return {
        q1: _.min(splitValues.true)
        q2: q2
        q3: poly.median(sortedValues, true)
        q4: q4
        q5: _.max(splitValues.true)
        outliers: splitValues.false ? []
      }
    return {
      outliers: values
    }

###
Calculate statistics
###
calculateStats = (data, statSpecs) ->
  # define stat functions
  statFuncs = {}
  _.each statSpecs.stats, (statSpec) ->
    {name, expr, args} = statSpec
    fn = statistics[name]
    key = poly.parser.unbracket(args[0].name)
    statFuncs[expr.name] = (data) -> fn _.pluck(data, key)
  # calculate the statistics for each group
  groupedData = poly.groupBy data, (poly.parser.unbracket(e.name) for e in statSpecs.groups)
  _.map groupedData, (data) ->
    rep = {}
    for {name} in statSpecs.groups
      name = poly.parser.unbracket(name)
      rep[name] = data[0][name] # define a representative
    for name, stats of statFuncs
      rep[name] = stats(data) # calc stats
    return rep

###
META SORTING
------------
Calculations of meta properties including sorting and limiting based on the
values of statistical calculations
###
calculateMeta = (metaSpec, data) ->
  {key, sort, stat, args, limit, asc} = metaSpec
  # group the data by the key
  if stat
    statSpec =
      stats: [{name:stat, expr: sort, args: args}]
      groups: [key]
    data = calculateStats(data, statSpec)
  # sorting
  multiplier = if asc then 1 else -1
  sortKey = poly.parser.unbracket sort.name
  comparator = (a, b) ->
    if a[sortKey] == b[sortKey] then return 0
    if a[sortKey] >= b[sortKey] then return 1 * multiplier
    return -1 * multiplier
  data.sort comparator
  # limiting
  if limit
    data = data[0..limit-1]
  values = _.uniq _.pluck data, poly.parser.unbracket key.name
  return {
    meta: { levels: values, sorted: true}
    filter: {expr: key, in: values}
  }

###
GENERAL PROCESSING
------------------
Figure out what the metadata of a column should be based on what we know about
other columns, and by the expression
###
interpretMeta = (metas) ->
  typeEnv = poly.parser.createColTypeEnv(metas)
  (expr) ->
    [rootType, payload] = expr.expr
    bw = null
    if rootType is 'call' and payload.fname is 'bin'
      [innerType, innerPayload] = payload.args[1]
      if innerType is 'const'
        bw = poly.type.coerce(innerPayload.value, {type: innerPayload.type})
    type: poly.parser.getType(expr.name, typeEnv)
    bw: bw


###
GENERAL PROCESSING
------------------
Coordinating the actual work being done
###

###
Perform the necessary computation in the front end
###
frontendProcess = (dataSpec, data, callback) ->
  # metaData and related f'ns
  metaData = _.clone(data.meta) ? {}
  getMeta = interpretMeta(metaData)
  addMeta = (expr, meta={}) ->
    metaData[expr.name] = _.extend (metaData[expr.name] ? {}), getMeta(expr), meta
  # data & related f'ns
  data = _.clone(data.raw)
  addData = (key, fn) ->
    for d in data
      d[key] = fn(d)
  # transforms
  if dataSpec.trans
    for expr in dataSpec.trans
      addData(expr.name, createFunction(expr.expr))
      addMeta(expr)
  # filter
  if dataSpec.filter
    data = _.filter data, filterFactory(dataSpec.filter)
  # meta + more filtering
  if dataSpec.sort
    additionalFilter = []
    for metaSpec in dataSpec.sort
      key = metaSpec.key
      {meta, filter} = calculateMeta(metaSpec, data)
      additionalFilter.push(filter)
      addMeta key, meta
    data = _.filter data, filterFactory(additionalFilter)
  # stats
  if dataSpec.stats and dataSpec.stats.stats and dataSpec.stats.stats.length > 0
    data = calculateStats(data, dataSpec.stats)
    for statSpec in dataSpec.stats.stats
      {expr} = statSpec
      addMeta(expr)
  # select: make sure everything selected is there
  for key in dataSpec.select ? []
    name = poly.parser.unbracket(key.name)
    if not metaData[name]? and name isnt 'count(*)'
      throw poly.error.defn ("You referenced a data column #{name} that doesn't exist.")
  # done
  callback(null, data:data, meta:metaData)

###
Perform the necessary computation in the backend
###
backendProcess = (dataSpec, dataObj, callback) ->
  dataObj.getData callback, dataSpec

###
For debug purposes only
###
poly.data.frontendProcess = frontendProcess
poly.data.createFunction = createFunction
