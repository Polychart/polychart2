module "tick"
jsondata = ({index:i, value:Math.random()} for i in [0..10000])
test "max values", ->
  deepEqual polyjs.debug.tick.poly.tick.make.ticks[ticks.length], 10000

test "min values", ->
  deepEqual polyjs.debug.tick.numlog.ticks[0], 0

test "correct step size", ->
  deepEqual polyjs.debug.tick.numlog.tmp, 10

test "correct value of array", ->
  deepEqual polyjs.debug.tick.numlog.ticks, [0,10,100,1000,10000]



