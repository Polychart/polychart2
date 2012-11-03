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
class Group #singleton
  constructor: (groupSpec) ->
    @groupSepc = groupSpec
  compute: (data) -> data

class Statistic
  constructor: (statSpec) ->
    @statSpec = statSpec
  compute: (data) -> item
class Sum extends Statistic
  compute: (data) -> _.sum(data)
class Mean extends Statistic
  compute: (data) -> data
class Uniq extends Statistic
  compute: (data) -> data
class Count extends Statistic
  compute: (data) -> data
class Lm extends Statistic
  compute: (data) -> data
class Box extends Statistic
  compute: (data) -> data

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
  # groupby
  #groupeData = groupby(filterSpec, rawData)

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
