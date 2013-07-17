###
Tick Generation
---------------
Helper functions to legends & axes for generating ticks
###
poly.tick = {}

###
Produce an associate array of aesthetics to tick objects.
###
poly.tick.make = (domain, guideSpec, type) ->
  step = null
  formatter = (x) -> x
  if guideSpec.ticks?
    # Will the only custom tick type be num? Will there be problems for others?
    if type is 'num'
      ticks = _.filter guideSpec.ticks, (t) => (t >= domain.min and t <= domain.max) # provided by spec
    else
      ticks = guideSpec.ticks
  else
    numticks = guideSpec.numticks ? 5 # use default
    {ticks, step} = tickValues[type] domain, numticks
  # turn each tick location to an actual tick object
  if guideSpec.labels
    formatter = (x) -> guideSpec.labels[x] ? x
  else if guideSpec.formatter
    formatter = guideSpec.formatter
  else
    formatter = poly.format(type.split('-')[0], step)
  tickobjs = {}
  tickfn = tickFactory(type, formatter)

  if ticks
    for i in [0..ticks.length-1]
      prev = if i is 0 then null else ticks[i-1]
      next = if i is ticks.length-1 then null else ticks[i+1]
      t = ticks[i]
      # Temp to force redraw when change format
      # TODO: Find a way to only change the text when changing format
      tmpTick = tickfn t, prev, next
      tickobjs[tmpTick.value] = tmpTick
  {ticks: tickobjs, ticksFormatter: formatter}

###
# CLASSES & HELPERS
###

###
Tick Object.
###
class Tick
  constructor: (params) -> {@location, @value, @index, @evtData} = params

###
Helper function for creating a function that creates ticks
###
tickFactory = (type, formatter) ->
  i = 0
  (value, prev, next) ->
    if type is 'cat'
      evtData = {in : [value]}
    else
      evtData = {}
      if prev? then evtData.ge = prev
      if next? then evtData.le = next
    new Tick
      location:value
      value:formatter(value)
      index:i++
      evtData:evtData

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
  'none' : -> {}
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
    ticks = []
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
      else
        num = tmp
      num = exp num
      if num < min or num > max
        tmp += step
        continue
      ticks.push num
      tmp += step
    ticks: ticks
  'date' : (domain, numticks) ->
    {min, max} = domain
    secs = (max-min) / numticks
    step = 'decade'
    for timeRange, timeInSeconds of poly.const.approxTimeInSeconds
      if secs < timeInSeconds*1.4
        step = timeRange
        break
    ticks = []
    current = moment.unix(min).startOf(step)
    momentjsStep =
      switch step
        when 'twomonth' then ['months', 2]
        when 'quarter' then ['months', 4]
        when 'sixmonth' then ['months', 6]
        when 'twoyear' then ['years', 2]
        when 'fiveyear' then ['years', 5]
        when 'decade' then ['years', 10]
        else [step+'s', 1]
    if current.unix() < min
      current.add(momentjsStep[0], momentjsStep[1])
    while current.unix() < max
      ticks.push current.unix()
      current.add(momentjsStep[0], momentjsStep[1])
    ticks: ticks
    step: step
#error testing

