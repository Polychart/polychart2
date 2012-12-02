showCall = (fname, args) -> fname + '(' + args + ')'
showList = (xs) -> '[' + xs + ']'

class Stream
  constructor: (src) -> @buffer = (val for val in src).reverse()
  empty: () -> @buffer.length is 0
  peek: () -> if @empty() then null else @buffer[@buffer.length - 1]
  get: () -> if @empty() then null else @buffer.pop()
  put: (val) -> @buffer.push val
  toString: () -> showCall('Stream', showList([@buffer...].reverse()))

class Token
  @Tag = { symbol: 'symbol', literal: 'literal', lparen: '(', rparen: ')', comma: ',' }
  constructor: (@tag) ->
  toString: () -> '<' + @contents().toString() + '>'
  contents: () -> [@tag]
class Symbol extends Token
  constructor: (@name) -> super Token.Tag.symbol
  contents: () -> super().concat([@name])
class Literal extends Token
  constructor: (@val) -> super Token.Tag.literal
  contents: () -> super().concat([@val])
[LParen, RParen, Comma] = (new Token(tag) for tag in [
  Token.Tag.lparen, Token.Tag.rparen, Token.Tag.comma])

tokenizers = [
  [/^\(/, (_) -> LParen],
  [/^\)/, (_) -> RParen],
  [/^,/, (_) -> Comma]
  [/^\d+(\.\d+)?/, (val) -> new Literal(val)],
  [/^\w+/, (name) -> new Symbol(name)],
]

leadingSpaces = /^[ \t\n\r\v\f]*/
dropLeadingSpaces = (str) ->
  match = leadingSpaces.exec(str)[0]
  str[match.length..]

matchToken = (str) ->
  str = dropLeadingSpaces str
  for [pat, op] in tokenizers
    match = pat.exec(str)
    if match
      substr = match[0]
      return [str[substr.length..], op substr]
  throw new Error('cannot tokenize: ' + str)

tokenize = (str) ->
  tokens = []
  while str
    [str, tok] = matchToken str
    tokens.push tok
  tokens

class Expr
class Ident extends Expr
  constructor: (@name) ->
  toString: () -> showCall('Ident', [@name])
  pretty: () -> @name
class Const extends Expr
  constructor: (@val) ->
  toString: () -> showCall('Const', [@val])
  pretty: () -> @val
class Call extends Expr
  constructor: (@fname, @args) ->
  toString: () -> showCall('Call', [@fname, showList(@args)])
  pretty: () -> showCall(@fname, arg.pretty() for arg in @args)

expect = (stream, fail, alts) ->
  token = stream.peek()
  if token isnt null
    for [tag, express] in alts
      if token.tag is tag
        return express(stream)
  fail stream

parseFail = (stream) -> throw Error('unable to parse: ' + stream.toString())
parse = (str) ->
  tokens = tokenize str
  stream = new Stream tokens
  expr = parseExpr(stream)
  if stream.peek() isnt null
    throw Error('expected end of stream, but found: ' + stream.toString())
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

# exports
@parse = parse
@Expr = Expr
@Ident = Ident
@Const = Const
@Call = Call

# testing
test = (str) ->
  console.log('\n\ntesting: ' + str + '\n')
  toks = tokenize str
  console.log(toks.toString() + '\n')
  expr = parse str
  console.log(expr.toString() + '\n')
  console.log expr.pretty()

test 'A'
test '3.3445'
test 'mean(A)'
test 'log(mean(sum(A_0), 10), 2.718, CCC)'
#test 'this(should, break'
test 'so should this'
