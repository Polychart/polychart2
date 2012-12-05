###############################################################################
# utilities
###############################################################################
zipWith = (op) -> (xs, ys) ->
  if xs.length isnt ys.length
    throw Error("zipWith: lists have different length: [#{xs}], [#{ys}]")
  op(xval, ys[ix]) for xval, ix in xs
zip = zipWith (xval, yval) -> [xval, yval]
assocsToObj = (assocs) ->
  obj = {}
  for [key, val] in assocs
    obj[key] = val
  obj
dictGet = (dict, key, defval = null) -> (key of dict and dict[key]) or defval
dictGets = (dict, keyVals) ->
  final = {}
  for key, defval of keyVals
    val = dictGet(dict, key, defval)
    if val isnt null
      final[key] = val
  final
mergeObjLists = (dicts) ->
  final = {}
  for dict in dicts
    for key of dict
      final[key] = dict[key].concat(dictGet(final, key, []))
  final
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
  constructor: (@name) -> super Token.Tag.symbol
  contents: -> super().concat([@name])
class Literal extends Token
  constructor: (@val) -> super Token.Tag.literal
  contents: -> super().concat([@val])
[LParen, RParen, Comma] = (new Token(tag) for tag in [
  Token.Tag.lparen, Token.Tag.rparen, Token.Tag.comma])

tokenizers = [
  [/^\(/, (_) -> LParen],
  [/^\)/, (_) -> RParen],
  [/^,/, (_) -> Comma],
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
  throw new Error("cannot tokenize: #{str}")
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
parseFail = (stream) -> throw Error("unable to parse: #{stream.toString()}")
parse = (str) ->
  stream = new Stream (tokenize str)
  expr = parseExpr(stream)
  if stream.peek() isnt null
    throw Error("expected end of stream, but found: #{stream.toString()}")
  expr
parseExpr = (stream) ->
  expect(stream, parseFail,
    [[Token.Tag.literal, parseConst],
     [Token.Tag.symbol, parseSymbolic]])
parseConst = (stream) -> new Const (stream.get().val)
parseSymbolic = (stream) ->
  name = stream.get().name
  expect(stream, ((_) -> new Ident name),
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

# testing
test = (str) ->
  try
    console.log('\n\ntesting: ' + str + '\n')
    toks = tokenize str
    console.log(toks.toString() + '\n')
    expr = parse str
    console.log(expr.toString() + '\n')
    console.log expr.pretty()
  catch error
    console.log error

test '  A'
test '3.3445 '
test ' mean(A)'
test 'log(mean(sum(A_0), 10), 2.718, CCC)  '
test 'this(should, break'
test 'so should this'
console.log '\n\n'

###############################################################################
# layerSpec -> dataSpec
###############################################################################
extractOps = (context) ->
  opdict = {}
  for [name, args...] in context.transforms
    opdict[name] = ['trans', args]
  for [name, args...] in context.statistics
    opdict[name] = ['stat', args]
  (expr) ->
    results = { trans: [], stat: [] }
    extractor = {
      ident: (expr, name) -> name,
      const: (expr, val) -> val,
      call: (expr, fname, args) ->
        if not fname of opdict
          throw Error("unknown operation: #{fname}")
        [optype, opargs] = opdict[fname]
        result = assocsToObj zip(opargs, args)
        result.name = expr.pretty()
        result[optype] = fname
        results[optype].push result
        result.name
    }
    expr.visit(extractor)
    results

layerToDataSpec = (cxt) ->
  extract = extractOps(cxt)
  (lspec) ->
    filters = {}
    for key, val of dictGet(lspec, 'filter', {})
      filters[(parse key).pretty()] = val # normalize name
    aesthetics = dictGets(lspec,
                          assocsToObj([name, null] for name in cxt.aesthetics))
    for key of aesthetics
      if 'var' not of aesthetics[key]
        delete aesthetics[key]
    transstat = []; select = []; groups = []; metas = {}
    for key, desc of aesthetics
      expr = parse desc.var
      desc.var = expr.pretty() # normalize name
      ts = extract expr
      transstat.push ts
      select.push desc.var
      if ts.stat.length is 0
        groups.push desc.var
      if 'sort' of desc
        sdesc = dictGets(desc, cxt.metas)
        sexpr = parse sdesc.sort
        sdesc.sort = sexpr.pretty() # normalize name
        result = extract sexpr
        if result.stat.length isnt 0
          sdesc.stat = result.stat
        metas[desc.var] = sdesc
    transstats = mergeObjLists transstat
    dedupByName = dedupOnKey 'name'
    stats = {stats: dedupByName(transstats.stat), groups: (dedup groups)}
    {
      trans: dedupByName(transstats.trans), stats: stats, meta: metas,
      select: (dedup select), filter: filters
    }

# testing
context = {
  aesthetics: ['x', 'y', 'color', 'opacity'],
  transforms: [['bin', 'key', 'binwidth'], ['lag', 'key', 'lag']],
  statistics: [['count', 'key'], ['sum', 'key'], ['mean', 'key']],
  metas: {sort: null, stat: null, limit: null, asc: true},
}

extract = extractOps(context)
r1 = extract(parse 'sum(c)')
r2 = extract(parse 'bin(lag(a, 1), 10)')
console.log mergeObjLists([r1, r2])

exampleLS = {
  #data: DATA_SET,
  type: "point",
  y: {var: "b", sort: "a", guide: "y2"},
  x: {var: "a"},
  color: {const: "blue"},
  opacity: {var: "sum(c)"},
  filter: {a: {gt: 0, lt: 100}},
}

exampleLS2 = {
  #data: DATA_SET,
  type: "point",
  y: {var: "b", sort: "a", guide: "y2"},
  x: {var: "lag(a, 1)"},
  color: {const: "blue"},
  opacity: {var: "sum(c)"},
  filter: {a: {gt: 0, lt: 100}},
}

exampleLS3 =
  type: "point"
  y: {var: "lag(c , -0xaF1) "}
  x: {var: "bin(a, 0.10)"}
  color: {var: "mean(lag(c,0))"}
  opacity: {var: "bin(a, 10)"}

exampleLS4 =
  type: "point"
  y: {var: "lag(',f+/\\\'c' , -1) "}
  x: {var: "bin(汉字漢字, 10.4e20)"}
  color: {var: "mean(lag(c, -1))"}
  opacity: {var: "bin(\"a-+->\\\"b\", '漢\\\'字')"}

l2d = layerToDataSpec(context)
testl2d = (ex) ->
  ds = l2d(ex)
  console.log '\n\n'
  console.log ds
  console.log ''
  console.log ds.stats

testl2d exampleLS
testl2d exampleLS2
testl2d exampleLS3
testl2d exampleLS4
