poly = @poly || {}
# DATA REALTED
class Data
  constructor: (params) ->
    {@url, @json} = params
    @frontEnd = !@url

# TRANFORMS
transforms =
  'bin' : (key, transSpec) ->
    {name, binwidth} = transSpec
    if _.isNumber binwidth
      binFn = (item) ->
        item[name] = binwidth * Math.floor item[key]/binwidth
      return trans: binFn, meta: {bw: binwidth, binned: true}
  'lag' : (key, transSpec) ->
    {name, lag} = transSpec
    lastn = (undefined for i in [1..lag])
    lagFn = (item) ->
      lastn.push(item[key])
      item[name] = lastn.shift()
    return trans: lagFn, meta:undefined

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
    groupedData = poly.groupBy data, statSpec.group
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

extractDataSpec = (layerSpec) -> {}

frontendProcess = (dataSpec, rawData, callback) ->
  # TODO add metadata computation to binning
  data = _.clone(rawData)
  # metaData and related f'ns
  metaData = {}
  addMeta = (key, meta) ->
    metaData[key] ?= {}
    _.extend metaData[key], meta
  # transforms
  if dataSpec.trans
    _.each dataSpec.trans, (transSpec, key) ->
      {trans, meta} = transformFactory(key, transSpec)
      _.each data, (d) -> trans(d)
      addMeta transSpec.name, meta
  # filter
  if dataSpec.filter
    data = _.filter data, filterFactory(dataSpec.filter)
  # meta + more filtering
  if dataSpec.meta
    additionalFilter = {}
    _.each dataSpec.meta, (metaSpec, key) ->
      {meta, filter} = calculateMeta(key, metaSpec, data)
      additionalFilter[key] = filter
      addMeta key, meta
    data = _.filter data, filterFactory(additionalFilter)
  # stats
  if dataSpec.stats
    groupedData = poly.groupBy data, dataSpec.stats.group
    data = _.map groupedData, statisticFactory(dataSpec.stats)
  # done
  callback(data, metaData)

backendProcess = (dataSpec, rawData, callback) ->
  # computation
  console.log 'backendProcess'

processData = (dataObj, layerSpec, strictmode, callback) ->
  dataSpec = extractDataSpec(layerSpec)
  if dataObj.frontEnd
    if strictmode
      callback dataObj.json, layerSpec
    else
      frontendProcess(dataSpec, dataObj.json, callback)
  else
    if strictmode
      console.log 'wtf, cant use strict mode here'
    else
      backendProcess(dataSpec, dataObj, callback)

# EXPORT
poly.Data = Data
poly.data =
  frontendProcess: frontendProcess
  processData: processData
@poly = poly
