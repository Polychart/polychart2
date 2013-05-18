##
# Pivot table object and entry point: poly.pivot()
# ------------------------------------------------
# TODO: write more comments
##

toStrictMode = (spec) ->
  for aes in ['row', 'column', 'value']
    if not spec[aes+'s']
      spec[aes+'s'] = []
      if spec[aes]?
        spec[aes+'s'].push(spec[aes])

  for aes in ['rows', 'columns', 'values']
    for mappedTo, i in spec[aes]
      if _.isString mappedTo
        spec[aes][i] = { var: mappedTo }
  spec

class Pivot
  constructor: (spec) ->
    if not spec?
      throw poly.error.defn "No pivot table specification is passed in!"
    @make(spec)

  make: (spec, @callback) ->
    @spec = toStrictMode(spec)
    ps = new poly.DataProcess(@spec, [], @spec.strict, poly.parser.pivotToData)
    ps.make @spec, [], @render

  render: (statData, metaData) =>
    # create domains
    domains = {}
    for aes in ['rows', 'columns']
      domains[aes] = []
      for item in @spec[aes]
        values = _.pluck(statData, item.var)
        domains[aes].push(poly.domain.single(values, metaData[item.var], {}))
    console.log domains



poly.pivot = (spec) -> new Pivot(spec)
