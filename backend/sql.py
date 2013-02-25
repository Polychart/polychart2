def process_fn(execute):
  def dataprocess(table, limit=1000, spec={}):
    TABLE = table
    SELECT = ''
    GROUP = ''
    WHERE = ''
    LIMIT = limit
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
    retobj = {
      'data': execute(query),
      'meta': spec['select']
    }
    return retobj
  return dataprocess
