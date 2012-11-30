poly = @poly || {}

###
# CONSTANTS
###
aesthetics = poly.const.aes

###
# GLOBALS
###

poly.domain = {}

###
Produce a domain set for each layer based on both the information in each
layer and the specification of the guides, then merge them into one domain
set.
###
poly.domain.make = (layers, guideSpec, strictmode) ->
  domainSets = []
  _.each layers, (layerObj) ->
    domainSets.push makeDomainSet layerObj, guideSpec, strictmode
  mergeDomainSets domainSets

###
# CLASSES & HELPER
###

###
Domain classes
###
class NumericDomain
  constructor: (params) -> {@type, @min, @max, @bw} = params
class DateDomain
  constructor: (params) -> {@type, @min, @max, @bw} = params
class CategoricalDomain
  constructor: (params) -> {@type, @levels, @sorted} = params

###
Public-ish interface for making different domain types
###
makeDomain = (params) ->
  switch params.type
    when 'num' then return new NumericDomain(params)
    when 'date' then return new DateDomain(params)
    when 'cat' then return new CategoricalDomain(params)

###
Make a domain set. A domain set is an associate array of domains, with the
keys being aesthetics
###
makeDomainSet = (layerObj, guideSpec, strictmode) ->
  domain = {}
  _.each _.keys(layerObj.mapping), (aes) ->
    if strictmode
      domain[aes] = makeDomain guideSpec[aes]
    else
      values = flattenGeoms(layerObj.geoms, aes)
      fromspec = (item) -> if guideSpec[aes]? then guideSpec[aes][item] else null
      # assume type = numeric for now :(
      domain[aes] = makeDomain {
        type: 'num'
        min: fromspec('min') ? _.min(values)
        max: fromspec('max') ? _.max(values)
        bw: fromspec('bw')
      }
      console.log domain[aes]
  domain

flattenGeoms = (geoms, aes) ->
  values = []
  _.each geoms, (geom) ->
    _.each geom.marks, (mark) ->
      values = values.concat poly.flatten mark[aes]
  values

###
Merge an array of domain sets: i.e. merge all the domains that shares the
same aesthetics.
###
mergeDomainSets = (domainSets) ->
  merged = {}
  _.each aesthetics, (aes) ->
    domains = _.without _.pluck(domainSets, aes), undefined
    if domains.length > 0
      merged[aes] = mergeDomains(domains)
  merged

###
Helper for merging domains of the same type. Two domains of the same type
can be merged if they share the same properties:
 - For numeric/date variables all domains must have the same binwidth parameter
 - For categorial variables, sorted domains must have any categories in common
###
domainMerge =
  'num' : (domains) ->
    bw = _.uniq _.map(domains, (d) -> d.bw)
    if bw.length > 1
      throw new poly.LengthError("All binwidths are not of the same length")
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
      throw new poly.UnknownError()
    sortedLevels = [_.flatten(sortedLevels, true)]
    levels = _.union.apply @, sortedLevels.concat(unsortedLevels)
    return makeDomain type: 'cat', levels: levels, sorted: true

###
Merge an array of domains: Two domains can be merged if they are of the
same type, and they share certain properties.
###
mergeDomains = (domains) ->
  types = _.uniq _.map(domains, (d) -> d.type)
  if types.length > 1
    throw new poly.TypeError("Not all domains are of the same type")
  domainMerge[types[0]](domains)

###
# EXPORT
###
@poly = poly
