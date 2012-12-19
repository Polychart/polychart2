module "Utils"
test "flatten", ->
  deepEqual gg.flatten(null), []
  deepEqual gg.flatten(2), [2]
  deepEqual gg.flatten({'t':'scalefn', 'v': 2}), [2]
  deepEqual gg.flatten([{'t':'scalefn', 'v': 2},{'t':'scalefn', 'v': 4}]), [2,4]
  deepEqual gg.flatten([1,2,3,4]), [1,2,3,4]
  deepEqual gg.flatten([2,3,[2,4]]), [2,3,2,4]
  deepEqual gg.flatten([2,3,[2,4]]), [2,3,2,4]
  deepEqual gg.flatten({'a':2, 'b':3}), [2,3]
  deepEqual gg.flatten({'a':[2,3,4], 'b':3}), [2,3,4,3]
