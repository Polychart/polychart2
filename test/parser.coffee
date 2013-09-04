module "Parsers"
test "type checking", ->
  equal polyjs.debug.parser.tc('4 + 5').toString(), 'num'
  equal polyjs.debug.parser.tc('6 * 3 + 5.3 / 4 - 90').toString(), 'num'
  equal polyjs.debug.parser.tc('8 + if 6 * 3 > 5 then 2 + 5.3 / 4 - 90 else 2 + 7').toString(), 'num'
  equal polyjs.debug.parser.tc('8 + (if 6 * 3 > 5 then 2 + 5.3 / 4 - 90 else 2 + 7) / 2').toString(), 'num'
  equal polyjs.debug.parser.tc('"something"').toString(), 'cat'
  equal polyjs.debug.parser.tc('\'some\' ++ " thing"').toString(), 'cat'
  equal polyjs.debug.parser.tc('"some" ++ if 6 * 3 > 5 then " thing" else " stuff"').toString(), 'cat'
  equal polyjs.debug.parser.tc('log(x)').toString(), 'num'
  equal polyjs.debug.parser.tc('sum(x)').toString(), 'stat'
  equal polyjs.debug.parser.tc('sum(log(x))').toString(), 'stat'
  equal polyjs.debug.parser.tc('nameCollision(nameCollision)').toString(), 'num'
  try
    polyjs.debug.parser.tc('sum(sum(x))')
    ok false, 'sum(sum(x))'
  catch e
    equal e.message, 'Type mismatch: (stat vs. num) in (([stat] -> ?) vs. ([num] -> stat))'
  try
    polyjs.debug.parser.tc('suum(x)')
    ok false, 'suum(x)'
  catch e
    equal e.message, 'Unknown function name: suum'
  try
    polyjs.debug.parser.tc('sum(y)')
    ok false, 'sum(y)'
  catch e
    equal e.message, 'Unknown column name: y'

test "jsonification", ->
  equal JSON.stringify(polyjs.debug.parser.tj('1 + 2')), '["infixop",{"opname":"+","lhs":["const",{"value":"1","type":"num"}],"rhs":["const",{"value":"2","type":"num"}]}]'
  equal JSON.stringify(polyjs.debug.parser.tj('mean(log(mycol * 10) - 1)')), '["call",{"fname":"mean","args":[["infixop",{"opname":"-","lhs":["call",{"fname":"log","args":[["infixop",{"opname":"*","lhs":["ident",{"name":"mycol"}],"rhs":["const",{"value":"10","type":"num"}]}]]}],"rhs":["const",{"value":"1","type":"num"}]}]]}]'
  equal JSON.stringify(polyjs.debug.parser.tj('"some" ++ if 6 * 3 > 5 then " thing" else " stuff"')), '["infixop",{"opname":"++","lhs":["const",{"value":"some","type":"cat"}],"rhs":["conditional",{"cond":["infixop",{"opname":">","lhs":["infixop",{"opname":"*","lhs":["const",{"value":"6","type":"num"}],"rhs":["const",{"value":"3","type":"num"}]}],"rhs":["const",{"value":"5","type":"num"}]}],"conseq":["const",{"value":" thing","type":"cat"}],"altern":["const",{"value":" stuff","type":"cat"}]}]}]'
  equal JSON.stringify(polyjs.debug.parser.tj('sum(a)')), '["call",{"fname":"sum","args":[["ident",{"name":"a"}]]}]'

test "parsing & tokenization", ->
  equal polyjs.debug.parser.tokenize('A').toString(), '<symbol,A>'
  equal polyjs.debug.parser.parse('A').toString(), 'Ident(A)'

  equal polyjs.debug.parser.tokenize('  A').toString(), '<symbol,A>'
  equal polyjs.debug.parser.parse('  A').toString(), 'Ident(A)'

  equal polyjs.debug.parser.tokenize('3.3445').toString(), '<literal,3.3445>'
  equal polyjs.debug.parser.parse('3.3445').toString(), 'Const(3.3445)'

  equal polyjs.debug.parser.tokenize('"something \\"quoted\\""').toString(), '<literal,something "quoted">'
  equal polyjs.debug.parser.tokenize('"something \\"quoted>\\""').toString(), '<literal,something "quoted>">'
  equal polyjs.debug.parser.parse('"something \\"quoted\\""').toString(), 'Const(something "quoted")'
  equal polyjs.debug.parser.parse('"something \\"quoted\\""').pretty(), '"something \\"quoted\\""'
  equal polyjs.debug.parser.parse('"something \\"quoted>\\""').toString(), 'Const(something "quoted>")'
  equal polyjs.debug.parser.parse('"something \\"quoted>\\""').pretty(), '"something \\"quoted>\\""'
  equal polyjs.debug.parser.parse('[+-*/%abcdefg()\\]\\[._><]').pretty(), '[+-*/%abcdefg()\\]\\[._><]'
  equal polyjs.debug.parser.parse('A').pretty(), '[A]'
  equal polyjs.debug.parser.parse('sum(A)').pretty(), 'sum([A])'

  equal polyjs.debug.parser.tokenize('mean(A )').toString(), '<symbol,mean>,<(>,<symbol,A>,<)>'
  equal polyjs.debug.parser.parse('mean(A )').toString(), 'Call(mean,[Ident(A)])'

  equal polyjs.debug.parser.tokenize(' mean(A )').toString(), '<symbol,mean>,<(>,<symbol,A>,<)>'
  equal polyjs.debug.parser.parse('mean(A )').toString(), 'Call(mean,[Ident(A)])'

  equal polyjs.debug.parser.tokenize('mean( A )  ').toString(), '<symbol,mean>,<(>,<symbol,A>,<)>'
  equal polyjs.debug.parser.parse('mean( A )  ').toString(), 'Call(mean,[Ident(A)])'

  equal polyjs.debug.parser.tokenize('log(mean(sum(A_0), 10), 2.7188, CCC)').toString(), '<symbol,log>,<(>,<symbol,mean>,<(>,<symbol,sum>,<(>,<symbol,A_0>,<)>,<,>,<literal,10>,<)>,<,>,<literal,2.7188>,<,>,<symbol,CCC>,<)>'
  equal polyjs.debug.parser.parse('log(mean(sum(A_0), 10), 2.7188, CCC)').toString(), 'Call(log,[Call(mean,[Call(sum,[Ident(A_0)]),Const(10)]),Const(2.7188),Ident(CCC)])'

  equal polyjs.debug.parser.parse('[this is one identifier]').toString(), 'Ident(this is one identifier)'
  equal polyjs.debug.parser.parse('[this is \\[also\\] one identifier]').toString(), 'Ident(this is [also] one identifier)'

  equal polyjs.debug.parser.tokenize('if true then [then] else [else]').toString(), '<keyword,if>,<symbol,true>,<keyword,then>,<symbol,then>,<keyword,else>,<symbol,else>'
  equal polyjs.debug.parser.parse('if 1 then 2 else 3').pretty(), '(if 1 then 2 else 3)'
  equal polyjs.debug.parser.parse('7 * if 1 >= 2 then 3 + four else 5 + 6').pretty(), '(7 * (if (1 >= 2) then (3 + [four]) else (5 + 6)))'

  equal polyjs.debug.parser.tokenize('(3 + four * 5 - 6 / 7 % 8) ++ nine').toString(), '<(>,<literal,3>,<infixsymbol,+>,<symbol,four>,<infixsymbol,*>,<literal,5>,<infixsymbol,->,<literal,6>,<infixsymbol,/>,<literal,7>,<infixsymbol,%>,<literal,8>,<)>,<infixsymbol,++>,<symbol,nine>'
  equal polyjs.debug.parser.parse('3 + four * 5 - six').pretty(), '((3 + ([four] * 5)) - [six])'
  equal polyjs.debug.parser.parse('3 - four * 5 + six').pretty(), '(3 - (([four] * 5) + [six]))'
  equal polyjs.debug.parser.parse('(3 + four * 5 - 6 / 7 % 8) ++ nine').pretty(), '(((3 + ([four] * 5)) - ((6 / 7) % 8)) ++ [nine])'
  equal polyjs.debug.parser.parse('3 + four * 5 - 6 / 7 % 8 ++ nine').pretty(), '((3 + ([four] * 5)) - ((6 / 7) % (8 ++ [nine])))'

  equal polyjs.debug.parser.tokenize('this(should, break').toString(), '<symbol,this>,<(>,<symbol,should>,<,>,<symbol,break>'
  try
    polyjs.debug.parser.parse('this(should, break').toString()
    ok false, 'this(should, break'
  catch e
    equal e.message, 'There is an error in your specification at Stream([])'

  try
    polyjs.debug.parser.parse(')this(should, break').toString()
    ok false, ')this(should, break'
  catch e
    equal e.message, 'There is an error in your specification at Stream([<)>,<symbol,this>,<(>,<symbol,should>,<,>,<symbol,break>])'

  try
    polyjs.debug.parser.parse('this should break').toString()
    ok false, 'this should break'
  catch e
    equal e.message, "There is an error in your specification at Stream([<symbol,should>,<symbol,break>])"

test "idempotence", ->
  for trial in ['sum([+-*/%abcdefg\\(\\)\\]\\[._><])', 'unquoted', '[quoted]', 'sum ( shit )', 'sum([ shitte ])', 'sum([\\[])', 'mean(log(2))', '3 + four * 5 - 6 / 7 % 8 ++ nine']
    once = polyjs.debug.parser.parse(trial).pretty()
    twice = polyjs.debug.parser.parse(once).pretty()
    equal once, twice

