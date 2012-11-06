poly = @poly || {}

###
# CONSTANTS
###
aesthetics = poly.const.aes

###
# GLOBALS
###
poly.domain = {}
poly.domain.make = (layers, guideSpec, strictmode) ->
  domainSets = []
  _.each layers, (layerObj) ->
    domainSets.push makeDomainSet layerObj, guideSpec, strictmode
  mergeDomainSets domainSets

###
# CLASSES & HELPER
###
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

###
# EXPORT
###
@poly = poly
