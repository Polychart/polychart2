poly.scaleset = (guideSpec, domains, ranges) ->
  return new ScaleSet(guideSpec, domains, ranges)

class ScaleSet
  constructor: (tmpRanges, coord) ->
    # note that axes.x is the axis for the x-aesthetic. it may or ma NOT be
    # the x-axis displayed on the screen.
    @coord = coord
    @ranges = tmpRanges
    @axes = {}
    @legends = []
    @deletedAxes = []
    @deletedLegends = []

  make: (guideSpec, domains, layers) ->
    @guideSpec = guideSpec
    @layers = layers
    @domains = domains
    @domainx = @domains.x
    @domainy = @domains.y
    @scales = @_makeScales(guideSpec, domains, @ranges)
    @reverse=
      x: @scales.x.finv
      y: @scales.y.finv
    @layerMapping = @_mapLayers layers

  setRanges: (ranges) ->
    @ranges = ranges
    @_makeXScale()
    @_makeYScale()
  setXDomain: (d) ->
    @domainx = d
    @_makeXScale()
  setYDomain: (d) ->
    @domainy = d
    @_makeYScale()
  resetDomains: () ->
    @domainx = @domains.x
    @domainy = @domains.y
    @_makeXScale()
    @_makeYScale()
  _makeXScale: () ->
    @scales.x.make(@domainx, @ranges.x)
  _makeYScale: () ->
    @scales.y.make(@domainy, @ranges.y)
  _makeScales : (guideSpec, domains, ranges) ->
    # this function contains information about default scales!
    specScale = (a) ->
      if guideSpec and guideSpec[a]? and guideSpec[a].scale?
        return guideSpec[a].scale
      return null
    scales = {}
    # x 
    scales.x = specScale('x') ? poly.scale.linear()
    scales.x.make(domains.x, ranges.x)
    # y
    scales.y = specScale('y') ? poly.scale.linear()
    scales.y.make(domains.y, ranges.y)
    # color
    if domains.color?
      if domains.color.type == 'cat'
        scales.color = specScale('color') ? poly.scale.color()
      else
        scales.color = specScale('color') ?
          poly.scale.gradient upper:'steelblue', lower:'red'
      scales.color.make(domains.color)
    # size
    if domains.size?
      scales.size = specScale('size') || poly.scale.area()
      scales.size.make(domains.size)
    # opacity
    if domains.opacity?
      scales.opacity= specScale('opacity') || poly.scale.opacity()
      scales.opacity.make(domains.opacity)
    # text
    scales.text = poly.scale.identity()
    scales.text.make()
    scales

  fromPixels: (start, end) ->
    {x,y} = @coord.getAes start, end, @reverse
    obj = {}
    for map in @layerMapping.x
      if map.type? and map.type == 'map'
        obj[map.value] = x
    for map in @layerMapping.y
      if map.type? and map.type == 'map'
        obj[map.value] = y
    obj

  getSpec : (a) -> if @guideSpec? and @guideSpec[a]? then @guideSpec[a] else {}
  makeAxes: (groups) ->
    {deleted, kept, added} = poly.compare(_.keys(@axes), groups)
    for key in deleted
      @deletedAxes.push @axes[key]
      delete @axes[key]
    for key in added
      @axes[key] =
        x: poly.guide.axis @coord.axisType('x')
        y: poly.guide.axis @coord.axisType('y')
    for key, axis of @axes
      axis.x.make
        domain: @domainx
        type: @scales.x.tickType()
        guideSpec: @getSpec 'x'
        key: poly.getLabel @layers, 'x'
      axis.y.make
        domain: @domainy
        type: @scales.y.tickType()
        guideSpec: @getSpec 'y'
        key: poly.getLabel @layers, 'y'
    @axes
  renderAxes: (dims, renderer) ->
    axis.remove(renderer) for axis in @deletedAxes
    @deletedAxes = []
    axisDim =
      top: dims.paddingTop + dims.guideTop
      left : dims.paddingLeft + dims.guideLeft
      right: dims.paddingLeft + dims.guideLeft + dims.chartWidth
      bottom : dims.paddingTop + dims.guideTop + dims.chartHeight
      width: dims.chartWidth
      height: dims.chartHeight
    for key, axis of @axes
      axis.x.render axisDim, @coord, renderer
      axis.y.render axisDim, @coord, renderer

  _mapLayers: (layers) ->
    obj = {}
    for aes of @domains
      obj[aes] =
        _.map layers, (layer) ->
          if layer.mapping[aes]?
            { type: 'map', value: layer.mapping[aes]}
          else if layer.consts[aes]?
            { type: 'const', value: layer.const[aes]}
          else
            layer.defaults[aes]
    obj
  _mergeAes: (layers) ->
    merging = [] # array of {aes: __, mapped: ___}
    for aes of @domains
      if aes in poly.const.noLegend then continue
      mapped = _.map layers, (layer) -> layer.mapping[aes]
      if not _.all mapped, _.isUndefined
        merged = false
        for m in merging # slow but ok, <7 aes anyways...
          if _.isEqual(m.mapped, mapped)
            m.aes.push(aes)
            merged = true
            break
        if not merged
          merging.push {aes: [aes], mapped: mapped}
    _.pluck merging, 'aes'

  makeLegends: (mapping) -> # ok, this will be a complex f'n. deep breath:
    # figure out which groups of aesthetics need to be represented
    aesGroups = @_mergeAes @layers

    # now iterate through existing legends AND the aesGroups to see
    #   1) if any existing legends need to be deleted,
    #      in which case move that legend from @legends into @deletedLEgends
    #   2) if any new legends need to be created
    #      in which case KEEP it in aesGroups (otherwise remove)
    idx = 0
    while idx < @legends.length
      legend = @legends[idx]
      legenddeleted = true
      i = 0
      while i < aesGroups.length
        aes = aesGroups[i]
        if _.isEqual aes, legend.aes
          aesGroups.splice i, 1
          legenddeleted = false
          break
        i++
      if legenddeleted
        @deletedLegends.push legend
        @legends.splice(idx, 1)
      else
        idx++
    # create new legends
    for aes in aesGroups
      @legends.push poly.guide.legend aes
    # make each legend
    for legend in @legends
      aes = legend.aes[0]
      legend.make
        domain: @domains[aes]
        guideSpec: @getSpec aes
        type: @scales[aes].tickType()
        mapping: @layerMapping
        keys: poly.getLabel(@layers, aes)
    @legends
  renderLegends: (dims, renderer) ->
    # NOTE: if this is changed, change dim.coffee dimension calculation
    legend.remove(renderer) for legend in @deletedLegends
    @deletedLegends = []
    offset = { x: 0, y : 0 }

    # axis offset
    y = 0
    for key, axis of @axes #this loop is dumb
      y = axis.y.getDimension()
      if y.position == 'right' and y.width > 0
        offset.x += y.width

    maxwidth = 0
    maxheight = dims.height - dims.guideTop - dims.paddingTop
    for legend in @legends # assume position = right
      newdim = legend.getDimension()
      if newdim.height + offset.y > maxheight
        offset.x += maxwidth + 5
        offset.y = 0
        maxwidth = 0
      if newdim.width > maxwidth
        maxwidth = newdim.width
      legend.render dims, renderer, offset
      offset.y += newdim.height
