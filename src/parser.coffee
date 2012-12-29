###############################################################################
# utilities
###############################################################################
unquote = (str, quote) ->
  n = str.length
  for quote in ['"', "'"]
    if str[0] is quote and str[n-1] is quote
      return str[1..(n-2)]
  return str
zipWith = (op) -> (xs, ys) ->
  #if xs.length isnt ys.length
  #  trow some error ("zipWith: lists have different length: [#{xs}], [#{ys}]")
  op(xval, ys[ix]) for xval, ix in xs
zip = zipWith (xval, yval) -> [xval, yval]
assocsToObj = (assocs) ->
  obj = {}
  for [key, val] in assocs
    obj[key] = val
  obj
dictGet = (dict, key, defval = null) -> (key of dict and dict[key]) or defval
dictGets = (dict, keyVals) ->
  fin = {}
  for key, defval of keyVals
    val = dictGet(dict, key, defval)
    if val isnt null
      fin[key] = val
  fin
mergeObjLists = (dicts) ->
  fin = {}
  for dict in dicts
    for key of dict
      fin[key] = dict[key].concat(dictGet(fin, key, []))
  fin
dedup = (vals, trans = (x) -> x) ->
  unique = {}
  unique[trans val] = val for val in vals
  val for _, val of unique
dedupOnKey = (key) -> (vals) -> dedup(vals, (val) -> val[key])
showCall = (fname, args) -> "#{fname}(#{args})"
showList = (xs) -> "[#{xs}]"

###############################################################################
# parsing
###############################################################################
class Stream
  constructor: (src) -> @buffer = (val for val in src).reverse()
  empty: -> @buffer.length is 0
  peek: -> if @empty() then null else @buffer[@buffer.length - 1]
  get: -> if @empty() then null else @buffer.pop()
  toString: -> showCall('Stream', showList([@buffer...].reverse()))

class Token
  @Tag = {
    symbol: 'symbol', literal: 'literal',
    lparen: '(', rparen: ')', comma: ','}
  constructor: (@tag) ->
  toString: -> "<#{@contents().toString()}>"
  contents: -> [@tag]
class Symbol extends Token
  constructor: (@name) ->
    @name = unquote @name
    super Token.Tag.symbol
  contents: -> super().concat([@name])
class Literal extends Token
  constructor: (@val) ->
    @val = unquote @val
    super Token.Tag.literal
  contents: -> super().concat([@val])
[LParen, RParen, Comma] = (new Token(tag) for tag in [
  Token.Tag.lparen, Token.Tag.rparen, Token.Tag.comma])

tokenizers = [
  [/^\(/, () -> LParen],
  [/^\)/, () -> RParen],
  [/^,/, () -> Comma],
  [/^[+-]?(0x[0-9a-fA-F]+|0?\.\d+|[1-9]\d*(\.\d+)?|0)([eE][+-]?\d+)?/,
   (val) -> new Literal(val)],
  [/^(\w|[^\u0000-\u0080])+|'((\\.)|[^\\'])+'|"((\\.)|[^\\"])+"/,
   (name) -> new Symbol(name)],
]
matchToken = (str) ->
  for [pat, op] in tokenizers
    match = pat.exec(str)
    if match
      substr = match[0]
      return [str[substr.length..], op substr]
  throw poly.error.defn("There is an error in your specification at #{str}")
tokenize = (str) ->
  loop
    str = str.replace(/^\s+/, '')
    if not str then break
    [str, tok] = matchToken str
    tok

class Expr
  toString: -> showCall(@constructor.name, @contents())
class Ident extends Expr
  constructor: (@name) ->
  contents: -> [@name]
  pretty: -> @name
  visit: (visitor) -> visitor.ident(@, @name)
class Const extends Expr
  constructor: (@val) ->
  contents: -> [@val]
  pretty: -> @val
  visit: (visitor) -> visitor.const(@, @val)
class Call extends Expr
  constructor: (@fname, @args) ->
  contents: -> [@fname, showList(@args)]
  pretty: -> showCall(@fname, arg.pretty() for arg in @args)
  visit: (visitor) ->
    visitor.call(@, @fname, arg.visit(visitor) for arg in @args)

expect = (stream, fail, alts) ->
  token = stream.peek()
  if token isnt null
    for [tag, express] in alts
      if token.tag is tag
        return express(stream)
  fail stream
parseFail = (stream) ->
  throw poly.error.defn("There is an error in your specification at #{stream.toString()}")
parse = (str) ->
  stream = new Stream (tokenize str)
  expr = parseExpr(stream)
  if stream.peek() isnt null
    throw poly.error.defn("There is an error in your specification at #{stream.toString()}")
  expr
parseExpr = (stream) ->
  expect(stream, parseFail,
    [[Token.Tag.literal, parseConst],
     [Token.Tag.symbol, parseSymbolic]])
parseConst = (stream) -> new Const (stream.get().val)
parseSymbolic = (stream) ->
  name = stream.get().name
  expect(stream, (() -> new Ident name),
    [[Token.Tag.lparen, parseCall name]])
parseCall = (name) -> (stream) ->
  stream.get() # lparen
  args = expect(stream, (parseCallArgs []),
    [[Token.Tag.rparen, (ts) -> ts.get(); []]])
  new Call(name, args)
parseCallArgs = (acc) -> (stream) ->
  arg = parseExpr stream
  args = acc.concat [arg]
  expect(stream, parseFail,
    [[Token.Tag.rparen, (ts) -> ts.get(); args],
     [Token.Tag.comma, (ts) -> ts.get(); (parseCallArgs args) ts]])

###############################################################################
# layerSpec -> dataSpec
###############################################################################
extractOps = (expr) ->
  results = { trans: [], stat: [] }
  extractor = {
    ident: (expr, name) -> name,
    const: (expr, val) -> val,
    call: (expr, fname, args) ->
      optype =
        if fname of poly.const.trans
          'trans'
        else if fname of poly.const.stat
          'stat'
        else
          'none'
      if optype isnt 'none'
        opargs = poly.const[optype][fname]
        result = assocsToObj zip(opargs, args)
        result.name = expr.pretty()
        result[optype] = fname
        results[optype].push result
        result.name
      else
        throw poly.error.defn("The operation #{fname} is not recognized. Please check your specifications.")
  }
  expr.visit(extractor)
  results

layerToDataSpec = (lspec, grouping) ->
  filters = {}
  for key, val of lspec.filter ? {}
    filters[(parse key).pretty()] = val # normalize name
  grouping = ((parse key).pretty() for key in grouping) # normalize name
  aesthetics = _.pick lspec, poly.const.aes
  for key of aesthetics
    if 'var' not of aesthetics[key]
      delete aesthetics[key]
  transstat = []; select = []; groups = []; metas = {}
  for key, desc of aesthetics
    expr = parse desc.var
    desc.var = expr.pretty() # normalize name
    ts = extractOps expr
    transstat.push ts
    select.push desc.var
    if ts.stat.length is 0
      groups.push desc.var
    if 'sort' of desc
      sdesc = dictGets(desc, poly.const.metas)
      sexpr = parse sdesc.sort
      sdesc.sort = sexpr.pretty() # normalize name
      result = extractOps sexpr
      if result.stat.length isnt 0
        sdesc.stat = result.stat
      metas[desc.var] = sdesc
  for grpvar in grouping
    expr = parse grpvar
    grpvar = expr.pretty() # normalize name
    ts = extractOps expr
    transstat.push ts
    select.push grpvar
    if ts.stat.length is 0
      groups.push grpvar
    else
      throw poly.error.defn "Facet variable should not contain statistics!"

  transstats = mergeObjLists transstat
  dedupByName = dedupOnKey 'name'
  stats = {stats: dedupByName(transstats.stat), groups: (dedup groups)}
  {
    trans: dedupByName(transstats.trans), stats: stats, meta: metas,
    select: (dedup select), filter: filters
  }

poly.parser =
  tokenize: tokenize
  parse: parse
  layerToData: layerToDataSpec
