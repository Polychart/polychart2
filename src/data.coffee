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
    _.reduceRight group, concat, ""

# STATS

statistics =
  sum : (spec) -> (values) -> _.sum values
  count : (spec) -> (values) -> values.length
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

# GENERAL PROCESSING

extractDataSpec = (layerSpec) -> dataSpec

frontendProcess = (dataSpec, rawData, callback) ->
  # TODO add metadata computation
  # TODO add sorting, limiting and secondary filters
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
