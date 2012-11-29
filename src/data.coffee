poly = @poly || {}

###
# GLOBALS
###

###
Generalized data object that either contains JSON format of a dataset,
or knows how to retrieve data from some source.
###
class Data
  constructor: (params) ->
    {@url, @json} = params
    @frontEnd = !@url
  update: (json) ->
    @json = json

poly.Data = Data

###
Wrapper around the data processing piece that keeps track of the kind of
data processing to be done.
###
class DataProcess
  ## save the specs
  constructor: (layerSpec, strictmode) ->
    @dataObj = layerSpec.data
    @initialSpec = extractDataSpec layerSpec
    @prevSpec = null
    @strictmode = strictmode
    @statData = null
    @metaData = {}

  reset : (callback) -> @make @initialSpec, callback

  ## calculate things...
  make : (spec, callback) ->
    dataSpec = extractDataSpec spec
    #if prevSpec? and prevSpec == dataSpec
    #  return callback @statData, @metaData

    wrappedCallback = @_wrap callback
    if @dataObj.frontEnd
      if @strictmode
        wrappedCallback @dataObj.json, {}
      else
        frontendProcess(dataSpec, @dataObj.json, wrappedCallback)
    else
      if @strictmode
        throw new poly.StrictModeError()
      else
        backendProcess(dataSpec, @dataObj, wrappedCallback)

  _wrap : (callback) => (data, metaData) =>
    # save a copy of the data/meta before going to callback
    @statData = data
    @metaData = metaData
    callback @statData, @metaData

poly.DataProcess = DataProcess

###
Temporary
###
poly.data = {}
poly.data.process = (dataObj, layerSpec, strictmode, callback) ->
  d = new DataProcess layerSpec, strictmode
  d.process callback
  d

###
TRANSFORMS
----------
Key:value pair of available transformations to a function that creates that
transformation. Also, a metadata description of the transformation is returned
when appropriate. (e.g for binning)
###
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

###
Helper function to figures out which transformation to create, then creates it
###
transformFactory = (key, transSpec) ->
  transforms[transSpec.trans](key, transSpec)

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
  _.each filterSpec, (spec, key) ->
    _.each spec, (value, predicate) ->
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
  sum : (spec) -> (values) -> _.reduce(_.without(values, undefined, null),
                                                 ((v, m) -> v + m), 0)
  count : (spec) -> (values) -> _.without(values, undefined, null).length
  uniq : (spec) -> (values) -> (_.uniq(_.without(values, undefined, null))).length
  min: (spec) -> (values) -> _.min(values)
  max: (spec) -> (values) -> _.max(values)
  median: (spec) -> (values) -> poly.median(values)
  box: (spec) -> (values) ->
    len = values.length
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
        outliers: splitValues.false
           }
###
Helper function to figures out which statistics to create, then creates it
###
statsFactory = (statSpec) ->
  statistics[statSpec.stat](statSpec)

###
Calculate statistics
###
calculateStats = (data, statSpecs) ->
  # define stat functions
  statFuncs = {}
  _.each statSpecs.stats, (statSpec) ->
    {key, name} = statSpec
    statFn = statsFactory statSpec
    statFuncs[name] = (data) -> statFn _.pluck(data, key)
  # calculate the statistics for each group
  groupedData = poly.groupBy data, statSpecs.group
  _.map groupedData, (data) ->
    rep = {}
    _.each statSpecs.group, (g) -> rep[g] = data[0][g] # define a representative
    _.each statFuncs, (stats, name) -> rep[name] = stats(data) # calc stats
    return rep

###
META
----
Calculations of meta properties including sorting and limiting based on the
values of statistical calculations
###
calculateMeta = (key, metaSpec, data) ->
  {sort, stat, limit, asc} = metaSpec
  # group the data by the key
  if stat
    statSpec = stats: [stat], group: [key]
    data = calculateStats(data, statSpec)
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

###
GENERAL PROCESSING
------------------
Coordinating the actual work being done
###

###
Given a layer spec, extract the data calculations that needs to be done.
###
extractDataSpec = (layerSpec) -> {}

###
Perform the necessary computation in the front end
###
frontendProcess = (dataSpec, rawData, callback) ->
  data = _.clone(rawData)
  # metaData and related f'ns
  metaData = {}
  addMeta = (key, meta) -> _.extend (metaData[key] ? {}), meta
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
    data = calculateStats(data, dataSpec.stats)
  # done
  callback(data, metaData)

###
Perform the necessary computation in the backend
###
backendProcess = (dataSpec, rawData, callback) ->
  # computation
  console.log 'backendProcess'

###
For debug purposes only
###
poly.data.frontendProcess = frontendProcess

###
# EXPORT
###
@poly = poly
