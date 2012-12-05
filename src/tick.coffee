poly = @poly || {}

###
# GLOBALS
###
poly.tick = {}

###
Produce an associate array of aesthetics to tick objects.
###
poly.tick.make = (domain, guideSpec, type) ->
  if guideSpec.ticks?
    ticks = guideSpec.ticks # provided by spec
  else
    numticks = guideSpec.numticks ? 5 # use default
    ticks = tickValues[type] domain, numticks
  # turn each tick location to an actual tick object
  formatter = (x) -> x
  if guideSpec.labels
    formatter = (x) -> guideSpec.labels[x] ? x
  else if guideSpec.formatter
    formatter = guideSpec.formatter
  tickobjs = {}
  tickfn = tickFactory(formatter)
  for t in ticks
    tickobjs[t] = tickfn t
  tickobjs

###
# CLASSES & HELPERS
###

###
Tick Object.
###
class Tick
  constructor: (params) -> {@location, @value, @index} = params

###
Helper function for creating a function that creates ticks
###
tickFactory = (formatter) ->
  i = 0
  (value) -> new Tick(location:value, value:formatter(value), index:i++)

###
Helper function for determining the size of each "step" (distance between
ticks) for numeric scales
###
getStep = (span, numticks) ->
  step = Math.pow(10, Math.floor(Math.log(span / numticks) / Math.LN10))
  error = numticks / span * step
  if      error < 0.15  then step *= 10
  else if error <= 0.35 then step *= 5
  else if error <= 0.75 then step *= 2
  return step

###
Function for calculating the location of ticks.
###
tickValues =
  'cat' : (domain, numticks) ->
    return domain.levels #TODO
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
  'date' : (domain, numticks) -> #TODO
    return 2

###
# EXPORT
###
@poly = poly
