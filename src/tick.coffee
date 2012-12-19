###
# GLOBALS
###
poly.tick = {}

###
Produce an associate array of aesthetics to tick objects.
###
poly.tick.make = (domain, guideSpec, type) ->
  step = null
  if guideSpec.ticks?
    ticks = guideSpec.ticks # provided by spec
  else
    numticks = guideSpec.numticks ? 5 # use default
    {ticks, step} = tickValues[type] domain, numticks
  # turn each tick location to an actual tick object
  if guideSpec.labels
    formatter = (x) -> guideSpec.labels[x] ? x
  else if guideSpec.formatter
    formatter = guideSpec.formatter
  else
    formatter = poly.format(type, step)
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
    len = domain.levels.length
    step = Math.max 1, Math.round(len/numticks)
    ticks = []
    for item, i in domain.levels
      if i % step == 0
        ticks.push item
    ticks: ticks
  'num' : (domain, numticks) ->
    {min, max} = domain
    step = getStep max-min, numticks
    tmp = Math.ceil(min/step) * step
    ticks = []
    while tmp < max
      ticks.push tmp
      tmp += step
    ticks: ticks
    step: Math.floor(Math.log(step)/Math.LN10)
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
    ticks: ticks
  'date' : (domain, numticks) ->
    {min, max} = domain
    step = (max-min) / numticks
    step =
      if      step < 1.4*1 then 'second'
      else if step < 1.4*60 then 'minute'
      else if step < 1.4*60*60 then 'hour'
      else if step < 1.4*24*60*60 then 'day'
      else if step < 1.4*7*24*60*60 then 'week'
      else if step < 1.4*30*24*60*60 then 'month'
      else 'year'
    ticks = []
    current = moment.unix(min).startOf(step)
    while current.unix() < max
      ticks.push current.unix()
      current.add(step+'s', 1)
    ticks: ticks
    step: step
