poly = @poly || {}
# GROUPING

poly.groupBy = (data, group) ->
  _.groupBy data, (item) ->
    concat = (memo, g) -> "#{memo}#{g}:#{item[g]};"
    _.reduce group, concat, ""

@poly = poly
