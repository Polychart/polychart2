module "Utils"
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
