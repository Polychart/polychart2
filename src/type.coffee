###
Impute types from values
###
THRESHOLD = 0.95

poly.type = {}

poly.type.impute = (values) ->
  date = 0
  num = 0
  length = 0
  for value in values
    if not value? or value is undefined or value is null
      continue
    length++
    # check if it's a number
    if not isNaN(value) or not isNaN value.replace(/\$|\,/g,'')
      num++
    # check if it's a date
    m = moment(value)
    if m? and m.isValid()
      date++
  if num > THRESHOLD*length
    return 'num'
  if date > THRESHOLD*length
    return 'date'
  return 'cat'

###
Parse values into correct types
###
poly.type.coerce = (value, meta) ->
  if _.isUndefined(value) or _.isNull(value)
    value
  else if meta.type is 'cat'
    value
  else if meta.type is 'num'
    if not isNaN value
      +value
    else
      +((""+value).replace(/\$|\,/g,''))
  else if meta.type is 'date'
    if meta.format
      if meta.format is 'unix'
        moment.unix(value).unix() #sounds inefficient, but error checks?
      else
        moment(value, meta.format).unix()
    else
      if isFinite(value) and value >= Math.pow(10, 9) # Assume that unix time stamp
        moment.unix(value).unix()
      else
        moment(value).unix()
  else
    undefined

poly.type.compare = (type) ->
  switch type
    when 'cat' then compareCat
    else compareNum
compareCat = (a, b) ->
  if a is b then return 0
  if not _.isString(a) then a = "" + a
  if not _.isString(b) then b = "" + b
  al = a.toLowerCase()
  bl = b.toLowerCase()
  if al is bl
    if a < b        then -1
    else if a > b   then  1
    else                  0
  else
    if al < bl      then -1
    else if al > bl then  1
    else                  0
compareNum = (a, b) ->
  if a is b then 0
  else if a is null then return 1
  else if b is null then -1
  else if a < b then return -1
  else if a > b then 1
  else 0
