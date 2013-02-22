module "Utils"

test "median", ->
  deepEqual polyjs.debug.median([1]), 1
  deepEqual polyjs.debug.median([5,2,3,4,1]), 3
  deepEqual polyjs.debug.median([1,3,2,4]), 2.5
  deepEqual polyjs.debug.median([-1,-2,-3], true), -2
  deepEqual polyjs.debug.median([-1.5,10], true), 4.25

test "linear", ->
  deepEqual (polyjs.debug.linear(1,1,2,2) 3), 3
  deepEqual (polyjs.debug.linear(1,2,3,2) 5), 2
  deepEqual (polyjs.debug.linear(2,5,4,0) 6), -5
  deepEqual (polyjs.debug.linear(1,1.5,2,3) 3), 4.5
  deepEqual (polyjs.debug.linear(1,3,1,6) 0), -Infinity
  deepEqual (polyjs.debug.linear(2,3,2,3) 2), NaN

test "compare", ->
  deepEqual polyjs.debug.compare([],[]), {deleted: [], kept: [], added: []}
  deepEqual polyjs.debug.compare([1,2],[]), {deleted: [1,2], kept: [], added: []}
  deepEqual polyjs.debug.compare([], [1,2]), {deleted: [], kept: [], added: [1,2]}
  deepEqual polyjs.debug.compare([1,2,3], [1,2,3]), {deleted: [], kept: [1,2,3], added: []}
  deepEqual polyjs.debug.compare([1,2,3], [3,4,5]), {deleted: [1,2], kept: [3], added: [4,5]}
  deepEqual polyjs.debug.compare([1,2,3], [1,2,3,4,5,6]), {deleted: [], kept: [1,2,3], added: [4,5,6]}
  deepEqual polyjs.debug.compare([1,2,3,4,5,6], [1,2,3]), {deleted: [4,5,6], kept: [1,2,3], added: []}
  deepEqual polyjs.debug.compare(['A','B','C'], ['B', 'D']), {deleted: ['A', 'C'], kept: ['B'], added: ['D']}

test "sample", ->
  x = {a:2, b:3, c:4, d:5, e:7, f:8, g:9}
  y = polyjs.debug.sample x, 3
  equal _.size(y), 3
  y = polyjs.debug.sample x, 5
  equal _.size(y), 5
  y = polyjs.debug.sample x, 100
  equal _.size(y), _.size(x)

test "flatten", ->
  deepEqual polyjs.debug.flatten(null), []
  deepEqual polyjs.debug.flatten(2), [2]
  deepEqual polyjs.debug.flatten({'t':'scalefn', 'v': 2}), [2]
  deepEqual polyjs.debug.flatten([{'t':'scalefn', 'v': 2},{'t':'scalefn', 'v': 4}]), [2,4]
  deepEqual polyjs.debug.flatten([1,2,3,4]), [1,2,3,4]
  deepEqual polyjs.debug.flatten([2,3,[2,4]]), [2,3,2,4]
  deepEqual polyjs.debug.flatten([2,3,[2,4]]), [2,3,2,4]
  deepEqual polyjs.debug.flatten({'a':2, 'b':3}), [2,3]
  deepEqual polyjs.debug.flatten({'a':[2,3,4], 'b':3}), [2,3,4,3]

test "strSize", ->
  deepEqual polyjs.debug.strSize(''), 0
  deepEqual polyjs.debug.strSize('a'), 7
  deepEqual polyjs.debug.strSize('   '), 21
  deepEqual polyjs.debug.strSize('foo bar'), 49
  deepEqual polyjs.debug.strSize('\'"'), 14

test "sortArrays", ->
  numcomp = polyjs.debug.type.compare('num')
  sincomp = (a,b) -> numcomp(Math.sin(a), Math.sin(b))
  deepEqual polyjs.debug.sortArrays(numcomp, [[1,2,3],[1,2,3]]), [[1,2,3],[1,2,3]]
  deepEqual polyjs.debug.sortArrays(sincomp, [[1,2,3],[4,5,6]]), [[3,1,2],[6,4,5]]

test "type.impute", ->
  deepEqual polyjs.debug.type.impute([]), 'cat'
  deepEqual polyjs.debug.type.impute(['3', 4]), 'num'
  deepEqual polyjs.debug.type.impute(['1900-01-03']), 'date'
  deepEqual polyjs.debug.type.impute(['1','$2', '3,125', '$2,000']), 'num'
  deepEqual polyjs.debug.type.impute([0,1,2,3,4,5,6,'1900-01-03',7,8,9,0,1,2,3,4,5,6,7,8,9]), 'num'
  deepEqual polyjs.debug.type.impute([0,1,2,3,4,5,'1900-01-03',6,7,8]), 'date' #???

test "groupProcessedData", ->
  data =
    1:
      statData:[{x:1,b:'A'},{x:1,b:'A'},{x:1,b:'B'}]
      metaData : {
        x: {type:'num'}
        b: {type:'cat'}
      }
  result = polyjs.debug.groupProcessedData data, []
  deepEqual result, data

  result = polyjs.debug.groupProcessedData data, ['b']
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
  result = polyjs.debug.groupProcessedData data, []
  deepEqual result, data

  result = polyjs.debug.groupProcessedData data, ['b']
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

  result = polyjs.debug.groupProcessedData data, ['y']
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

  result = polyjs.debug.groupProcessedData data, ['y', 'b']
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
  y = polyjs.debug.cross {x:[1,2,3], y:[1,2]}
  deepEqual y.length, 6
  y = polyjs.debug.cross {x:[1,2,3]}
  deepEqual y.length, 3
  y = polyjs.debug.cross {x:[]}
  deepEqual y.length, 0
  y = polyjs.debug.cross {}
  deepEqual y.length, 1

test "stingify", ->
  y = polyjs.debug.stringify(['a','b']) {x:2, a:2, b:3}
  equal y, "a:2;b:3;"
  y = polyjs.debug.stringify(['a']) {x:2, a:2, b:3}
  equal y, "a:2;"
  y = polyjs.debug.stringify([]) {x:2, a:2, b:3}
  equal y, ""
