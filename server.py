import tornado.ioloop
import tornado.web
#import tornado.database
import sqlite3
import json
from backend.sql import process_fn
from tornado.escape import json_encode

def _execute(query, params):
  dbPath = 'data/db'
  connection = sqlite3.connect(dbPath)
  cursorobj = connection.cursor()
  try:
    cursorobj.execute(query, params)
    result = cursorobj.fetchall()
    connection.commit()
  except Exception:
    raise
  connection.close()
  return result

dataprocess = process_fn(_execute)

class AJAX(tornado.web.RequestHandler):
  def get(self):
    # NOTE:
    #   DO NOT USE THIS CODE IN PRODUCTION OR ANYWHERE CLOSE TO PRODUCTION
    TABLE = self.get_argument("table", None)
    LIMIT = self.get_argument("limit", "1000")
    spec = self.get_argument("spec", None)
    spec = json.loads(spec)

    retobj = dataprocess(TABLE, LIMIT, spec)
    self.write(json_encode(retobj))

application = tornado.web.Application([
  (r"/db",AJAX),
  (r"/(.*)",tornado.web.StaticFileHandler, {'path':'.'}),
],debug=True)
 
if __name__ == "__main__":
  application.listen(8888)
  tornado.ioloop.IOLoop.instance().start()
