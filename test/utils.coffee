module "Utils"
test "flatten", ->
  deepEqual poly.flatten(null), []
  deepEqual poly.flatten(2), [2]
  deepEqual poly.flatten({'t':'scalefn', 'v': 2}), [2]
  deepEqual poly.flatten([{'t':'scalefn', 'v': 2},{'t':'scalefn', 'v': 4}]), [2,4]
  deepEqual poly.flatten([1,2,3,4]), [1,2,3,4]
  deepEqual poly.flatten([2,3,[2,4]]), [2,3,2,4]
  deepEqual poly.flatten([2,3,[2,4]]), [2,3,2,4]
  deepEqual poly.flatten({'a':2, 'b':3}), [2,3]
  deepEqual poly.flatten({'a':[2,3,4], 'b':3}), [2,3,4,3]
