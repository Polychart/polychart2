@examples ?= {}

@examples.backend_point = (dom) ->
  data = polyjs.data.url "/db?table=example1&limit=50", true
  spec =
    layer:
      data: data
      type: 'point'
      x: 'grp'
      y: 'val1'
    dom: dom
  c = polyjs.chart spec

@examples.backend_bar = (dom) ->
  data = polyjs.data.url "/db?table=example1&limit=50", true
  spec =
    layer:
      data: data
      type: 'bar'
      x: 'grp'
      y: 'val1'
      color: 'category'
    dom: dom
  c = polyjs.chart spec

@examples.backend_sum = (dom) ->
  data = polyjs.data.url "/db?table=example1&limit=50", true
  spec =
    layer:
      data: data
      type: 'bar'
      x: 'grp'
      y: 'sum(val1)'
    dom: dom
  c = polyjs.chart spec

@examples.backend_count = (dom) ->
  data = polyjs.data.url "/db?table=example1&limit=50", true
  spec =
    layer:
      data: data
      type: 'bar'
      x: 'grp'
      y: 'count(val1)'
    dom: dom
  c = polyjs.chart spec
