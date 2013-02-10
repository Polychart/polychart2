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
    @layers = @_makeLayers spec # spec may have changed!

    if not @geoms # hmm, this is bad... what about adding & removing?
      @geoms = {}
      for layer, i in @layers
        @geoms[i] = new poly.Geometry()

    @metas = {}

    for layer, i in @layers
      {geoms, meta} = layer.calculate(data[i].statData, data[i].metaData)
      @geoms[i].set geoms
      @metas[i] = meta
    @title ?= @_makeTitle spec # title may have changed?!? (or not...)
    @title.make title: @str
    @domains = @_makeDomains spec, @geoms, @metas
  _makeTitle: () -> poly.guide.title('facet')
  _makeLayers: (spec) ->
    _.map spec.layers, (layerSpec) -> poly.layer.make(layerSpec, spec.strict)
  _makeDomains: (spec, geoms, metas) ->
    poly.domain.make geoms, metas, spec.guides, spec.strict
  render: (renderer, offset, clipping, dims) ->
    @title.render renderer({}, false, false), dims, offset
    r = renderer(offset, clipping, true)
    for k, geom of @geoms
      geom.render(r)
  dispose: (renderer) ->
    for layer in @layers
      layer.dispose(renderer)
    @title.dispose(renderer)
