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

poly.filter = (statData, key, val) ->
  newData = []
  for item in statData
    if item[key] is val
      newData.push item
  newData

###
Intersets values when filter key is common to both objects, add all values otherwise.

  TODO: handle the case when no intersection exist from a given common key
###
poly.intersect = (filter1, filter2) ->
  intersectList = (key) ->
    newList = []
    for elem in filter1[key]["in"]
      if elem in filter2[key]["in"]
        newList.push elem
    "in": newList
  intersectIneq = (key) ->
    getUpperBound = (filter) ->
      if filter[key].lt
        type: "lt"
        val: filter[key].lt
      else if filter[key].le
        type: "le"
        val: filter[key].le
      else
        type: null
        val: null
    getLowerBound = (filter) ->
      if filter[key].gt
        type: "gt"
        val: filter[key].gt
      else if filter[key].ge
        type: "ge"
        val: filter[key].ge
      else
        type: null
        val: null
    addbound = (bound) ->
      newIneq[bound.type] = bound.val
    lowers = [getLowerBound(filter1), getLowerBound(filter2)]
    uppers = [getUpperBound(filter1), getUpperBound(filter2)]
    lowers.sort (a,b) ->
      b.val - a.val # descending order
    uppers.sort (a,b) ->
      a.val - b.val # ascending order
    newIneq = {}
    if lowers[0].type and lowers[0].val
      {type, val} = lowers[0]
      if lowers[0].val == lowers[1].val and lowers[0].type != lowers[1].type
        type = "lt"
      newIneq[type] = val
    if uppers[0].type and uppers[0].val
      {type, val} = uppers[0]
      if uppers[0].val == uppers[1].val and uppers[0].type != uppers[1].type
        type = "lt"
      newIneq[type] = val

    if lowers[0].type and uppers[0].type
      # There exists a lower & upper bound
      if lowers[0].val > uppers[0].val or (lowers[0].val == uppers[0].val and (lowers[0].key is "lt" or uppers[0].key is "gt"))
        # Seems like its not an intersection afterall
        throw "No intersection found!"
    newIneq

  newFilter = {}
  for key, val of filter1
    if key of filter2
      # Calculate intersection
      if "in" of filter1[key]
        newFilter[key] = intersectList(key)
      else # gt, lt, ge, le
        newFilter[key] = intersectIneq(key)
    else
      newFilter[key] = val

  for key, val of filter2
    unless key of newFilter
      newFilter[key] = val
  newFilter

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
  if _.isFinite(x1) and _.isFinite(y1) and _.isFinite(x2) and _.isFinite(y2)
    (x) -> (y2-y1)/(x2-x1)*(x-x1) + y1
  else
    throw poly.error.input "Attempting to create linear function from infinity"

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
poly.strSize = (str) ->
  len = (str+"").length
  if len < 10
    len * 6
  else
    (len - 10) * 5 + 60

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

###
Determine if a value is not null and not undefined.
###
poly.isDefined = (x) ->
  if _.isObject(x)
    if x.t is 'scalefn' and x.f isnt 'novalue'
      poly.isDefined(x.v)
    else
      true
  else
    x isnt undefined and x isnt null and !(_.isNumber(x) and _.isNaN(x))

###
Determine if a String is a valid URI
http://stackoverflow.com/questions/5717093/check-if-a-javascript-string-is-an-url
###
poly.isURI = (str) ->
  if not _.isString(str)
    false
  else
    pattern = new RegExp('^(https?:\\/\\/)?'+ # protocol
    '((([a-z\\d]([a-z\\d-]*[a-z\\d])*)\\.)+[a-z]{2,}|'+ # domain name
    '((\\d{1,3}\\.){3}\\d{1,3}))'+ # OR ip (v4) address
    '(\\:\\d+)?(\\/[-a-z\\d%_.~+]*)*'+ # port and path
    '(\\?[;&a-z\\d%_.~+=-]*)?'+ # query string
    '(\\#[-a-z\\d_]*)?$','i'); # fragment locator
    pattern.test(str)
