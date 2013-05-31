@examples ?= {}

@examples.pivot = (dom) ->
  data = polyjs.data data:{
    cat1: ['a', 'a', 'a', 'a', 'a', 'a', 'b', 'b', 'b', 'b', 'b', 'b']
    cat2: ['c', 'd', 'e', 'd', 'e', 'e', 'c', 'd', 'c', 'd', 'c', 'd']
    cat3: ['z', 'z', 'z', 'z', 'z', 'z', 'z', 'z', 'z', 'z', 'z', 'z']
    val1: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
  }
  polyjs.pivot
    data: data
    columns: ['cat1', 'cat2']
    rows: ['cat3']
    values: ['sum(val1)', 'mean(val1)']
    dom: dom
