@examples ?= {}

@examples.content_bars = (dom) ->
  data = polyjs.data {data: content, meta: {dataset_id: {type: 'num'}, user_id: {type: 'num'}, public: {type: 'cat'}}}
  spec = {
    layers: [
      {data : data, type: 'point', x: 'bin(dataset_id, 100)', y: 'public', color: 'count(*)'}
    ]
    dom: dom
  }
  c = polyjs.chart spec

@examples.email_bars = (dom) ->
  data = polyjs.data {data: emails, meta: {created: {type: 'date'}, id: {type: 'num'}}}
  spec = {
    width: 900
    layers: [
      {data: data, type: 'bar', x: 'bin(created, "day")', y: 'count(id)'}
    ]
    dom: dom
  }
  c = polyjs.chart spec


@examples.email_pie = (dom) ->
  data = polyjs.data {data: emails, meta: {created: {type: 'date'}, success: {type: 'cat'}}}
  spec = {
    layers: [
      {data: data, type: 'bar', y: 'count(created)', color: 'success'}
    ]
    coord:{ type: 'polar' }
    dom: dom
  }
  c = polyjs.chart spec

@examples.email_polarbars = (dom) ->
  data = polyjs.data {data: emails, meta: {id: {type: 'num'}, success: {type: 'cat'}}}
  spec = {
    layers: [
      {data: data, type: 'bar', x: 'bin(id,100)', y: 'count(success)'}
    ]
    coord: {type: 'polar'}
    dom: dom
  }
  c = polyjs.chart spec
