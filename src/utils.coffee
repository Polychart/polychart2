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
  _.groupBy data, poly.stringify(group)

poly.stringify = (group) -> (item) ->
  concat = (memo, g) -> "#{memo}#{g}:#{item[g]};"
  _.reduce group, concat, ""

poly.cross = (keyVals,ignore=[]) ->
  todo = _.difference(_.keys(keyVals), ignore)
  if todo.length is 0
    return [{}]
  arrs = []
  next = todo[0]
  items = poly.cross(keyVals, ignore.concat(next))
  for val in keyVals[next]
    for item in items
      i = _.clone(item)
      i[next] = val
      arrs.push(i)
  arrs

###
Take a processedData from the data processing step and group it for faceting
purposes.

Input is in the format: 
processData = {
  layer_id : { statData: [...], metaData: {...} }
  ...
}

Output should be in one of the two format:
  groupedData = {
    grouped: true
    key: group1
    values: {
      value1: groupedData2 # note recursive def'n
      value2: groupedData3
      ...
    }
  }
  OR
  groupedData = {
    layer_id : { statData: [...], metaData: {...} }
    ...
  }
###
poly.groupProcessedData = (processedData, groups) ->
  if groups.length is 0
    return processedData
  currGrp = groups.splice(0, 1)[0]

  uniqueValues = []
  for index, data of processedData
    if currGrp of data.metaData
      uniqueValues = _.union uniqueValues, _.uniq(_.pluck(data.statData, currGrp))

  result =
    grouped: true
    key: currGrp
    values: {}
  for value in uniqueValues
    # construct new processedData
    newProcessedData = {}
    for index, data of processedData
      newProcessedData[index] = metaData : data.metaData
      newProcessedData[index].statData =
        if currGrp of data.metaData
          poly.filter(data.statData, currGrp, value)
        else
          _.clone data.statData
    # construct value
    result.values[value] =
      poly.groupProcessedData(newProcessedData, _.clone groups)
  result

poly.filter = (statData, key, val) ->
  newData = []
  for item in statData
    if item[key] is val
      newData.push item
  newData

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

###
Produces a function that counts how many times it has been called
###
poly.counter = () ->
  i = 0
  () -> i++

###
Sample an associate array (object)
###
poly.sample = (assoc, num) ->
  _.pick assoc, _.shuffle(_.keys(assoc)).splice(0, num)

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
  deleted = []; kept = []; added = []
  oldIndex = newIndex = 0
  while oldIndex < sortedOldarr.length or newIndex < sortedNewarr.length
    oldElem = sortedOldarr[oldIndex]
    newElem = sortedNewarr[newIndex]
    if oldIndex >= sortedOldarr.length
      added.push(newElem)
      newIndex += 1
    else if newIndex >= sortedNewarr.length
      deleted.push(oldElem)
      oldIndex += 1
    else if oldElem < newElem
      deleted.push(oldElem)
      oldIndex += 1
    else if oldElem > newElem
      added.push(newElem)
      newIndex += 1
    else if oldElem == newElem
      kept.push(oldElem)
      oldIndex += 1; newIndex += 1
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
  zipped = _.zip(arrays...)
  zipped.sort (a, b) -> fn a[0], b[0]
  _.zip(zipped...)
