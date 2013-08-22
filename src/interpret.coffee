fns =
  ident: (name) -> (row) -> row[name]
  const: (value) -> () -> value
  conditional: (cond, conseq, altern) -> (row) ->
    if cond(row) then conseq(row) else altern(row)
  infixop:
    "+": (lhs, rhs) -> (row) -> lhs(row) + rhs(row)
    "-": (lhs, rhs) -> (row) -> lhs(row) - rhs(row)
    "*": (lhs, rhs) -> (row) -> lhs(row) * rhs(row)
    "/": (lhs, rhs) -> (row) -> lhs(row) / rhs(row)
    "%": (lhs, rhs) -> (row) -> lhs(row) % rhs(row)
    ">": (lhs, rhs) -> (row) -> lhs(row) > rhs(row)
    "<": (lhs, rhs) -> (row) -> lhs(row) < rhs(row)
    "++": (lhs, rhs) -> (row) -> lhs(row) + rhs(row)
  trans:
    "log": (args) -> (row) -> Math.log(args[0](row))
    "bin": (args) -> (row) ->
      val = args[0](row)
      bw = args[1](row) # we actually need args[1] to be a const... :(
      # numeric
      if _.isNumber(bw)
        return Math.floor(val/bw)*bw
      # non-numeric
      _timeBinning = (n, timerange) =>
        m = moment.unix(val).startOf(timerange)
        m[timerange] n * Math.floor(m[timerange]()/n)
        m.unix()
      switch bw
        when 'week' then moment.unix(val).day(0).unix()
        when 'twomonth' then _timeBinning 2, 'month'
        when 'quarter' then _timeBinning 4, 'month'
        when 'sixmonth' then _timeBinning 6, 'month'
        when 'twoyear' then _timeBinning 2, 'year'
        when 'fiveyear' then _timeBinning 5, 'year'
        when 'decade' then _timeBinning 10, 'year'
        else moment.unix(val).startOf(bw).unix()

createFunction = (node) ->
  [nodeType, payload] = node
  fn =
    if nodeType is 'ident'
      fns.ident(payload.name)
    else if nodeType is 'const'
      value = poly.type.coerce(payload.value, {type: payload.type})
      fns.const(value)
    else if nodeType is 'infixop'
      lhs = createFunction(payload.lhs)
      rhs = createFunction(payload.rhs)
      fns.infixop[payload.opname](lhs, rhs)
    else if nodeType is 'conditional'
      cond = createFunction(payload.cond)
      conseq = createFunction(payload.conseq)
      altern = createFunction(payload.altern)
      fns.conditional(cond, conseq, altern)
    else if nodeType is 'call'
      args = (createFunction(arg) for arg in payload.args)
      fns.trans[payload.fname](args) # should all be transforms
  if fn then return fn
  throw poly.error.defn "Unknown operation of type: #{nodeType}"

poly.interpret = {
  createFunction
}
