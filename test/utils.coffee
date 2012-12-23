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
  deepEqual polyjs.sortArrays(Math.sin, [[1,2,3],[4,5,6]]), [[3,1,2],[5,4,6]]

test "varType", ->
  deepEqual polyjs.varType([]), 'cat'
  deepEqual polyjs.varType(['3', 4]), 'num'
  deepEqual polyjs.varType(['1900-01-03']), 'date'
  deepEqual polyjs.varType(['1','$2', '3,125', '$2,000']), 'num'
  deepEqual polyjs.varType([0,1,2,3,4,5,6,'1900-01-03',7,8,9,0,1,2,3,4,5,6,7,8,9]), 'num'
  deepEqual polyjs.varType([0,1,2,3,4,5,'1900-01-03',6,7,8]), 'cat'
