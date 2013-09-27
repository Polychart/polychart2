###############################################################################
# utilities
###############################################################################
escape = (str) -> str.replace(/[\[\]\\]/g, (match) -> '\\' + match)
unescape = (str) -> str.replace /\\./g, (match) -> match[1..]
bracket = (str) -> '[' + escape(str)  + ']'
unbracket = (str) ->
  n = str.length
  if str[0] is '[' and str[n-1] is ']'
    str = str[1..(n-2)]
    str = unescape(str)
  str
quote = (str) -> '"' + str.replace(/["\\]/g, (match) -> '\\' + match) + '"'
unquote = (str) ->
  n = str.length
  for qu in ['"', "'"]
    if str[0] is qu and str[n-1] is qu
      str = str[1..(n-2)]
      str = unescape(str)
      break
  str
showCall = (fname, args) -> "#{fname}(#{args})"
showList = (xs) -> "[#{xs}]"

###############################################################################
# data types
###############################################################################
class DataTypeError
  constructor: (@message) ->

class DataType
  constructor: (@name) ->
  error: (context, msg) =>
    #cmp = ("(#{t0.toString()} vs. #{t1.toString()})" for [t0, t1] in context)
    cmp = ("(#{t0} vs. #{t1})" for [t0, t1] in context)
    cmp.reverse()
    comparison = cmp.join(' in ')
    throw new DataTypeError(msg + ': ' + comparison)
  mismatch: (context) => @error(context, 'Type mismatch')
  unify: (type) => type._known_unify(@)
  _known_unify: (type) =>
    @_runify([], type)
    @
  _runify: (context, type) => @_unify(context.concat([[@toString(), type.toString()]]), type)
  _unify: (context, type) => if @name isnt type.name then @mismatch(context)
class UnknownType extends DataType
  constructor: ->
    super '?'
    @found = null
  toString: =>
    if @found is null then '?'
    else @found.toString()
  unify: (type) => @_known_unify(type)
  _unify: (context, type) =>
    if @found is null then @found = type
    else @found._unify(context, type)
class BaseType extends DataType
  toString: => "#{@name}"
class FuncType extends DataType
  constructor: (@domains, @range) -> super '->'
  toString: =>
    domains = (domain.toString() for domain in @domains).join(', ')
    "([#{domains}] -> #{@range})"
  _unify: (context, type) =>
    super(context, type)
    if @domains.length isnt type.domains.length
      @error(context, 'function domains differ in length')
    for [d0, d1] in _.zip(@domains, type.domains)
      d0._runify(context, d1)
    @range._runify(context, type.range)

DataType.Base = _.object([n, new BaseType(s)] for n, s of {
  cat: 'cat', num: 'num', date: 'date', stat: 'stat'})

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
  constructor: (@val, @type) ->
    super Token.Tag.literal
    if @type is DataType.Base.cat
      @val = unquote @val
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
   (val) -> new Literal(val, DataType.Base.num)],
  [/^(([\w|\.]|[^\u0000-\u0080])+|\[((\\.)|[^\\\[\]])+\])/, symbolOrKeyword],
  [/^('((\\.)|[^\\'])*'|"((\\.)|[^\\"])+")/,
   (val) -> new Literal(val, DataType.Base.cat)],
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
  constructor: (@val, @vtype) ->
  contents: => [@val]
  pretty: =>
    if @vtype is DataType.Base.cat then quote @val
    else @val
  visit: (visitor) => visitor.const(@, @val, @vtype)
class Call extends Expr
  constructor: (@fname, @args) ->
  contents: => [@fname, showList(@args)]
  pretty: => showCall(@fname, arg.pretty() for arg in @args)
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
      if tok.tag is Token.Tag.literal then new Const(tok.val, tok.type)
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
# type analysis
###############################################################################
exprType = (funcTypeEnv, colTypeEnv, expr) ->
  tapply = (fname, targs) ->
    if fname not of funcTypeEnv
      throw poly.error.defn "Unknown function name: #{fname}"
    if fname is 'bin' and targs.length is 2 and targs[0] == tdate
      fname = 'bin_date'
    if fname in ['min', 'max'] and targs.length is 1 and targs[0] == tdate
      fname = fname+'_date'
    if fname in ['count', 'unique', 'lag'] and targs.length is 1
      if targs[0] == tcat
        fname = fname+'_cat'
      else if targs[0] == tdate
        fname = fname+'_date'
    if fname is 'parseDate' and targs.length is 1
      fname = 'parseDateDefault'
    tfunc = funcTypeEnv[fname]
    tresult = new UnknownType
    tfunc.unify(new FuncType(targs, tresult))
    tresult.found
  visitor = {
    ident: (expr, name) ->
      if name of colTypeEnv then colTypeEnv[name]
      else throw poly.error.defn "Unknown column name: #{name}"
    const: (expr, val, type) -> type,
    call: (expr, fname, targs) -> tapply(fname, targs)
    infixop: (expr, opname, tlhs, trhs) -> tapply(opname, [tlhs, trhs])
    conditional: (expr, tcond, tconseq, taltern) ->
      tcond.unify DataType.Base.num
      tconseq.unify taltern
      tconseq
  }
  expr.visit(visitor)

tcat = DataType.Base.cat
tnum = DataType.Base.num
tdate = DataType.Base.date
pairNumToNum = new FuncType([tnum, tnum], tnum)

###############################################################################
# type environments
###############################################################################
# infix ops
initialFuncTypeEnv = {'++': new FuncType([tcat, tcat], tcat)}
for opname in ['*', '/', '%', '+', '-', '>=', '>', '<=', '<', '!=', '==', '=']
  initialFuncTypeEnv[opname] = pairNumToNum
# statistics
for fname in ['sum', 'mean', 'box', 'median']
  initialFuncTypeEnv[fname] = new FuncType([tnum], DataType.Base.stat)
for fname in ['min', 'max']
  initialFuncTypeEnv[fname] = new FuncType([tnum], DataType.Base.stat)
  initialFuncTypeEnv[fname+'_date'] = new FuncType([tdate], DataType.Base.stat)
for fname in ['count', 'unique']
  initialFuncTypeEnv[fname] = new FuncType([tnum], DataType.Base.stat)
  initialFuncTypeEnv[fname+'_cat'] = new FuncType([tcat], DataType.Base.stat)
  initialFuncTypeEnv[fname+'_date'] = new FuncType([tdate], DataType.Base.stat)
# transforms
for fname in ['lag']
  initialFuncTypeEnv[fname] = new FuncType([tnum, tnum], tnum)
  initialFuncTypeEnv[fname+'_cat'] = new FuncType([tcat, tnum], tcat)
  initialFuncTypeEnv[fname+'_date'] = new FuncType([tdate, tnum], tdate)
initialFuncTypeEnv.log = new FuncType([tnum], tnum)

initialFuncTypeEnv.substr = new FuncType([tcat, tnum, tnum], tnum)
initialFuncTypeEnv.length = new FuncType([tcat], tnum)
initialFuncTypeEnv.upper = new FuncType([tcat], tnum)
initialFuncTypeEnv.lower = new FuncType([tcat], tnum)
initialFuncTypeEnv.indexOf = new FuncType([tcat, tcat], tnum)
initialFuncTypeEnv.parseNum = new FuncType([tcat], tnum)
initialFuncTypeEnv.parseDate = new FuncType([tcat, tcat], tdate)
initialFuncTypeEnv.parseDateDefault = new FuncType([tcat], tdate)
initialFuncTypeEnv.year = new FuncType([tdate], tnum)
initialFuncTypeEnv.month = new FuncType([tdate], tnum)
initialFuncTypeEnv.dayOfMonth = new FuncType([tdate], tnum)
initialFuncTypeEnv.dayOfYear = new FuncType([tdate], tnum)
initialFuncTypeEnv.dayOfWeek = new FuncType([tdate], tnum)
initialFuncTypeEnv.hour = new FuncType([tdate], tnum)
initialFuncTypeEnv.minute = new FuncType([tdate], tnum)
initialFuncTypeEnv.second = new FuncType([tdate], tnum)
initialFuncTypeEnv['bin'] = new FuncType([tnum, tnum], tnum)
initialFuncTypeEnv['bin_date'] = new FuncType([tdate, tcat], tdate)

###############################################################################
# JSON serialization
###############################################################################
exprJSON = (expr) ->
  visitor = {
    ident: (expr, name) -> ['ident', {name: name}]
    const: (expr, val, type) -> ['const', {value: val, type: type.name}]
    call: (expr, fname, args) -> ['call', {fname: fname, args: args}]
    infixop: (expr, opname, lhs, rhs) ->
      ['infixop', {opname: opname, lhs: lhs, rhs: rhs}]
    conditional: (expr, cond, conseq, altern) ->
      ['conditional', {cond: cond, conseq: conseq, altern: altern}]
  }
  expr.visit(visitor)

###############################################################################
# layerSpec -> dataSpec
###############################################################################
extractOps = (expr) ->
  results = { trans: [], stat: [] }
  extractor = {
    ident: (expr, name) -> expr,
    const: (expr, val, type) -> expr,
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
        result = _.object(opargs, args)
        result.name = expr
        result[optype] = fname
        results[optype].push result
        result.name
      else
        throw poly.error.defn("The operation #{fname} is not recognized. Please check your specifications.")
  }
  expr.visit(extractor)
  results

# TODO: remove after testing
testTypeCheck = () ->
  b0 = DataType.Base.cat
  b1 = DataType.Base.num
  u0 = new UnknownType
  a0 = new FuncType([b0, b1, u0, b1], b1)
  a1 = new FuncType([b0, b1, b0, u0], b1)
  a0.unify a1

testFuncTypeEnv = _.clone initialFuncTypeEnv
testFuncTypeEnv.sum = new FuncType([tnum], DataType.Base.stat)
testFuncTypeEnv.log = new FuncType([tnum], tnum)
testFuncTypeEnv.nameCollision = new FuncType([tcat], tnum)
testColTypeEnv = { x: tnum, nameCollision: tcat }

# TODO: remove after testing
typeCheck = (str) ->
  expr = parse str
  exprType(testFuncTypeEnv, testColTypeEnv, expr)

testExprJSON = (str) ->
  expr = parse str
  exprJSON expr

createColTypeEnv = (metas) ->
  colTypeEnv = {}
  for key, meta of metas
    colTypeEnv[key] = DataType.Base[meta.type]
  colTypeEnv

getType = (str, typeEnv, combineStat=true) ->
  type = exprType(initialFuncTypeEnv, typeEnv, parse(str))
  if combineStat and type.name is 'stat'
    'num' # all statistics end up as numbers; sometimes we treat it as such
  else
    type.name # other times they are different
    
getExpression = (str) ->
  if str is 'count(*)' then str = 'count(1)'
  expr = parse str # main expression
  exprObj = (e) -> {name: e.pretty(), expr: exprJSON(e)} # helper functions
  statInfo = ->

  obj = exprObj(expr)
  [rootType, etc] = obj.expr
  type =
    if rootType == "ident"
      'ident' #just an identifier, nothing fancy
    else if _.has(expr, 'fname') and expr.fname in ['sum', 'count', 'unique', 'mean', 'box', 'median', 'min', 'max'] # hack
      statInfo = () -> {fname: expr.fname, args: exprObj(a) for a in expr.args}
      'stat' #statistics
    else
      'trans' #transformation required
  {exprType:type, expr:obj, statInfo}

makeTypeEnv = (meta) ->

getName = (str) ->
  expr = parse str
  if 'name' of expr # shorthand for this being an identifier
    expr.name
  else
    str

poly.parser = {
  tj: testExprJSON  # TODO: remove after testing
  tc: typeCheck  # TODO: remove after testing
  ttc: testTypeCheck  # TODO: remove after testing
  createColTypeEnv
  getExpression
  getType
  tokenize
  parse
  bracket
  unbracket: getName
  escape
  unescape
}
