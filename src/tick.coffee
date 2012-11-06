poly = @poly || {}

###
# GLOBALS
###
poly.tick = {}
poly.tick.make = (domain, guideSpec, range, scale) ->
  # ticks
  if guideSpec.ticks?
    ticks = guideSpec.ticks
  else
    numticks = guideSpec.numticks ? 5
    if domain.type == 'num' and guideSpec.transform == 'log'
      ticks = tickValues['num-log'] domain, numticks
    else
      ticks = tickValues[domain.type] domain, numticks
  # range
  scale = scale || (x) -> x
  formatter = (x) -> x
  if guideSpec.labels
    formatter = (x) -> guideSpec.labels[x] ? x
  else if guideSpec.formatter
    formatter = guideSpec.formatter
  ticks = _.map ticks, tickFactory(scale, formatter)

###
# CLASSES & HELPERS
###
class Tick
  constructor: (params) -> {@location, @value} = params

tickFactory = (scale, formatter) ->
  (value) -> new Tick(location:scale(value), value:formatter(value))

getStep = (span, numticks) ->
  step = Math.pow(10, Math.floor(Math.log(span / numticks) / Math.LN10))
  error = numticks / span * step
  if      error < 0.15  then step *= 10
  else if error <= 0.35 then step *= 5
  else if error <= 0.75 then step *= 2
  return step

tickValues =
  'cat' : (domain, numticks) ->
    return domain.levels
  'num' : (domain, numticks) ->
    {min, max} = domain
    step = getStep max-min, numticks
    tmp = Math.ceil(min/step) * step
    ticks = []
    while tmp < max
      ticks.push tmp
      tmp += step
    ticks
  'num-log' : (domain, numticks) ->
    {min, max} = domain
    lg = (v) -> Math.log(v) / Math.LN10
    exp = (v) -> Math.exp v*Math.LN10
    lgmin = Math.max lg(min), 0
    lgmax = lg max
    step = getStep lgmax-lgmin, numticks
    tmp = Math.ceil(lgmin/step) * step
    while tmp < (lgmax + poly.const.epsilon)
      if tmp % 1 isnt 0 && tmp % 1 <= 0.1
        tmp += step
        continue
      else if tmp % 1 > poly.const.epsilon
        num = Math.floor(tmp) + lg 10*(tmp % 1)
        if num % 1 == 0
          tmp += step
          continue
      num = exp num
      if num < min or num > max
        tmp += step
        continue
      ticks.push num
    ticks
  'date' : (domain, numticks) ->
    return 2

###
# EXPORT
###
@poly = poly
