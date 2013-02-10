poly.pane = {}
poly.pane.make = (spec, grp, formatter) -> new Pane spec, grp, formatter
class Pane extends poly.Renderable
  constructor: (spec, multiindex, formatter) ->
    @spec = spec
    @index = multiindex
    @str = formatter multiindex
    @layers = null
    @title = null
  make: (spec, data) ->
    @layers ?= @_makeLayers spec # spec may have changed!
    @title ?= @_makeTitle spec # title may have changed?!? (or not...)
    @title.make title: @str
    for layer, id in @layers
      layer.make spec.layers[id], data[id].statData, data[id].metaData
    @domains = @_makeDomains spec, @layers
  _makeTitle: () -> poly.guide.title('facet')
  _makeLayers: (spec) ->
    _.map spec.layers, (layerSpec) -> poly.layer.make(layerSpec, spec.strict)
  _makeDomains: (spec, layers) ->
    poly.domain.make layers, spec.guides, spec.strict
  render: (renderer, offset, clipping, dims) ->
    @title.render renderer({}, false, false), dims, offset
    for layer in @layers
      {sampled} = layer.render renderer(offset, clipping, true)
  dispose: (renderer) ->
    for layer in @layers
      layer.dispose(renderer)
    @title.dispose(renderer)
