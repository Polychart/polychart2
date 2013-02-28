poly.tick.make({0,1000}, null, 'num-log')
length=ticks.length
if ticks[length]>1000
  throw poly.error.tick "The max value of the numbers in the array is greater than the max specified"
else if ticks[length]<1000
  throw poly.error.tick "The max value of the numbers in the array is less than the max specified"
if ticks[0]>0
  throw poly.error.tick "The min value of the ticks array is less than the min specified"
else if ticks[0]<0
  throw poly.error.tick "The min value of the ticks array is greater than the min specified"
for i in ticks
  ticks0=ticks[i]
  ticks1=ticks[i+1]
  ticks2=ticks[i+2]
  if ticks1/ticks0 isnt ticks2/ticks1
    throw poly.error.tick "The numbers in the arrary do not increase by a constant factor"
