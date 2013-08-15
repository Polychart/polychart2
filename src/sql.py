import json

def escape(str): return str # TODO: implement
def quote(str): return '"'+escape(str)+'"'

class ExprToSql(object): # more like Expr to MySQL
  def toSql(self, params):
    type, payload = params
    fn = getattr(self, type)
    return fn(payload)
  def ident(self, payload): return payload['name'] # TODO: check for SQL Injection
  def const(self, payload):
    if payload['type'] == 'num':
      return payload['value']
    else:
      return quote(payload['value'])
  def infixop(self, payload):
    lhsSql = self.toSql(payload['lhs'])
    rhsSql = self.toSql(payload['rhs'])
    if payload['opname'] in ["+", "-", "*", "/", "%", ">", "<"]:
      return lhsSql + payload['opname'] + rhsSql
    if payload['opname'] == "++":
      return "CONCAT(%s, %s)" % (lhsSql, rhsSql)
    raise Exception("Unknown operation %s" % payload["opname"])
  def conditional(self, payload):
    condSql = self.toSql(payload['cond'])
    conseqSql = self.toSql(payload['conseq'])
    alternSql = self.toSql(payload['altern'])
    return "IF(%s, %s, %s)" % (condSql, conseqSql, alternSql)
  def call(self, payload):
    fn = getattr(self, "fn_%s"%payload['fname'])
    argsSql = [self.toSql(arg) for arg in payload['args']]
    return fn(argsSql)
  def fn_log(self, argsSql):
    if len(argsSql) != 1: raise Exception
    return "LOG(%s)" % argsSql[0]
  def fn_mean(self, argsSql):
    if len(argsSql) != 1: raise Exception
    return "AVG(%s)" % argsSql[0]

sqlizer = ExprToSql()
def sqlize(str):
  return sqlizer.toSql(json.loads(str))


print sqlize('["infixop",{"opname":"+","lhs":["const",{"value":"1","type":"num"}],"rhs":["const",{"value":"2","type":"num"}]}]')
print sqlize('["call",{"fname":"mean","args":[["infixop",{"opname":"-","lhs":["call",{"fname":"log","args":[["infixop",{"opname":"*","lhs":["ident",{"name":"mycol"}],"rhs":["const",{"value":"10","type":"num"}]}]]}],"rhs":["const",{"value":"1","type":"num"}]}]]}]')
print sqlize('["infixop",{"opname":"++","lhs":["const",{"value":"some","type":"cat"}],"rhs":["conditional",{"cond":["infixop",{"opname":">","lhs":["infixop",{"opname":"*","lhs":["const",{"value":"6","type":"num"}],"rhs":["const",{"value":"3","type":"num"}]}],"rhs":["const",{"value":"5","type":"num"}]}],"conseq":["const",{"value":" thing","type":"cat"}],"altern":["const",{"value":" stuff","type":"cat"}]}]}]')
