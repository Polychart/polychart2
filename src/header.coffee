# EXCEPTIONS
class NotImplemented extends Error

# GRAPHS
class Graph
  constructor: (input) ->
    graphSpec = spec

# DATA REALTED
class Data
  constructor: (input) ->
    @input = input

this.Data = Data

transformFactory = (transSpec) ->
  trans
class Transform
  constructor: (transSpec) ->
    @transSpec = transSpec
  mutate: (item) -> item

class Bin extends Transform
  mutate: (item) -> item
class Lag extends Transform
  mutate: (item) -> item


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
    trans = transformFactory(transSpec)
    _.each rawData (d) ->
      trans.mutate(d)
  # filter
  filter = filterFactory(dataSpec.filter)
  rawData = filter(rawData)
  # groupby
  groupeData = groupby(filterSpec, rawData)


  # computation
  callback(statData)

backendProcess = (dataSpec, rawData, callback) ->
  # computation
  callback(statData)



class Layer
  constructor: (layerSpec, statData) ->
    @spec = layerSpec
    @precalc = statData
  calculate: (statData) ->
    layerData

