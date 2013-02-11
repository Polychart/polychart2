poly.scaleset = (guideSpec, domains, ranges) ->
  return new ScaleSet(guideSpec, domains, ranges)

class ScaleSet
  constructor: (tmpRanges, coord) ->
    # note that axes.x is the axis for the x-aesthetic. it may or ma NOT be
    # the x-axis displayed on the screen.
    @coord = coord
    @ranges = tmpRanges
    @axes = poly.guide.axes()
    @legends = poly.guide.legends()

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
  _makeXScale: () -> @scales.x.make @domainx, @ranges.x, @getSpec('x').padding
  _makeYScale: () -> @scales.y.make @domainy, @ranges.y, @getSpec('y').padding
  _makeScales : (guideSpec, domains, ranges) ->
    # this function contains information about default scales!
    # todo: typechecking.
    specScale = (a) ->
      if guideSpec and guideSpec[a]? and guideSpec[a].scale?
        if _.isFunction(guideSpec[a].scale)
          type: 'custom'
          function: guideSpec[a].scale
        else
          guideSpec[a].scale
      else
        null
    scales = {}
    # x 
    scales.x =  poly.scale.make specScale('x') || {type: 'linear'}
    scales.x.make(domains.x, ranges.x, @getSpec('x').padding)
    # y
    scales.y =  poly.scale.make specScale('y') || {type: 'linear'}
    scales.y.make(domains.y, ranges.y, @getSpec('y').padding)
    # color
    if domains.color?
      if domains.color.type == 'cat'
        scales.color = poly.scale.make specScale('color') || {type: 'color'}
      else
        defaultSpec = {type:'gradient', upper:'steelblue', lower:'red'}
        scales.color = poly.scale.make specScale('color') || defaultSpec
      scales.color.make(domains.color)
    # size
    if domains.size?
      scales.size = poly.scale.make specScale('size') || {type: 'area'}
      scales.size.make(domains.size)
    # opacity
    if domains.opacity?
      scales.opacity= poly.scale.make specScale('opacity') || {type: 'opacity'}
      scales.opacity.make(domains.opacity)
    # text
    scales.text = poly.scale.make {type: 'identity'}
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

  makeTitles: (maintitle) ->
    @titles ?=
      x: poly.guide.title @coord.axisType('x')
      y: poly.guide.title @coord.axisType('y')
      main: poly.guide.title('main')
    @titles.main.make
      title: maintitle
      guideSpec: {}
      position: "top"
    @titles.x.make
      guideSpec: @getSpec 'x'
      title: poly.getLabel @layers, 'x'
    @titles.y.make
      guideSpec: @getSpec 'y'
      title: poly.getLabel @layers, 'y'
  titleOffset: (dim) ->
    offset = {}
    for key, title of @titles
      o = title.getDimension()
      for dir in ['left', 'right', 'top',' bottom']
        if o[dir]
          offset[dir] ?= 0
          offset[dir] += o[dir]
    offset
  renderTitles: (dims, renderer) ->
    renderer = renderer({}, false, false)
    o = @axesOffset(dims)
    @titles.x.render renderer, dims, o
    @titles.y.render renderer, dims, o
    @titles.main.render renderer, dims, o
  disposeTitles: (renderer) ->
    @titles = {}
    @titles.x.dispose(renderer)
    @titles.y.dispose(renderer)
    @titles.main.dispose(renderer)

  makeAxes: () ->
    @axes.make
      domains: {x: @domainx, y: @domainy}
      coord : @coord
      scales : @scales
      specs: @guideSpec ? {}
      labels: {x: poly.getLabel(@layers, 'x'), y: poly.getLabel(@layers, 'y')}

  axesOffset: (dims) -> @axes.getDimension(dims)
  renderAxes: (dims, renderer, facet) -> @axes.render(dims, renderer, facet)
  disposeAxes: (renderer) -> @axes.dispose(renderer)
  _mapLayers: (layers) ->
    obj = {}
    for aes in poly.const.aes
      obj[aes] =
        _.map layers, (layer) ->
          if layer.mapping[aes]?
            { type: 'map', value: layer.mapping[aes]}
          else if layer.consts[aes]?
            { type: 'const', value: layer.consts[aes]}
          else
            layer.defaults[aes]
    obj
  makeLegends: (mapping) ->
    @legends.make
      mapping: mapping
      domains: @domains
      layers: @layers
      guideSpec: @guideSpec
      scales: @scales
      layerMapping: @layerMapping
  legendOffset: (dims) -> @legends.getDimension(dims)
  renderLegends: (dims, renderer) ->
    offset = { x: 10, y : 0 } # initial spacing
    # axis offset
    offset.x += @axesOffset(dims).right ? 0
    offset.x += @titleOffset(dims).right ? 0
    @legends.render(dims, renderer, offset)
  disposeLegends: (renderer) -> @legends.dispose(renderer)
