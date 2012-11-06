poly = @poly || {}

###
# GLOBALS
###
poly.dim = {}
poly.dim.make = (spec, ticks) ->
  return {
    chartWidth: 300
    chartHeight: 300
    paddingLeft: 10
    paddingRight: 10
    paddingTop: 10
    paddingBottom: 10
    guideLeft: 10
    guideRight: 10
    guideTop: 10
    guideBottom: 10
  }

###
# CLASSES
###

###
# EXPORT
###
@poly = poly
