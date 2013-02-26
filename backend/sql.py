class QueryBuilder:
  def __init__(self):
    self.reset()

  def reset(self):
    self.select = ''
    self.table = None
    self.where = None
    self.group = ''
    self.limit = None

  def __parse(self, table,limit,spec):
    def set_select():
      self.select = ', '.join(spec['select'])
    def set_group():
      self.group = ', '.join(spec['stats']['groups'])
    def set_where():
      if spec['filter'] == {}:
        return
      self.where = []
      for key in spec['filter']:
        v = spec['filter'][key]
        for quantifier in v:
          if quantifier is 'ge':
            self.where.append("%s >= %s" % (key, v[quantifier]))
          elif quantifier is "gt":
            self.where.append("%s > %s" % (key, v[quantifier]))
          elif quantifier is "lt":
            self.where.append("%s < %s" % (key, v[quantifier]))
          elif quantifier is "le":
            self.where.append("%s <= %s" % (key, v[quantifier]))
          elif quantifier is "in":
            self.where.append("%s in %s" % (key, (', ').join(v[quantifier])))
          else:
            raise NameError("Unrecognized filter quantifier: %s" % quantifier)
    def set_orderby():
      if spec['meta'] == {}:
        return
      for key in spec['meta']:
        val = spec['meta'][key]
        assert 'sort' in val, 'Meta key missing: sort'
        self.orderby = val['sort'] + ' %s' % ('ASC' if 'asc' in val and val['asc'] == 'true' else 'DESC')

    self.reset()
    self.table = table
    self.limit = limit
    set_select()
    set_group()
    set_where()
    set_orderby()

  def __build(self):
    assert self.table is not None
    assert self.select is not None
    query = 'SELECT %s FROM %s ' % (self.select, self.table)
    if self.where is not None:
      query += 'WHERE % ' % self.where[0]
      for idx in range(1, len(self.where)):
        ' AND %s ' % self.where[idx]
    if self.group != '':
      query += 'GROUP BY %s ' % self.group
    if self.limit is not None:
      query += 'LIMIT %s' % self.limit
    return query

  def get_query(self,table,limit,spec):
    self.__parse(table,limit,spec)
    return self.__build()


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
