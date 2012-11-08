poly = @poly || {}

###
# CONSTANTS
###
aesthetics = poly.const.aes

###
# GLOBALS
###
poly.scale = {}

poly.scale.make = (guideSpec, domains, dims) ->
  scales = {}
  # x axis
  if domains.x
    range = type: 'num', min: 0, max: dims.chartWidth
    scales.x = makeScale domains.x, range
  # y axis
  if domains.y
    range = type: 'num', min: 0, max: dims.chartHeight
    scales.y = makeScale domains.y, range
  scales

###
# CLASSES
###

makeScale = (domain, range) ->
  # log?
  if domain.type is 'num' and range.type is 'num'
    return scale.numeric domain, range, 2

scale =
  'numeric' : (domain, range, space) -> # space:px
    [y2, y1, x2, x1] = [range.max, range.min, domain.max, domain.min]
    bw = domain.bw
    m = (y2 - y1) / (x2 - x1)
    y = (x) -> m * (x - x1) + y1
    (val) ->
      if _.isObject(val)
        if value.t is 'scalefn'
          if value.f is 'upper' then return y(val+bw) - space
          if value.f is 'lower' then return y(val) + space
          if value.f is 'middle' then return y(val+bw/2)
        console.log 'wtf'
      y(val)
  'identity' : () -> (x) -> x


###
# EXPORT
###
@poly = poly
