###############################################################################
# utilities
###############################################################################
bracket = (str) -> '[' + str.replace(/[\[\]]/g, (match) -> '\\' + match) + ']'
unbracket = (str) ->
  n = str.length
  if str[0] is '[' and str[n-1] is ']'
    str = str[1..(n-2)]
  return str.replace /\\./g, (match) -> match[1..]
zipWith = (op) -> (xs, ys) ->
  if xs.length isnt ys.length
    throw poly.error.defn("zipWith: lists have different length: [#{xs}], [#{ys}]")
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
dedup = (vals=[], trans = (x) -> x) ->
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
  empty: => @buffer.length is 0
  peek: => if @empty() then null else @buffer[@buffer.length - 1]
  get: => if @empty() then null else @buffer.pop()
  toString: => showCall('Stream', showList([@buffer...].reverse()))

class Token
  @Tag = {
    symbol: 'symbol', literal: 'literal', infixsymbol: 'infixsymbol',
    keyword: 'keyword', lparen: '(', rparen: ')', comma: ','}
  constructor: (@tag) ->
  toString: => "<#{@contents().toString()}>"
  contents: => [@tag]
class Symbol extends Token
  constructor: (@name) ->
    @name = unbracket @name
    super Token.Tag.symbol
  contents: => super().concat([@name])
class Literal extends Token
  constructor: (@val) -> super Token.Tag.literal
  contents: => super().concat([@val])
class InfixSymbol extends Token
  constructor: (@op) -> super Token.Tag.infixsymbol
  contents: => super().concat([@op])
class Keyword extends Token
  constructor: (@name) -> super Token.Tag.keyword
  contents: => super().concat([@name])
[LParen, RParen, Comma] = (new Token(tag) for tag in [
  Token.Tag.lparen, Token.Tag.rparen, Token.Tag.comma])

# ordered from highest to lowest precedence for both tokenizing and grouping
infixops = ['++', '*', '/', '%', '+', '-', '>=', '>', '<=', '<', '!=', '==']
infixGTEQ = (lop, rop) -> infixops.indexOf(lop) <= infixops.indexOf(rop)
infixpats = ((str.replace /[+*]/g, (m) -> '(\\' + m + ')') for str in infixops)
infixpat = new RegExp('^(' + infixpats.join('|') + ')')
keywords = ['if', 'then', 'else']
symbolOrKeyword = (name) ->
  if name in keywords
    return new Keyword(name)
  new Symbol(name)
tokenizers = [
  [/^\(/, () -> LParen],
  [/^\)/, () -> RParen],
  [/^,/, () -> Comma],
  [/^[+-]?(0x[0-9a-fA-F]+|0?\.\d+|[1-9]\d*(\.\d+)?|0)([eE][+-]?\d+)?/,
   (val) -> new Literal(val)],
  [/^(\w|[^\u0000-\u0080])+|\[((\\.)|[^\\\[\]])+\]/, symbolOrKeyword],
  # TODO: quotes used to define category literals
  #[/^(\w|[^\u0000-\u0080])+|'((\\.)|[^\\'])+'|"((\\.)|[^\\"])+"/,
   #(name) -> new Symbol(name)],
  # placed after numeric literal pattern to avoid ambiguity with +/-
  [infixpat, (op) -> new InfixSymbol(op)],
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
  contents: => [@name]
  pretty: => bracket @name
  visit: (visitor) => visitor.ident(@, @name)
class Const extends Expr
  constructor: (@val) ->
  contents: => [@val]
  pretty: => @val
  visit: (visitor) => visitor.const(@, @val)
class Call extends Expr
  constructor: (@fname, @args) ->
  contents: => [@fname, showList(@args)]
  pretty: => showCall(bracket @fname, arg.pretty() for arg in @args)
  visit: (visitor) =>
    visitor.call(@, @fname, arg.visit(visitor) for arg in @args)
class InfixOp extends Expr
  constructor: (@opsym, @lhs, @rhs) ->
  contents: => [@lhs, @opsym, @rhs]
  pretty: => '(' + [@lhs.pretty(), @opsym, @rhs.pretty()].join(' ') + ')'
  visit: (visitor) =>
    visitor.infixop(@, @opsym, @lhs.visit(visitor), @rhs.visit(visitor))
class Conditional extends Expr
  constructor: (@condition, @consequent, @alternative) ->
  contents: => [@condition, @consequent, @alternative]
  pretty: => "(if #{@condition.pretty()} " +
    "then #{@consequent.pretty()} else #{@alternative.pretty()})"
  visit: (visitor) =>
    visitor.conditional(@, @condition.visit(visitor),
      @consequent.visit(visitor), @alternative.visit(visitor))

class OpStack
  constructor: -> @ops = []
  _reduce: (rhs, pred) =>
    while @ops.length isnt 0
      [lhs, lop] = @ops.pop()
      if pred(lop) then rhs = new InfixOp(lop, lhs, rhs)
      else
        @ops.push [lhs, lop]
        break
    rhs
  push: (rhs, op) =>
    pred = (lop) -> infixGTEQ(lop, op)
    rhs = @_reduce(rhs, pred)
    @ops.push [rhs, op]
  finish: (rhs) =>
    pred = (lop) -> true
    @_reduce(rhs, pred)

assertIs = (received, expected) ->
  if received isnt expected
    throw poly.error.defn("Expected #{expected} but received #{received}")
assertTagIs = (received, tag) -> return assertIs(received.tag, tag)
class Parser
  constructor: (@stream) -> @ops = new OpStack()
  expect: (fail, alts) =>
    token = @stream.peek()
    if token isnt null
      for [tag, express] in alts
        if token.tag in tag
          return express()
    fail()
  parseFail: =>
    throw poly.error.defn("There is an error in your specification at #{@stream.toString()}")
  parseTopExpr: =>
    expr = @parseExpr()
    if @stream.peek() isnt null then @parseFail()
    expr
  parseSubExpr: =>
    parser = new Parser(@stream)
    parser.parseExpr()
  parseExpr: =>
    expr = @expect(@parseFail,
      [[[Token.Tag.lparen], @parseParenExpr],
       [[Token.Tag.keyword], @parseKeywordExpr],
       [[Token.Tag.literal, Token.Tag.symbol], @parseAtomCall]])
    @expect(@parseFinish(expr),
      [[[Token.Tag.infixsymbol], @parseInfix expr]])
  parseKeywordExpr: =>
    kw = @stream.peek()
    assertTagIs(kw, Token.Tag.keyword)  # would be a bug
    switch kw.name
      when 'if' then @parseConditional()
      else @parseFail()
  parseKeyword: (expected) =>
    kw = @stream.get()
    assertTagIs(kw, Token.Tag.keyword)  # bug or bad user input
    assertIs(kw.name, expected)  # bug or bad user input
  parseConditional: =>
    @parseKeyword 'if'
    cond = @parseSubExpr()
    @parseKeyword 'then'
    conseq = @parseSubExpr()
    @parseKeyword 'else'
    altern = @parseSubExpr()
    new Conditional(cond, conseq, altern)
  parseParenExpr: =>
    assertIs(@stream.get(), LParen)  # would be a bug
    expr = @parseSubExpr()
    assertIs(@stream.get(), RParen)  # bad user input
    expr
  parseAtomCall: =>
    tok = @stream.get()
    atom =
      if tok.tag is Token.Tag.literal then new Const(tok.val)
      else if tok.tag is Token.Tag.symbol then new Ident(tok.name)
      else assertIs(false, true)  # would be a bug
    @expect((() -> atom),
      [[[Token.Tag.lparen], @parseCall tok]])
  parseCall: (tok) => (stream) =>
    assertTagIs(tok, Token.Tag.symbol)  # bad user input
    assertIs(@stream.get(), LParen)  # would be a bug
    name = tok.name
    args = @expect((@parseCallArgs []),
      [[[Token.Tag.rparen], (() => @stream.get(); [])]])
    new Call(name, args)
  parseCallArgs: (acc) => () =>
    arg = @parseSubExpr()
    args = acc.concat [arg]
    @expect(@parseFail,
      [[[Token.Tag.rparen], (() => @stream.get(); args)],
       [[Token.Tag.comma], (() => @stream.get(); @parseCallArgs(args)())]])
  parseInfix: (rhs) => () =>
    optok = @stream.get()
    assertTagIs(optok, Token.Tag.infixsymbol)  # would be a bug
    op = optok.op
    @ops.push(rhs, op)
    @parseExpr()
  parseFinish: (expr) => () =>
    @ops.finish expr

parse = (str) ->
  stream = new Stream(tokenize str)
  parser = new Parser(stream)
  parser.parseTopExpr()

###############################################################################
# layerSpec -> dataSpec
###############################################################################
extractOps = (expr) ->
  results = { trans: [], stat: [] }
  extractor = {
    ident: (expr, name) -> expr,
    const: (expr, val) -> expr,
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
        result.name = expr
        result[optype] = fname
        results[optype].push result
        result.name
      else
        throw poly.error.defn("The operation #{fname} is not recognized. Please check your specifications.")
  }
  expr.visit(extractor)
  results

layerToDataSpec = (lspec, grouping=[]) ->
  filters = {}
  for key, val of lspec.filter ? {}
    filters[parse key] = val
  aesthetics = _.pick lspec, poly.const.aes
  for key of aesthetics
    if 'var' not of aesthetics[key]
      delete aesthetics[key]
  transstat = []; select = []; groups = []; metas = {}
  for key, desc of aesthetics
    if desc.var is 'count(*)'
      select.push desc.var
    else
      desc.var = parse desc.var
      ts = extractOps desc.var
      transstat.push ts
      select.push desc.var
      if ts.stat.length is 0
        groups.push desc.var
      if 'sort' of desc
        sdesc = dictGets(desc, poly.const.metas)
        if sdesc.sort is 'count(*)'
          result = {sort: 'count(*)', asc: sdesc.asc, stat: [], trans: []}
        else
          sdesc.sort = parse sdesc.sort
          result = extractOps sdesc.sort
        if result.stat.length isnt 0
          sdesc.stat = result.stat[0]
        metas[desc.var] = sdesc
  for grpvar in grouping
    grpvar = parse grpvar
    ts = extractOps grpvar
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
    trans: dedupByName(transstats.trans), stats: stats, sort: metas,
    select: (dedup select), filter: filters
  }

pivotToDataSpec = (lspec) ->
  filters = {}
  for key, val of lspec.filter ? {}
    filters[parse key] = val

  aesthetics = _.pick lspec, ['columns', 'rows', 'values']
  aesthetics_list = []

  for key, list of aesthetics
    for item in list
      if 'var' of item
        aesthetics_list.push(item)

  transstat = []; select = []; groups = []; metas = {}
  for desc in aesthetics_list
    if desc.var is 'count(*)'
      select.push desc.var
    else
      desc.var = parse desc.var
      ts = extractOps desc.var
      transstat.push ts
      select.push desc.var
      if ts.stat.length is 0
        groups.push desc.var
      if 'sort' of desc
        sdesc = dictGets(desc, poly.const.metas)
        if sdesc.sort is 'count(*)'
          result = {sort: 'count(*)', asc: sdesc.asc, stat: [], trans: []}
        else
          sdesc.sort = parse sdesc.sort
          result = extractOps sdesc.sort
        if result.stat.length isnt 0
          sdesc.stat = result.stat[0]
        metas[desc.var] = sdesc
  transstats = mergeObjLists transstat
  dedupByName = dedupOnKey 'name'
  stats = {stats: dedupByName(transstats.stat), groups: (dedup groups)}
  {
    trans: dedupByName(transstats.trans), stats: stats, sort: metas,
    select: (dedup select), filter: filters
  }

numeralToDataSpec = (lspec) ->
  filters = {}
  for key, val of lspec.filter ? {}
    filters[parse key] = val # normalize name
  aesthetics = _.pick lspec, ['value']
  for key of aesthetics
    if 'var' not of aesthetics[key]
      delete aesthetics[key]
  transstat = []; select = []; groups = []; metas = {}
  for key, desc of aesthetics
    if desc.var is 'count(*)'
      select.push desc.var
    else
      desc.var = parse desc.var
      ts = extractOps desc.var
      transstat.push ts
      select.push desc.var
      if ts.stat.length is 0
        groups.push desc.var
      if 'sort' of desc
        sdesc = dictGets(desc, poly.const.metas)
        sdesc.sort = parse sdesc.sort
        result = extractOps sdesc.sort
        if result.stat.length isnt 0
          sdesc.stat = result.stat[0]
        metas[desc.var] = sdesc
  transstats = mergeObjLists transstat
  dedupByName = dedupOnKey 'name'
  stats = {stats: dedupByName(transstats.stat ? []), groups: (dedup groups)}
  {
    trans: dedupByName(transstats.trans ? []), stats: stats, sort: metas,
    select: (dedup select), filter: filters
  }


poly.parser =
  tokenize: tokenize
  parse: parse
  layerToData: layerToDataSpec
  pivotToData: pivotToDataSpec
  numeralToData: numeralToDataSpec
