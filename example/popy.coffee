@examples ?= {}

@examples.popy_polar = (dom) ->
  data = polyjs.data
    json:
      [
        {gr: "Overall", p: 60, colgrp: '1'},
        {gr: "Grade 9", p: 10, colgrp: '2'},
        {gr: "Grade 10", p: 40, colgrp: '2'},
        {gr: "Grade 11", p: 50, colgrp: '2'},
        {gr: "Grade 12", p: 70, colgrp: '2'},
      ]
 
  c = polyjs.chart
    layers: [
      { data: data, type: 'bar', y:'p', color: 'colgrp' }
    ]
    facet:
      type: 'wrap'
      var: 'gr'
      cols: 5
      formatter: (index) -> index.gr
    coord:
      type: 'polar'
    guides:
      y: min: 0, max:100, position: 'none', padding: 0
      x: position: 'none', padding: 0
    dom: dom
    height: 150
    width: 600
    title: 'Percentage of student completed 40 hours'

@examples.popy_gr = (dom) ->
  data = polyjs.data
    json:
      [
        {gr: "Grade 9", p: 10},
        {gr: "Grade 10", p: 40},
        {gr: "Grade 11", p: 50},
        {gr: "Grade 12", p: 70},
      ]
    meta:
      gr: type: 'cat'

  data.derive ((x) -> x.p + 5), 'p_10'
  data.derive ((x) -> "#{x.p}%"), 'percent'
  
  c = polyjs.chart
    layers: [
      { data: data, type: 'bar', x:'gr', y:'p' , color: {const:'#ABC'} }
      { data: data, type: 'text', x:'gr', y:'p_10', text: 'percent', color: {const:'black'} }
    ]
    guides:
      y: { min: 0, max:100, title: "Percentage"}
      x: { levels : ["Grade 9", "Grade 10", "Grade 11", "Grade 12"], title: 'Grade'}
    dom: dom
    title: 'Percentage of student completed 40 hours'

@examples.popy_interests = (dom) ->
  data = polyjs.data
    json:
      [
        {gr: "Health Care", num: 500}
        {gr: "Events", num: 400}
        {gr: "Recreation", num: 370}
        {gr: "Technology", num: 370}
        {gr: "Animal/Pets", num: 70}
        {gr: "Senior Services", num: 30}
      ]

  data.derive ((x) -> x.num+40), 'p_50'
  data.derive ((x) -> "#{Math.round(x.num/800*100)}%"), 'percent'
  
  c = polyjs.chart
    layers: [
      { data: data, type: 'bar', x: {var: 'gr', sort:'num'}, y:'num' }
      { data: data, type: 'text', x:'gr', y:'p_50', text:'percent', color: {const:'black'}}
    ]
    dom: dom
    guide:
      y: { min: 0, max:700 }
    coord: { type:'cartesian', flip: true }
    title: 'Student Interests'

@examples.popy_intexp = (dom) ->
  data = polyjs.data
    json:
      [
        {gr: "Health Care", num: 500, type: 'Interest'}
        {gr: "Events", num: 400, type: 'Interest'}
        {gr: "Recreation", num: 370, type: 'Interest'}
        {gr: "Technology", num: 370, type: 'Interest'}
        {gr: "Animal/Pets", num: 70, type: 'Interest'}
        {gr: "Senior Services", num: 30, type: 'Interest'}
        {gr: "Health Care", num: 500, type: 'Org Type'}
        {gr: "Events", num: 400, type: 'Org Type'}
        {gr: "Recreation", num: 370, type: 'Org Type'}
        {gr: "Technology", num: 370, type: 'Org Type'}
        {gr: "Animal/Pets", num: 70, type: 'Org Type'}
        {gr: "Senior Services", num: 30, type: 'Org Type'}
      ]

  data.derive ((x) -> x.num+50), 'p_50'
  data.derive ((x) -> "#{Math.round(x.num/800*100)}%"), 'percent'
  
  c = polyjs.chart
    layers: [
      { data: data, type: 'bar', x: {var: 'gr', sort:'num'}, y:'num', color: 'type',  position:'dodge' }
      { data: data, type: 'text', x:'gr', y:'p_50', text:'percent', color: {const:'black'}}
    ]
    dom: dom
    guide:
      y: { min: 0, max:700 }
    coord: { type:'cartesian', flip: true }
    title: 'Student Interests'

@examples.popy_rating = (dom) ->
  data = polyjs.data
    json:
      [
        {gr: "Excellent", num: 500}
        {gr: "Very Good", num: 400}
        {gr: "Average", num: 370}
        {gr: "Poor", num: 370}
        {gr: "Terrible", num: 70}
      ]
  
  c = polyjs.chart
    layers: [
      { data: data, type: 'bar', x: {var: 'gr', sort:'num'}, y:'num' }
    ]
    dom: dom
    guide:
      y: { min: 0, max:700 }
    coord: { type:'cartesian', flip: true }
    title: 'Volunteer Experience Rating'

@examples.popy_rating_pie = (dom) ->
  data = polyjs.data
    json:
      [
        {gr: "Excellent", num: 500}
        {gr: "Very Good", num: 400}
        {gr: "Average", num: 370}
        {gr: "Poor", num: 370}
        {gr: "Terrible", num: 70}
      ]
  
  c = polyjs.chart
    layers: [
      { data: data, type: 'bar', y:'num', color: 'gr' }
    ]
    dom: dom
    coord: { type:'polar'}
    guide:
      x: position: 'none'
      y: position: 'none'
      color: levels: ['Excellent', 'Very Good', 'Average', 'Poor', 'Terrible']
    title: 'Volunteer Experience Rating'
    width: 400
    height: 300
