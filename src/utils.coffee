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

