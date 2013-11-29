import json

def escape(str): return str # TODO: implement
def quote(str): return '"'+escape(str)+'"'

class ASTVisitor(object):
  def visit(self, ast):
    tag, fields = ast
    fn = getattr(self, '_' + tag)
    return fn(fields)
  def _mapVisit(self, fields, *names):
    return [self.visit(fields[name]) for name in names]
  def _ident(self, fields): return self.ident(fields['name'])
  def _const(self, fields): return self.const(fields['type'], fields['value'])
  def _infixop(self, fields):
    visited = self._mapVisit(fields, 'lhs', 'rhs')
    return self.infixop(fields['opname'], *visited)
  def _conditional(self, fields):
    visited = self._mapVisit(fields, 'cond', 'conseq', 'altern')
    return self.conditional(*visited)
  def _call(self, fields):
    args = [self.visit(arg) for arg in fields['args']]
    return self.call(fields['fname'], args)

class ExprToSql(ASTVisitor): # more like Expr to MySQL
  def ident(self, name): return name # TODO: check for SQL Injection
  def const(self, type, value):
    if type == 'num':
      return value
    else:
      return quote(value)
  def infixop(self, opname, lhs, rhs):
    if opname in ["+", "-", "*", "/", "%", ">", "<"]:
      return lhs + opname + rhs
    if opname == "++":
      return "CONCAT(%s, %s)" % (lhs, rhs)
    raise Exception("Unknown operation %s" % opname)
  def conditional(self, cond, conseq, altern):
    return "IF(%s, %s, %s)" % (cond, conseq, altern)
  def call(self, fname, args):
    fn = getattr(self, "fn_%s"%fname)
    return fn(args)
  def fn_log(self, argsSql):
    if len(argsSql) != 1: raise Exception
    return "LOG(%s)" % argsSql[0]
  def fn_mean(self, argsSql):
    if len(argsSql) != 1: raise Exception
    return "AVG(%s)" % argsSql[0]

sqlizer = ExprToSql()
def sqlize(str):
  return sqlizer.visit(json.loads(str))

print sqlize('["infixop",{"opname":"+","lhs":["const",{"value":"1","type":"num"}],"rhs":["const",{"value":"2","type":"num"}]}]')
print sqlize('["call",{"fname":"mean","args":[["infixop",{"opname":"-","lhs":["call",{"fname":"log","args":[["infixop",{"opname":"*","lhs":["ident",{"name":"mycol"}],"rhs":["const",{"value":"10","type":"num"}]}]]}],"rhs":["const",{"value":"1","type":"num"}]}]]}]')
print sqlize('["infixop",{"opname":"++","lhs":["const",{"value":"some","type":"cat"}],"rhs":["conditional",{"cond":["infixop",{"opname":">","lhs":["infixop",{"opname":"*","lhs":["const",{"value":"6","type":"num"}],"rhs":["const",{"value":"3","type":"num"}]}],"rhs":["const",{"value":"5","type":"num"}]}],"conseq":["const",{"value":" thing","type":"cat"}],"altern":["const",{"value":" stuff","type":"cat"}]}]}]')
