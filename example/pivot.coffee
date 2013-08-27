@examples ?= {}

data = polyjs.data data:{
  cat1: ['a', 'a', 'a', 'a', 'a', 'a', 'b', 'b', 'b', 'b', 'b', 'b']
  cat2: ['c', 'd', 'e', 'd', 'e', 'e', 'c', 'd', 'c', 'd', 'c', 'd']
  cat3: ['z', 'z', 'z', 'z', 'z', 'z', 'z', 'z', 'z', 'z', 'z', 'z']
  val1: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 52]
  date: ['2013-01-01', '2013-02-02', '2013-05-03', '2013-04-04', '2012-12-12',
         '2013-02-05', '2013-07-07', '2013-05-05',  '2013-04-04', '2012-12-12',
         '2013-04-04', '2012-12-12']
}

@examples.pivot_both = (dom) ->
  polyjs.pivot
    data: data
    columns: ['cat1', 'cat2']
    rows: ['cat3']
    values: ['sum(val1)', 'mean(val1)']
    dom: dom

@examples.pivot_both_smallnum = (dom) ->
  data.derive ((x) -> x.val1/100000), 'val2'
  polyjs.pivot
    data: data
    columns: ['cat1']
    rows: ['cat3', 'cat2']
    values: ['sum(val2)']
    dom: dom

@examples.pivot_both_largenum = (dom) ->
  data.derive ((x) -> x.val1*100000), 'val3'
  polyjs.pivot
    data: data
    columns: ['cat1']
    rows: ['cat3', 'cat2']
    values: ['sum(val3)']
    dom: dom

@examples.pivot_rows_only = (dom) ->
  polyjs.pivot
    data: data
    columns: []
    rows: ['cat3', 'cat2','cat1']
    values: ['sum(val1)', 'mean(val1)']
    dom: dom

@examples.pivot_cols_only = (dom) ->
  polyjs.pivot
    data: data
    columns: ['cat2', 'cat1','cat3']
    rows: []
    values: ['sum(val1)', 'mean(val1)']
    dom: dom

@examples.pivot_one_val = (dom) ->
  polyjs.pivot
    data: data
    columns: []
    rows: ['cat3', 'cat1', 'cat2']
    values: ['sum(val1)']
    dom: dom

@examples.pivot_full = (dom) ->
  polyjs.pivot
    data: data
    columns: []
    rows: ['cat3', 'cat1', 'cat2']
    values: ['sum(val1)']
    dom: dom
    full: true

@examples.pivot_binned = (dom) ->
  polyjs.pivot
    data: data
    columns: []
    rows: ['bin(val1, 5)']
    values: ['sum(val1)']
    dom: dom
    full: true

@examples.pivot_binned_date = (dom) ->
  polyjs.pivot
    data: data
    columns: []
    rows: ['bin(date, "month")']
    values: ['sum(val1)']
    dom: dom
    full: true

@examples.pivot_filtered = (dom) ->
  polyjs.pivot
    data: data
    columns: []
    rows: ['bin(val1, 5)']
    values: ['sum(val1)']
    dom: dom
    full: true
    filter: val1: ge: 10

