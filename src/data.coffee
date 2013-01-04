###
# GLOBALS
###

###
Generalized data object that either contains JSON format of a dataset,
or knows how to retrieve data from some source.
###
class Data
  isData: true
  constructor: (params) ->
    {@url, @json, @csv, @meta} = params
    @dataBackend = params.url?
    @computeBackend = false
    @raw = null
    @meta ?= {}
    @subscribed = []
  impute: (json) ->
    if _.isArray(json)
      if json.length > 0
        keys = _.union _.keys(@meta), _.keys(json[0])
        first100 = json[0..99]
        for key in keys
          @meta[key] ?= {}
          if not @meta[key].type
            @meta[key].type = poly.varType _.pluck(first100, key)
        for item in json
          for key in keys
            if _.isString item[key]
              item[key] = poly.coerce item[key], @meta[key]
        @key = keys
        @raw = json
      else
        @key = _.keys(@meta)
        @raw = []
    else if _.isObject(json)
      @key = _.keys(json)
      @raw = []
      for key in @key
        @meta[key] ?= {}
        if not @meta[key].type
          @meta[key].type = poly.varType json[key][0..99]

      if @key.length > 0
        len = json[@key[0]].length
        if len > 0
          for i in [0..len-1]
            obj = {}
            for k in @key
              obj[k] = poly.coerce json[k][i], @meta[k]
            @raw.push(obj)
      @raw
  getData: (callback) ->
    # frontend
    if @raw then return callback @
    if @json then @impute @json
    if @csv then @impute poly.csv.parse(@csv)
    if @raw then return callback @
    # backend
    if @url then poly.csv @url, (csv) =>
      @raw = @impute csv
      callback @
  update: (params) ->
    {@json, @csv} = params
    @raw = null
    @getData () =>
      for fn in @subscribed
        fn()
  subscribe: (h) ->
    if _.indexOf(@subscribed, h) is -1
      @subscribed.push h
  unsubscribe: (h) ->
    @subscribed.splice _.indexOf(@subscribed, h), 1

  # functions for backwards compatibility: DO NOT USE!
  keys: () -> @key
  checkRename: (from, to) ->
    if to is ''
      throw poly.err.defn "Column names cannot be an empty string"
    if _.indexOf(@key, from) is -1
      throw poly.err.defn "The key #{from} doesn't exist!"
    if _.indexOf(@key, to) isnt -1
      throw poly.err.defn "The key #{to} already exists!"
  rename: (from, to, checked=false) ->
    from = from.toString()
    to = to.toString()
    if not checked then @checkRename from, to
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
      @checkRename from, to
    for from, to of map
      @rename from, to, true
    true
  remove: (key) ->
    index = _.indexOf(@key, key)
    if index is '-1'
      return false #throw poly.err.defn "The key #{key} doesn't exist!"
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
    newobj = new Data json: newdata, meta: @meta
    newobj.getData ->
    newobj
  sort: (key, desc) ->
    type = @type key
    newdata =_.clone(@raw)
    sortfn = if type is 'cat' then poly.sortString else poly.sortNum
    newdata.sort (a,b) -> sortfn a[key], b[key]
    if desc then newdata.reverse()
    newobj = new Data json: newdata, meta: @meta
    newobj.getData ->
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
        throw poly.err.defn "Derivation function returned another function."
      item[key] = value
    if dryrun then return success:true, values: _.pluck @raw[0..10], key

    if not (key in @key)
      @key.push key
    @meta[key] =
      type : poly.varType _.pluck(@raw[0..100], key)
      derived: true
    if hasFnStr then @meta[key].formula = fnstr
    key
  getMeta: (key) -> @meta[key]
  type: (key) ->
    if key of @meta
      t = @meta[key].type
      return if t is 'num' then 'number' else t
    throw poly.error.defn "Data does not have column #{key}."
  get: (key) -> _.pluck @raw, key
  len: () -> @raw.length
  getObject: (i) -> @raw[i]
  max: (key) -> _.max @get(key)
  min: (key) -> _.min @get(key)

poly.Data = Data
