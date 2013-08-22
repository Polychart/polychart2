module "Interpreter"

evaluate = (e, data) ->
  e = polyjs.debug.parser.getExpression(e).expr.expr
  f = polyjs.debug.interpret.createFunction(e)
  (f(row) for row in data)

test "identifier", ->
  data = [
    {a:2, b:3, "some long word": 4, "a!sd,\"]": 5}
    {a:1, b:3, "some long word": 4, "a!sd,\"]": 5}
  ]
  deepEqual evaluate("[a]", data), [2, 1], 'identifier'
  deepEqual evaluate("a", data), [2, 1], 'identifier'
  deepEqual evaluate("'a'", data), ['a', 'a'], 'string const'
  deepEqual evaluate("1", data), [1, 1], 'numeric const'
  deepEqual evaluate("1 + 2", data), [3, 3], 'const + const'
  deepEqual evaluate("a + 2", data), [4, 3], 'ident + const'
  deepEqual evaluate("[a] + 2", data), [4, 3], 'ident + const'
  deepEqual evaluate("[a] + [some long word]", data), [6, 5], 'ident + ident'
  debugger
  deepEqual evaluate("[a] + [a!sd,\"\\]]", data), [7, 6], 'ident + annoying ident'
  deepEqual evaluate("[a] * [a!sd,\"\\]]", data), [10, 5], 'ident * annoying ident'

  deepEqual evaluate("3 + [a] * [a!sd,\"\\]]", data), [13, 8], 'nesting annoying ident'

  deepEqual evaluate("log([a])", data), [Math.log(2), 0], 'identifier'
  deepEqual evaluate("log([a] + 2)", data), [Math.log(4), Math.log(3)], 'identifier'
  deepEqual evaluate("log([a!sd,\"\\]] + 2)", data), [Math.log(7), Math.log(7)], 'identifier'
