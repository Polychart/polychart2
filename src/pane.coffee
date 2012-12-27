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
  render: (paper, dims, renderer, rendererNoClip) ->
    for layer in @layers
      {sampled} = layer.render renderer
    #@scaleSet.renderAxes dims, rendererNoClip

