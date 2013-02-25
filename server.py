import tornado.ioloop
import tornado.web
import tornado.database
import sqlite3
import json
from tornado.escape import json_encode

def _execute(query):
  dbPath = 'data/db'
  connection = sqlite3.connect(dbPath)
  cursorobj = connection.cursor()
  try:
    cursorobj.execute(query)
    result = cursorobj.fetchall()
    connection.commit()
  except Exception:
    raise
  connection.close()
  return result
 
class AJAX(tornado.web.RequestHandler):
  def get(self):
    # NOTE:
    #  DO NOT USE THIS CODE IN PRODUCTION OR ANYWHERE CLOSE TO PRODUCTION
    TABLE = self.get_argument("table", None)
    LIMIT = self.get_argument("limit", "1000")
    spec = self.get_argument("spec", None)
    spec = json.loads(spec)

    SELECT = ''
    GROUP = ''
    WHERE = ''
    def _add(v):
      if WHERE:
        WHERE += " and "+v
      else:
        WHERE = " where "+v

    SELECT = ', '.join(spec['select'])
    if len(spec['stats']) > 0:
      GROUP = ' group by ' + ', '.join(spec['stats']['groups'])
    for key in spec['filter']:
      v = spec['filter']['key']
      for quantifier in v:
        if quantifier is 'ge':
          _add(key + " >= " + v[quantifier])
        elif quantifier is "gt":
          _add(key + " > " + v[quantifier])
        elif quantifier is "lt":
          _add(key + " < " + v[quantifier])
        elif quantifier is "le":
          _add(key + " <= " + v[quantifier])
        elif quantifier is "in":
          _add(key + " in " + (', ').join(v[quantifier]))
      WHERE = ''

    #if 'meta' in spec
    #  pass

    query = "select %s from %s %s %s limit %s" % (SELECT, TABLE, WHERE, GROUP, LIMIT)
    rows = _execute(query)
    retobj = {
      'data' : rows,
      'meta' : spec['select']
    }
    self.write(json_encode(retobj))

application = tornado.web.Application([
  (r"/db",AJAX),
  (r"/(.*)",tornado.web.StaticFileHandler, {'path':'.'}),
],debug=True)
 
if __name__ == "__main__":
  application.listen(8888)
  tornado.ioloop.IOLoop.instance().start()
