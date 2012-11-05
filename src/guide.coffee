poly = @poly || {}

aesthetics = poly.const.aes

makeGuides = (layers, guideSpec, strictmode) ->
  domainSets = []
  _.each layers, (layerObj) ->
    domainSets.push makeDomainSet layerObj, guideSpec, strictmode
  mergeDomainSets domainSets

# DOMAIN CREATION AND MERGING

makeDomainSet = (layerObj, guideSpec, strictmode) ->
  domain = {}
  _.each _.keys(layerObj.mapping), (aes) ->
    if strictmode
      domain[aes] = makeDomain guideSpec[aes]
  return domain

mergeDomainSets = (domainSets) ->
  merged = {}
  _.each aesthetics, (aes) ->
    domains = _.without _.pluck(domainSets, aes), undefined
    if domains.length > 0
      merged[aes] = mergeDomains(domains)
  merged

class NumericDomain
  constructor: (params) -> {@type, @min, @max, @bw} = params
class DateDomain
  constructor: (params) -> {@type, @min, @max, @bw} = params
class CategoricalDomain
  constructor: (params) -> {@type, @levels, @sorted} = params
makeDomain = (params) ->
  switch params.type
    when 'num' then return new NumericDomain(params)
    when 'date' then return new DateDomain(params)
    when 'cat' then return new CategoricalDomain(params)

domainMerge =
  'num' : (domains) ->
    bw = _.uniq _.map(domains, (d) -> d.bw)
    if bw.length > 1
      console.log 'wtf'
    bw = bw[0] ? undefined
    min = _.min _.map(domains, (d) -> d.min)
    max = _.max _.map(domains, (d) -> d.max)
    return makeDomain type: 'num', min: min, max:max, bw: bw
  'cat' : (domains) ->
    sortedLevels =
      _.chain(domains).filter((d) -> d.sorted).map((d) -> d.levels).value()
    unsortedLevels =
      _.chain(domains).filter((d) -> !d.sorted).map((d) -> d.levels).value()
    if sortedLevels.length > 0 and _.intersection.apply @, sortedLevels
      console.log 'wtf'
    sortedLevels = [_.flatten(sortedLevels, true)]
    levels = _.union.apply @, sortedLevels.concat(unsortedLevels)
    return makeDomain type: 'cat', levels: levels, sorted: true

mergeDomains = (domains) ->
  types = _.uniq _.map(domains, (d) -> d.type)
  if types.length > 1
    console.log 'wtf'
  domainMerge[types[0]](domains)

# TICK CREATION
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

makeTicks = (domain, guideSpec, range, scale) ->
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

poly.guide =
  makeGuides : makeGuides
  makeTicks : makeTicks

@poly = poly
