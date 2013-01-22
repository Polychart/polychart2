module "Utils"

test "median", ->
  deepEqual polyjs.median([1]), 1
  deepEqual polyjs.median([5,2,3,4,1]), 3
  deepEqual polyjs.median([1,3,2,4]), 2.5
  deepEqual polyjs.median([-1,-2,-3], true), -2
  deepEqual polyjs.median([-1.5,10], true), 4.25

test "linear", ->
  deepEqual (polyjs.linear(1,1,2,2) 3), 3
  deepEqual (polyjs.linear(1,2,3,2) 5), 2
  deepEqual (polyjs.linear(2,5,4,0) 6), -5
  deepEqual (polyjs.linear(1,1.5,2,3) 3), 4.5
  deepEqual (polyjs.linear(1,3,1,6) 0), -Infinity
  deepEqual (polyjs.linear(2,3,2,3) 2), NaN

test "compare", ->
  deepEqual polyjs.compare([],[]), {deleted: [], kept: [], added: []}
  deepEqual polyjs.compare([1,2],[]), {deleted: [1,2], kept: [], added: []}
  deepEqual polyjs.compare([], [1,2]), {deleted: [], kept: [], added: [1,2]}
  deepEqual polyjs.compare([1,2,3], [1,2,3]), {deleted: [], kept: [1,2,3], added: []}
  deepEqual polyjs.compare([1,2,3], [3,4,5]), {deleted: [1,2], kept: [3], added: [4,5]}
  deepEqual polyjs.compare([1,2,3], [1,2,3,4,5,6]), {deleted: [], kept: [1,2,3], added: [4,5,6]}
  deepEqual polyjs.compare([1,2,3,4,5,6], [1,2,3]), {deleted: [4,5,6], kept: [1,2,3], added: []}
  deepEqual polyjs.compare(['A','B','C'], ['B', 'D']), {deleted: ['A', 'C'], kept: ['B'], added: ['D']}

test "sample", ->
  x = {a:2, b:3, c:4, d:5, e:7, f:8, g:9}
  y = polyjs.sample x, 3
  equal _.size(y), 3
  y = polyjs.sample x, 5
  equal _.size(y), 5
  y = polyjs.sample x, 100
  equal _.size(y), _.size(x)

test "flatten", ->
  deepEqual polyjs.flatten(null), []
  deepEqual polyjs.flatten(2), [2]
  deepEqual polyjs.flatten({'t':'scalefn', 'v': 2}), [2]
  deepEqual polyjs.flatten([{'t':'scalefn', 'v': 2},{'t':'scalefn', 'v': 4}]), [2,4]
  deepEqual polyjs.flatten([1,2,3,4]), [1,2,3,4]
  deepEqual polyjs.flatten([2,3,[2,4]]), [2,3,2,4]
  deepEqual polyjs.flatten([2,3,[2,4]]), [2,3,2,4]
  deepEqual polyjs.flatten({'a':2, 'b':3}), [2,3]
  deepEqual polyjs.flatten({'a':[2,3,4], 'b':3}), [2,3,4,3]

test "strSize", ->
  deepEqual polyjs.strSize(''), 0
  deepEqual polyjs.strSize('a'), 7
  deepEqual polyjs.strSize('   '), 21
  deepEqual polyjs.strSize('foo bar'), 49
  deepEqual polyjs.strSize('\'"'), 14

test "sortArrays", ->
  deepEqual polyjs.sortArrays(((x)->x), [[1,2,3],[1,2,3]]), [[1,2,3],[1,2,3]]
  deepEqual polyjs.sortArrays(Math.sin, [[1,2,3],[4,5,6]]), [[3,1,2],[6,4,5]]

test "type.impute", ->
  deepEqual polyjs.type.impute([]), 'cat'
  deepEqual polyjs.type.impute(['3', 4]), 'num'
  deepEqual polyjs.type.impute(['1900-01-03']), 'date'
  deepEqual polyjs.type.impute(['1','$2', '3,125', '$2,000']), 'num'
  deepEqual polyjs.type.impute([0,1,2,3,4,5,6,'1900-01-03',7,8,9,0,1,2,3,4,5,6,7,8,9]), 'num'
  deepEqual polyjs.type.impute([0,1,2,3,4,5,'1900-01-03',6,7,8]), 'date' #???

test "groupProcessedData", ->
  data =
    1:
      statData:[{x:1,b:'A'},{x:1,b:'A'},{x:1,b:'B'}]
      metaData : {
        x: {type:'num'}
        b: {type:'cat'}
      }
  result = polyjs.groupProcessedData data, []
  deepEqual result, data

  result = polyjs.groupProcessedData data, ['b']
  deepEqual result,
    grouped: true
    key: 'b'
    values:
      A:
        1:
          metaData: data[1].metaData
          statData: [{x:1,b:'A'},{x:1,b:'A'}]
      B:
        1:
          metaData: data[1].metaData
          statData: [{x:1,b:'B'}]

  data =
    1:
      statData:[{x:1,b:'A'},{x:1,b:'A'},{x:1,b:'B'}]
      metaData : {
        x: {type:'num'}
        b: {type:'cat'}
      }
    2:
      statData:[{y:1,b:'A'},{y:1,b:'A'},{y:2,b:'B'}]
      metaData : {
        y: {type:'num'}
        b: {type:'cat'}
      }
  result = polyjs.groupProcessedData data, []
  deepEqual result, data

  result = polyjs.groupProcessedData data, ['b']
  deepEqual result,
    grouped: true
    key: 'b'
    values:
      A:
        1:
          metaData: data[1].metaData
          statData: [{x:1,b:'A'},{x:1,b:'A'}]
        2:
          metaData: data[2].metaData
          statData: [{y:1,b:'A'},{y:1,b:'A'}]
      B:
        1:
          metaData: data[1].metaData
          statData: [{x:1,b:'B'}]
        2:
          metaData: data[2].metaData
          statData: [{y:2,b:'B'}]

  result = polyjs.groupProcessedData data, ['y']
  deepEqual result,
    grouped: true
    key: 'y'
    values:
      1:
        1: data[1]
        2:
          metaData: data[2].metaData
          statData: [{y:1,b:'A'},{y:1,b:'A'}]
      2:
        1: data[1]
        2:
          metaData: data[2].metaData
          statData: [{y:2,b:'B'}]

  result = polyjs.groupProcessedData data, ['y', 'b']
  deepEqual result,
    grouped: true
    key: 'y'
    values:
      1:
        grouped: true
        key: 'b'
        values:
          A:
            1:
              metaData: data[1].metaData
              statData: [{x:1,b:'A'},{x:1,b:'A'}]
            2:
              metaData: data[2].metaData
              statData: [{y:1,b:'A'},{y:1,b:'A'}]
          B:
            1:
              metaData: data[1].metaData
              statData: [{x:1,b:'B'}]
            2:
              metaData: data[2].metaData
              statData: []
      2:
        grouped: true
        key: 'b'
        values:
          A:
            1:
              metaData: data[1].metaData
              statData: [{x:1,b:'A'},{x:1,b:'A'}]
            2:
              metaData: data[2].metaData
              statData: []
          B:
            1:
              metaData: data[1].metaData
              statData: [{x:1,b:'B'}]
            2:
              metaData: data[2].metaData
              statData: [{y:2,b:'B'}]

test "utils.cross", ->
  y = polyjs.cross {x:[1,2,3], y:[1,2]}
  deepEqual y.length, 6
  y = polyjs.cross {x:[1,2,3]}
  deepEqual y.length, 3
  y = polyjs.cross {x:[]}
  deepEqual y.length, 0
  y = polyjs.cross {}
  deepEqual y.length, 1

test "stingify", ->
  y = polyjs.stringify(['a','b']) {x:2, a:2, b:3}
  equal y, "a:2;b:3;"
  y = polyjs.stringify(['a']) {x:2, a:2, b:3}
  equal y, "a:2;"
  y = polyjs.stringify([]) {x:2, a:2, b:3}
  equal y, ""
