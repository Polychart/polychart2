@examples ?= {}

@examples.storage = (dom) ->
  data = polyjs.data storage
  c = polyjs.chart
    layer:
      data: data
      type: "point"
      x: "Date"
      y: "UnitCost"
    guide:
      y: scale: type: 'log'
    dom: dom
    height: 600
    width: 600

