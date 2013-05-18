@examples ?= {}

@examples.pivot = (dom) ->
  data = polyjs.data data:{
    cat1: ['a', 'a', 'a', 'a', 'a', 'a', 'b', 'b', 'b', 'b', 'b', 'b']
    cat2: ['c', 'd', 'c', 'd', 'c', 'd', 'c', 'd', 'c', 'd', 'c', 'd']
    val1: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
  }
  polyjs.pivot
    data: data
    rows: ['cat1', 'cat2']
    values: ['sum(val1)']
