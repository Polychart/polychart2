poly.pane = {}
poly.pane.make = (spec, grp) -> new Pane spec, grp
class Pane
  constructor: (spec, multiindex) ->
    @spec = spec
    @index = multiindex
  make: (spec, data) ->
    @layers ?= @_makeLayers spec
    for layer, id in @layers
      layer.make spec.layers[id], data[id].statData, data[id].metaData
    @domains = @_makeDomains spec, @layers
  _makeLayers: (spec) ->
    _.map spec.layers, (layerSpec) -> poly.layer.make(layerSpec, spec.strict)
  _makeDomains: (spec, layers) ->
    poly.domain.make layers, spec.guides, spec.strict
  render: (params) ->
    {dims, renderer, rendererGuide, coord, axes} = params
    for layer in @layers
      {sampled} = layer.render renderer

      axisDim =
        top: dims.paddingTop + dims.guideTop
        left : dims.paddingLeft + dims.guideLeft
        right: dims.paddingLeft + dims.guideLeft + dims.chartWidth
        bottom : dims.paddingTop + dims.guideTop + dims.chartHeight
        width: dims.chartWidth
        height: dims.chartHeight
      axes.x.render axisDim, coord, rendererGuide
      axes.y.render axisDim, coord, rendererGuide
