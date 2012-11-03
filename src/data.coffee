# DATA REALTED
class Data
  constructor: (params) ->
    {@url, @json} = params
    @frontEnd = !!@url

# TRANFORMS
trans_bin = (key, transSpec) ->
  name = transSpec.name
  binwidth = transSpec.binwidth
  if _.isNumber binwidth
    return (item) ->
      item[name] = binwidth * Math.floor item[key]/binwidth

trans_lag = (key, transSpec) ->
  name = transSpec.name
  lag = transSpec.lag
  lastn = (undefined for i in [1..lag])
  return (item) ->
    lastn.push(item[key])
    item[name] = lastn.shift()

transformFactory = (key, transSpec) ->
  switch transSpec.trans
    when "bin" then return trans_bin(key, transSpec)
    when "lag" then return trans_lag(key, transSpec)

# FILTERS
filterFactory = (filterSpec) ->
  filterFuncs = []
  _.each filterSpec, (spec, key) ->
    _.each spec, (value, predicate) ->
      filterFuncs.push constraintFunc predicate, value, key
  (item) ->
    for f in filterFuncs
      if not f(item) then return false
    return true

constraintFunc = (predicate, value, key) ->
  switch predicate
    when 'lt' then return (x) -> x[key] < value
    when 'le' then return (x) -> x[key] <= value
    when 'gt' then return (x) -> x[key] > value
    when 'ge' then return (x) -> x[key] >= value
    when 'in' then return (x) -> x[key] in value

# GROUPING

groupByFunc = (group) ->
  (item) ->
    concat = (memo, g) -> "#{memo}#{g}:#{item[g]};"
    _.reduceRight group, concat, ""

# STATS
statisticFactory = (statSpecs) ->
  group = statSpecs.group
  statistics = []
  _.each statSpecs.stats, (statSpec, key) ->
    statistics.push singleStatsFunc(key, statSpec, group)
  (data) ->
    rep = {}; _.each group, (g) -> rep[g] = data[0][g] # define a representative
    _.each statistics, (stats) ->
      stats(data, rep)
    return rep

singleStatsFunc = (key, statSpec, group) ->
  name = statSpec.name
  stat = switch statSpec.stat
    when 'sum' then stat_sum(key, statSpec, group)
    when 'count' then stat_count(key, statSpec, group)
    when 'uniq' then stat_uniq(key, statSpec, group)
  (data, rep) ->
    rep[name] = stat _.pluck data, key

stat_sum = (key, spec, group) -> (values) -> _.sum values

stat_count = (key, spec, group) -> (values) -> values.length

stat_uniq = (key, spec, group) -> (values) -> (_.uniq values).length

# GENERAL PROCESSING

extractDataSpec = (layerSpec) -> dataSpec

frontendProcess = (dataSpec, rawData, callback) ->
  data = _.clone(rawData)
  # transforms
  if dataSpec.trans
    _.each dataSpec.trans, (transSpec, key) ->
      trans = transformFactory(key, transSpec)
      _.each data, (d) ->
        trans(d)
  # filter
  if dataSpec.filter
    data = _.filter data, filterFactory(dataSpec.filter)
  # stats
  if dataSpec.stats
    groupedData = _.groupBy data, groupByFunc(dataSpec.stats.group)
    data = _.map groupedData, statisticFactory(dataSpec.stats)


  # computation
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
