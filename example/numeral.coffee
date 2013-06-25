@examples ?= {}

data = polyjs.data data:{
  cat: ['a', 'a', 'a', 'a', 'a', 'a', 'b', 'b', 'b', 'b', 'b', 'b']
  val: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12.12413252523523]
}

@examples.numeral = (dom) ->
  polyjs.numeral
    data: data
    value: 'sum(val)'
    filter: cat: in: ['b']
    dom: dom
