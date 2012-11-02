# DATA REALTED
class Data
  constructor: (params) ->
    {@url, @json} = params
    @frontEnd = !!@url

class Transform
  constructor: (key, transSpec) ->
    @key = key
    @name = transSpec.name
    @transSpec = transSpec
    @mutate = @getMutateFunction()
  getMutateFunction: () =>

class Bin extends Transform
  getMutateFunction: () =>
    @binwidth = @transSpec.binwidth
    if _.isNumber @binwidth
      return (item) ->
        item[@name] = @binwidth * Math.floor item[@key]/@binwidth

class Lag extends Transform
  getMutateFunction: () =>
    @lag = @transSpec.lag
    @lastn = (undefined for i in [1..@lag])
    return (item) ->
      @lastn.push(item[@key])
      item[@name] = @lastn.shift()

transformFactory = (key,transSpec) ->
  switch transSpec.trans
    when "bin" then return new Bin(key, transSpec)
    when "lag" then return new Lag(key, transSpec)

filterFactory = (filterSpec) ->
  idontknow
class Filter #singleton
  constructor: (filterSpec) ->
    @filterSpec = filterSpec
  mutate: (data) -> data

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
  # transforms
  _.each dataSpec.trans, (transSpec, key) ->
    trans = transformFactory(key, transSpec)
    _.each rawData, (d) ->
      trans.mutate(d)
  ###
  # filter
  filter = filterFactory(dataSpec.filter)
  rawData = filter(rawData)
  # groupby
  groupeData = groupby(filterSpec, rawData)
  ###

  # computation
  callback(rawData)

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
