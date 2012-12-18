poly = @poly || {}

###
Group an array of data items by the value of certain columns.

Input:
- `data`: an array of data items
- `group`: an array of column keys, to group by
Output:
- an associate array of key: array of data, with the appropriate grouping
  the `key` is a string of format "columnKey:value;colunmKey2:value2;..."
###
poly.groupBy = (data, group) ->
  _.groupBy data, (item) ->
    concat = (memo, g) -> "#{memo}#{g}:#{item[g]};"
    _.reduce group, concat, ""


###
Produces a linear function that passes through two points.
Input:
- `x1`: x coordinate of the first point
- `y1`: y coordinate of the first point
- `x2`: x coordinate of the second point
- `y2`: y coordinate of the second point
Output:
- A function that, given the x-coord, returns the y-coord
###
poly.linear = (x1, y1, x2, y2) ->
  (x) -> (y2-y1)/(x2-x1)*(x-x1) + y1

###
given a sorted list and a midpoint calculate the median
###
poly.median = (values, sorted=false) ->
    if not sorted then values = _.sortBy(values, (x)->x)
    mid = values.length/2
    if mid % 1 != 0 then return values[Math.floor(mid)]
    return (values[mid-1]+values[mid])/2

@poly = poly


###
Produces a function that counts how many times it has been called
###
poly.counter = () ->
  i = 0
  () -> i++


###
Given an OLD array and NEW array, split the points in (OLD union NEW) into
three sets:
  - deleted
  - kept
  - added
###
poly.compare = (oldarr, newarr) ->
  sortedOldarr = _.sortBy(oldarr, (x) -> x)
  sortedNewarr = _.sortBy(newarr, (x) -> x)
  sortedOldarr.push(NaN); sortedNewarr.push(NaN) # NaN is a terminal value
  deleted = []; kept = []; added = []
  i = j = 0
  while not isNaN(sortedOldarr[i]) or not isNaN(sortedNewarr[j])
    oldElem = sortedOldarr[i]
    newElem = sortedNewarr[j]
    if oldElem < newElem or isNaN(newElem)
      deleted.push(oldElem)
      i += 1
    else if oldElem > newElem or isNaN(oldElem)
      added.push(newElem)
      j += 1
    else if oldElem == newElem
      kept.push(oldElem)
      i += 1; j += 1
    else throw DataError("Unknown data encounted")

  return {
    deleted : deleted
    kept    : kept
    added   : added
    }

###
Given an aesthetic mapping in the "geom" object, flatten it and extract only
the values from it. This is so that even if a compound object is encoded in an
aestehtic, we have the correct set of values to calculate the min/max.
###
poly.flatten = (values) ->
  flat = []
  if values?
    if _.isObject values
      if values.t is 'scalefn'
        if values.f isnt 'novalue'
          flat.push values.v
      else
        for k, v of values
          flat = flat.concat poly.flatten(v)
    else if _.isArray values
      for v in values
        flat = flat.concat poly.flatten(v)
    else
      flat.push values
  return flat

###
GET LABEL
TODO: move somewhere else and allow overwrite by user
###
poly.getLabel = (layers, aes) ->
  _.chain(layers)
   .map((l) -> l.mapping[aes])
   .without(null, undefined)
   .uniq().value().join(' | ')

###
Estimate the number of pixels rendering this string would take...?
###
poly.strSize = (str) -> (str+"").length * 7

###
Sort Arrays: given a sorting function and some number of arrays, sort all the
arrays by the function applied to the first array. This is used for sorting
points for a line chart, i.e. poly.sortArrays(sortFn, [xs, ys])

This way, all the points are sorted by (sortFn(x) for x in xs)
###
poly.sortArrays = (fn, arrays) ->
  _.zip(_.sortBy(_.zip(arrays...), (a) -> fn(a[0]))...)


###
Impute types from values
###
THRESHOLD = 0.95
poly.varType = (values) ->
  date = 0
  num = 0
  for value in values
    if not value? then continue
    # check if it's a number
    if not isNaN(value) or not isNaN value.replace(/\$|\,/g,'')
      num++
    # check if it's a date
    if moment(value).isValid()
      date++
  if num > THRESHOLD*values.length
    return 'num'
  if date > THRESHOLD*values.length
    return 'date'
  return 'cat'

###
Parse values into correct types
###
poly.coerce = (value, meta) ->
  if meta.type is 'cat'
    value
  else if meta.type is 'num'
    if not isNaN value
      +value
    else
      +((""+value).replace(/\$|\,/g,''))
  else if meta.type is 'date'
    if meta.format
      if meta.format is 'unix'
        moment.unix(value).unix() #sounds inefficient, but error checks?
      else
        moment(value, meta.format).unix()
    else
      moment(value).unix()
  else
    undefined

###
# EXPORT
###
@poly = poly
