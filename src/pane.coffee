poly.pane = {}
poly.pane.make = (grp, name) -> new Pane grp, name
class Pane extends poly.Renderable
  constructor: (multiindex, @str) ->
    @index = multiindex
    @layers = null
    @title = null
  make: (spec, data, @layers) ->
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
  _makeDomains: (spec, geoms, metas) ->
    poly.domain.make geoms, metas, spec.guides, spec.strict
  render: (renderer, offset, clipping, dims) ->
    @title.render renderer({}, false, false), dims, offset
    r = renderer(offset, clipping, true)
    for k, geom of @geoms
      geom.render(r)
  dispose: (renderer) ->
    for k, geom of @geoms
      geom.dispose(renderer)
    @geoms = {}
    @title.dispose(renderer)
