###
Data Object
---------
Polychart wrapper around a data set. This is contains the data structure
required for poly.chart().  Data object that either contains JSON format
of a dataset, or knows how to retrieve data from some source.
###

poly.data = (blob) ->
  type = undefined
  data = undefined
  meta = undefined
  if _.isObject(blob) and _.keys(blob).length < 4 and 'data' of blob
    data = blob.data
    meta = blob.meta
  else
    data = blob
  if _.isObject data or _.isArray data
    poly.data.json(data, meta)
  else if _.isString data
    if poly.isURI data
      poly.data.csv(data, meta)
    else
      poly.data.csv(data, meta)
  else
    poly.error.data "Unknown data format."

poly.data.json = (data, meta) ->
  new FrontendData json: data, meta:meta

poly.data.csv = (data, meta) ->
  new FrontendData csv: data, meta:meta

poly.data.url = (url, computeBackend, limit) ->
  new BackendData {url, computeBackend, limit}

###
Helper functions
###
_getArray = (json, meta) ->
  # array of objects [{foo:2, bar:4}, {foo:2, bar:3}, ...]
  if json.length > 0
    keys = _.union _.keys(meta), _.keys(json[0])
    first100 = json[0..99]
    for key in keys
      meta[key] ?= {}
      if not meta[key].type
        meta[key].type = poly.type.impute _.pluck(first100, key)
    for item in json
      for key in keys
        item[key] = poly.type.coerce item[key], meta[key]
    key = keys
    raw = json
  else
    key = _.keys(meta)
    raw = []
  {key, raw, meta}

_getArrayOfArrays = (json, meta) ->
  # array of arrays [[1,2,3],[1,2,3],...]
  retobj = []
  if json.length > 0
    keys =
      if meta and _.isArray(meta)
        meta
      else if meta and _.isObject(meta)
        _.keys(meta)
      else
        _.keys(json[0])
    if _.isArray(meta) or not _.isObject(meta)
      meta = {}
    first100 = json[0..99]
    for key, i in keys
      meta[key] ?= {}
      if not meta[key].type
        meta[key].type = poly.type.impute _.pluck(first100, i)
    for item in json
      newitem = {}
      for value, i in item
        key = keys[i]
        newitem[key] = poly.type.coerce value, meta[key]
      retobj.push(newitem)
    key = keys
    raw = retobj
  else
    key = _.keys(meta)
    raw = []
  {key, raw, meta}

_getObject = (json, meta) ->
  keys = _.keys(json)
  raw = []
  for key in keys
    meta[key] ?= {}
    if not meta[key].type
      meta[key].type = poly.type.impute json[key][0..99]
  if keys.length > 0
    len = json[keys[0]].length
    if len > 0
      for i in [0..len-1]
        obj = {}
        for k in keys
          obj[k] = poly.type.coerce json[k][i], meta[k]
        raw.push(obj)
  key = keys
  {key, raw, meta}

_getCSV = (str, meta) ->
  _getArray poly.csv.parse(str), meta

###
Classes
###
class AbstractData
  isData: true
  constructor: () ->
    @raw = null
    @meta = {}
    @key = []
    @subscribed = []
    @computeBackend = false
  update: () ->
    fn() for fn in @subscribed
  subscribe: (h) ->
    if _.indexOf(@subscribed, h) is -1
      @subscribed.push h
  unsubscribe: (h) ->
    @subscribed.splice _.indexOf(@subscribed, h), 1
  keys: () -> @key
  rename: () -> false # throw not implemented?
  renameMany: () -> false # throw not implemented?
  remove: () -> false # throw not implemented?
  filter: () -> false # throw not implemented?
  sort: () -> false # throw not implemented?
  derive: () -> false # throw not implemented?
  get: () -> throw poly.error.data "Data has not been fetched or is undefined."
  len: () -> throw poly.error.data "Data has not been fetched or is undefined."
  getObject: () -> throw poly.error.data "Data has not been fetched or is undefined."
  max: () -> throw poly.error.data "Data has not been fetched or is undefined."
  min: () -> throw poly.error.data "Data has not been fetched or is undefined."
  getMeta: (key) -> if @meta then @meta[key] else undefined
  type: (key) ->
    if key of @meta
      t = @meta[key].type
      return if t is 'num' then 'number' else t
    throw poly.error.defn "Data does not have column #{key}."

class FrontendData extends AbstractData
  constructor: (params) ->
    super()
    @_setData params
  getData: (callback) -> callback @
  update: (params) ->
    @_setData params
    super()
  _setData: (params) ->
    {csv, json, meta} = params
    meta ?= {}
    {@key, @raw, @meta} =
      if csv
        _getCSV csv, meta
      else if _.isArray json
        if json[0] and _.isArray(json[0])
          _getArrayOfArrays json, meta
        else
          _getArray json, meta
      else if _.isObject json
        _getObject json, meta
  _checkRename: (from, to) ->
    if to is ''
      throw poly.error.defn "Column names cannot be an empty string"
    if _.indexOf(@key, from) is -1
      throw poly.error.defn "The key #{from} doesn't exist!"
    if _.indexOf(@key, to) isnt -1
      throw poly.error.defn "The key #{to} already exists!"
  rename: (from, to, checked=false) ->
    from = from.toString()
    to = to.toString()
    if from is to then return true
    if not checked then @_checkRename from, to
    for item in @raw
      item[to] = item[from]
      delete item[from]
    k = _.indexOf(@key, from)
    @key[k] = to
    @meta[to] = @meta[from]
    delete @meta[from]
    true
  renameMany: (map) ->
    for from, to of map
      if from isnt to
        @_checkRename from, to
    for from, to of map
      if from isnt to
        @rename from, to, true
    true
  remove: (key) ->
    index = _.indexOf(@key, key)
    if index is '-1'
      return false #throw poly.error.defn "The key #{key} doesn't exist!"
    @key.splice index, 1
    delete @meta[key]
    for item in @raw
      delete item[key]
    true
  filter: (strfn) ->
    fn =
      if _.isFunction strfn
        strfn
      else if _.isString strfn
        new Function('d', "with(d) { return #{strfn};}")
      else
        () -> true
    newdata = []
    for item in @raw
      if fn item
        newdata.push item
    newobj = poly.data.json newdata, @meta
    newobj
  sort: (key, desc) ->
    type = @type key
    newdata =_.clone(@raw)
    sortfn = poly.type.compare(type)
    newdata.sort (a,b) -> sortfn a[key], b[key]
    if desc then newdata.reverse()
    newobj = poly.data.json newdata, @meta
    newobj
  derive: (fnstr, key, opts) ->
    opts ?= {}
    {dryrun, context} = opts
    if not key? then key = _uniqueId("var_")
    context ?= {}
    if _.isFunction(fnstr)
      compute = fnstr
      hasFnStr = false
    else
      hasFnStr = true
      compute = new Function('d', "with(this) { with(d) { return #{fnstr if '' then "" else fnstr};}}")

    for item in @raw
      value = compute.call context,item
      if _.isFunction value
        throw poly.error.defn "Derivation function returned another function."
      item[key] = value
    if dryrun then return success:true, values: _.pluck @raw[0..10], key

    if not (key in @key)
      @key.push key
    @meta[key] =
      type : poly.type.impute _.pluck(@raw[0..100], key)
      derived: true
    if hasFnStr then @meta[key].formula = fnstr
    key
  get: (key) -> _.pluck @raw, key
  len: () -> @raw.length
  getObject: (i) -> @raw[i]
  max: (key) -> _.max @get(key)
  min: (key) -> _.min @get(key)

class BackendData extends AbstractData
  constructor: (params) ->
    super()
    {@url, @computeBackend, @limit} = params
    @limit ?= 1000
    @computeBackend ?= false

  # retrieve data from backend
  #   @callback - the callback function once data is retrieved
  #   @params - additional parameters to send to the backend
  getData: (callback, dataSpec) =>
    if @raw? then return callback @
    chr = if _.indexOf(@url, "?") is -1 then '?' else '&'
    url = @url +"#{chr}limit=#{@limit}"
    if dataSpec
      url += "&spec=#{encodeURIComponent(JSON.stringify(dataSpec))}"
    poly.text url, (blob) =>
      try
        blob = JSON.parse(blob)
      catch e
        # Guess "blob" is not a JSON object!
        throw poly.error.data("Unknown object returned from server!")
      # TODO: refactor this. repeat code from poly.data
      if _.isObject(blob) and _.keys(blob).length < 4 and 'data' of blob
        data = blob.data
        meta = blob.meta
      else
        data = blob
        meta = {}
      if _.isString(data)
        {@key, @raw, @meta} = _getCSV data, meta
      else if _.isArray(data)
        if data[0] and _.isArray(data[0])
          {@key, @raw, @meta} = _getArrayOfArrays data, meta
        else
          {@key, @raw, @meta} = _getArray data, meta
      else if _.isObject(data)
        {@key, @raw, @meta} = _getObject data, meta
      else
        poly.error.data "Unknown data format."
      @data = @raw # hack?
      callback @
  update: (params) ->
    @raw = null
    super()
