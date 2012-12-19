poly.format = (type, step) ->
  switch type
    when 'cat' then return poly.format.identity
    when 'num' then return poly.format.number(step)
    when 'date' then return poly.format.date(step)

poly.format.identity = (x) -> x

# add postfix
POSTFIXES = { 0: '', 3:'k', 6:'m', 9:'b', 12:'t'}
postfix = (num, pow) ->
  if !_.isUndefined(POSTFIXES[pow]) then num+POSTFIXES[pow]
  else num+'e'+(if pow > 0 then '+' else '-')+Math.abs(pow)
# add commas every third number
formatNumber = (n) ->
  if !isFinite(n) then return n
  s = ""+n
  abs = Math.abs(n)
  if (abs >= 1000)
    v  = (""+abs).split(/\./)
    i  = v[0].length % 3 || 3
    v[0] = s.slice(0,i + (n < 0)) + v[0].slice(i).replace(/(\d{3})/g,',$1')
    s = v.join('.')
  s

poly.format.number = (exp_original) -> (num) ->
  exp_fixed = 0
  exp_precision = 0
  exp = if exp_original? then exp_original else
    Math.floor(Math.log(Math.abs(if num is 0 then 1 else num))/Math.LN10)
  if exp_original? && (exp == 2 || exp == 5 || exp == 8 || exp == 11)
    exp_fixed = exp + 1
    exp_precision = 1
  else if (exp == -1)
    exp_fixed = 0
    exp_precision = if exp_original? then 1 else 2
  else if (exp == -2)
    exp_fixed = 0
    exp_precision = if exp_original? then 2 else 3
  else if (exp == 1 || exp == 2)
    exp_fixed = 0
  else if (exp > 3 && exp < 6)
    exp_fixed = 3
  else if (exp > 6 && exp < 9)
    exp_fixed = 6
  else if (exp > 9 && exp < 12)
    exp_fixed = 9
  else if (exp > 12 && exp < 15)
    exp_fixed = 12
  else
    exp_fixed = exp
    exp_precision = if exp_original? then 0 else 1
  rounded = Math.round(num / Math.pow(10, exp_fixed-exp_precision))
  rounded /= Math.pow(10, exp_precision)
  rounded = rounded.toFixed(exp_precision)
  postfix(formatNumber(rounded), exp_fixed)

poly.format.date = (format) ->
  if (format in poly.const.timerange)
    level = format
    if level is 'second'
      (date) -> moment.unix(date).format('h:mm:ss a')
    else if level is 'minute'
      (date) -> moment.unix(date).format('h:mm a')
    else if level is 'hour'
      (date) -> moment.unix(date).format('MMM D h a')
    else if level is 'day' or level is 'week'
      (date) -> moment.unix(date).format('MMM D')
    else if level is 'month'
      (date) -> moment.unix(date).format('YY/MM')
    else if level is 'year'
      (date) -> moment.unix(date).format('YYYY')
  else
    moment.unix(date).format(format)
