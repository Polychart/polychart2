# DATA REALTED
class Data
  constructor: (params) ->
    {@url, @json} = params
    @frontEnd = !!@url

# TRANFORMS
transforms =
  'bin' : (key, transSpec) ->
    {name, binwidth} = transSpec
    if _.isNumber binwidth
      return (item) ->
        item[name] = binwidth * Math.floor item[key]/binwidth
  'lag' : (key, transSpec) ->
    {name, lag} = transSpec
    lastn = (undefined for i in [1..lag])
    return (item) ->
      lastn.push(item[key])
      item[name] = lastn.shift()

transformFactory = (key, transSpec) ->
  transforms[transSpec.trans](key, transSpec)

# FILTERS

filters =
  'lt' : (x, value) -> x < value
  'le' : (x, value) -> x <= value
  'gt' : (x, value) -> x > value
  'ge' : (x, value) -> x >= value
  'in' : (x, value) -> x in value

filterFactory = (filterSpec) ->
  filterFuncs = []
  _.each filterSpec, (spec, key) ->
    _.each spec, (value, predicate) ->
      filter = (item) -> filters[predicate](item[key], value)
      filterFuncs.push filter
  (item) ->
    for f in filterFuncs
      if not f(item) then return false
    return true

# GROUPING

groupByFunc = (group) ->
  (item) ->
    concat = (memo, g) -> "#{memo}#{g}:#{item[g]};"
    _.reduce group, concat, ""

# STATS

statistics =
  sum : (spec) -> (values) ->
    memo = 0
    for v in values
      memo += v
    return memo
  count : (spec) -> (values) ->
    return values.length
  uniq : (spec) -> (values) -> (_.uniq values).length

statisticFactory = (statSpecs) ->
  group = statSpecs.group
  statFuncs = {}
  _.each statSpecs.stats, (statSpec) ->
    {stat, key, name} = statSpec
    statFn = statistics[stat](statSpec)
    statFuncs[name] = (data) -> statFn _.pluck(data, key)
  (data) ->
    rep = {}
    _.each group, (g) -> rep[g] = data[0][g] # define a representative
    _.each statFuncs, (stats, name) -> rep[name] = stats(data)
    return rep

# META

calculateMeta = (key, metaSpec, data) ->
  # note: data = array
  {sort, stat, limit, asc} = metaSpec
  # stats
  if stat
    statSpec = stats: [stat], group: [key]
    groupedData = _.groupBy(data, groupByFunc(statSpec.group))
    data = _.map groupedData, statisticFactory(statSpec)
  # sorting
  multiplier = if asc then 1 else -1
  comparator = (a, b) ->
    if a[sort] == b[sort] then return 0
    if a[sort] >= b[sort] then return 1 * multiplier
    return -1 * multiplier
  data.sort comparator
  # limiting
  if limit
    data = data[0..limit-1]
  values = _.uniq _.pluck data, key
  return meta: { levels: values, sorted: true}, filter: { in: values}

# GENERAL PROCESSING

extractDataSpec = (layerSpec) -> dataSpec

frontendProcess = (dataSpec, rawData, callback) ->
  # TODO add metadata computation to binning
  data = _.clone(rawData)
  metaData = {}
  # transforms
  if dataSpec.trans
    _.each dataSpec.trans, (transSpec, key) -> #the spec here should be like stats
      trans = transformFactory(key, transSpec)
      _.each data, (d) ->
        trans(d)
  # filter
  if dataSpec.filter
    data = _.filter data, filterFactory(dataSpec.filter)
  # meta + more filtering
  if dataSpec.meta
    additionalFilter = {}
    _.each dataSpec.meta, (metaSpec, key) ->
      {meta, filter} = calculateMeta(key, metaSpec, data)
      metaData[key] = meta
      additionalFilter[key] = filter
    data = _.filter data, filterFactory(additionalFilter)

  # stats
  if dataSpec.stats
    groupedData = _.groupBy data, groupByFunc(dataSpec.stats.group)
    data = _.map groupedData, statisticFactory(dataSpec.stats)
  # done
  callback(data)

backendProcess = (dataSpec, rawData, callback) ->
  # computation
  callback(statData)

processData = (dataObj, layerSpec, callback) ->
  dataSpec = extractDataSpec(layerSpec)
  if dataObj.frontEnd
    frontendProcess(dataSpec, layerSpec, callback)
  else
    backendProcess(dataSpec, layerSpec, callback)

@frontendProcess = frontendProcess
@processData = processData
@Data = Data
