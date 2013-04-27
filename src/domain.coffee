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
poly.domain.make = (geoms, metas, guideSpec, strictmode) ->
  domainSets = []
  for i, g of geoms
    domainSets.push makeDomainSet g.geoms, metas[i], guideSpec, strictmode
  poly.domain.merge domainSets

poly.domain.compare = (domain) ->
  if domain
    if domain.type is 'cat'
      (a, b) ->
        a = _.indexOf(domain.levels, a)
        b = _.indexOf(domain.levels, b)
        if a == -1 then 1
        else if b == -1 then -1
        else if a < b then return -1
        else if a > b then return 1
        else 0
    else
      poly.type.compare(domain.type)
  else
    (x) -> x # should not happen...

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
makeDomainSet = (geoms, metas, guideSpec, strictmode) ->
  domain = {}
  for aes, meta of metas
    if aes in poly.const.noDomain then continue
    if strictmode
      domain[aes] = makeDomain guideSpec[aes]
    else
      values = flattenGeoms(geoms, aes)
      if values.length is 0
        throw poly.error.input("Dataset is none?")
      fromspec = (item) -> if guideSpec[aes]? then guideSpec[aes][item] else null
      switch meta.type
        when 'num'
          bw = fromspec('bw') ? meta.bw
          if values.length > 1
            min = fromspec('min') ? _.min(values)
            max = fromspec('max') ?  (_.max(values) + (bw ? 0))
          else if values.length == 1
            debugger
            if bw
              min = fromspec('min') ? values[0]
              max = fromspec('max') ? values[0]+bw
            else
              min = fromspec('min') ? values[0]-1
              max = fromspec('max') ? values[0]+1
          else
            min = fromspec('min') ? 0
            max = fromspec('max') ? bw ? 1
          domain[aes] = makeDomain {
            type: 'num'
            min: min
            max: max
            bw: bw
          }
        when 'date'
          bw = fromspec('bw') ? meta.bw
          min = fromspec('min') ? _.min(values)
          max = fromspec('max')
          if not max?
            max = _.max(values)
            max =
              if bw is 'week'
                moment.unix(max).add('days',7).unix()
              else if bw is 'decade'
                moment.unix(max).add('years',10).unix()
              else
                moment.unix(max).add(bw+'s',1).unix()
          domain[aes] = makeDomain {
            type: 'date'
            min: min
            max: max
            bw: bw
          }
        when 'cat'
          domain[aes] = makeDomain {
            type: 'cat'
            levels: fromspec('levels') ? meta.levels ? _.uniq(values)
            sorted : fromspec('levels') ? meta.sorted ? false
            #sorted = true <=> user specified
          }

  domain

###
VERY preliminary flatten function. Need to optimize
###
flattenGeoms = (geoms, aes) ->
  values = []
  for k, geom of geoms
    for l, mark of geom.marks
      values = values.concat poly.flatten mark[aes]
  (v for v in values when poly.isDefined(v))

###
Merge an array of domain sets: i.e. merge all the domains that shares the
same aesthetics.
###
poly.domain.merge = (domainSets) ->
  merged = {}
  for aes in aesthetics
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
    bw = _.compact _.uniq _.map(domains, (d) -> d.bw)
    if bw.length > 1
      throw poly.error.data "Not all layers have the same binwidth."
    bw = bw[0] ? undefined
    min = _.min _.map(domains, (d) -> d.min)
    max = _.max _.map(domains, (d) -> d.max)
    return makeDomain type: 'num', min: min, max:max, bw: bw
  'date' : (domains) ->
    bw = _.compact _.uniq _.map(domains, (d) -> d.bw)
    if bw.length > 1
      throw poly.error.data "Not all layers have the same binwidth."
    bw = bw[0] ? undefined
    min = _.min _.map(domains, (d) -> d.min)
    max = _.max _.map(domains, (d) -> d.max)
    return makeDomain type: 'date', min: min, max:max, bw: bw
  'cat' : (domains) ->
    sortedLevels = []
    for d in domains
      if d.sorted
        add = true
        for l in sortedLevels
          if _.isEqual l, d.levels then add = false
        if add then sortedLevels.push d.levels
    unsortedLevels =
      _.chain(domains).filter((d) -> !d.sorted).map((d) -> d.levels).value()
    if sortedLevels.length > 1 and _.intersection.apply @, sortedLevels
      throw poly.error.data "You are trying to combine incompatible sorted domains in the same axis."
    sortedLevels = [_.flatten(sortedLevels, true)]
    levels = _.union.apply @, sortedLevels.concat(unsortedLevels)
    if sortedLevels[0].length is 0
      levels = levels.sort()
    return makeDomain type: 'cat', levels: levels, sorted: sortedLevels[0].length isnt 0

###
Merge an array of domains: Two domains can be merged if they are of the
same type, and they share certain properties.
###
mergeDomains = (domains) ->
  types = _.uniq _.map(domains, (d) -> d.type)
  if types.length > 1
    throw poly.error.data "You are trying to merge data of different types in the same axis or legend."
  domainMerge[types[0]](domains)
