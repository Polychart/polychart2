import copy

class Parser:
  @staticmethod
  def parse_select(select):
    return ', '.join(select) if select != [] else None

  @staticmethod
  def parse_where(where):
    if where == {}:
      return None
    result = []
    for key in where:
      v = where[key]
      for quantifier in v:
        if quantifier is 'ge':
          result.append("%s >= %s" % (key, v[quantifier]))
        elif quantifier is "gt":
          result.append("%s > %s" % (key, v[quantifier]))
        elif quantifier is "lt":
          result.append("%s < %s" % (key, v[quantifier]))
        elif quantifier is "le":
          result.append("%s <= %s" % (key, v[quantifier]))
        elif quantifier is "in":
          result.append("%s in %s" % (key, (', ').join(v[quantifier])))
        else:
          raise NameError("Unrecognized filter quantifier: %s" % quantifier)
    return result

  @staticmethod
  def parse_group(groups):
    ret = ', '.join(groups) if groups != [] else None
    return ret

  @staticmethod
  def parse_order(order):
    return '%s %s' % (order['sort'], 'ASC' if order['asc'] == 'true' else 'DESC')

class QueryBuilder:
  def __init__(self, raw_table):
    self.reset()
    self.set_table(raw_table)

  def reset(self):
    self.select = ''
    self.where = None
    self.group = ''
    self.limit = None
    self.orderby = None

  def set_select(self, raw_select):
    #assert type(raw_select) is str
    self.select = Parser.parse_select(raw_select)

  def set_table(self, raw_table):
    #assert type(raw_table) is str
    self.table = raw_table

  def set_where(self, raw_where):
    assert type(raw_where) is dict
    self.where = Parser.parse_where(raw_where)

  def set_groupby(self, raw_group):
    assert type(raw_group) is str or type(raw_group) is list
    self.groupby = Parser.parse_group(raw_group)

  def set_orderby(self, raw_order):
    assert type(raw_order) is dict
    assert 'sort' in raw_order 
    self.orderby = Parser.parse_order(raw_order)

  def set_limit(self, raw_limit):
    #assert type(raw_limit) is str
    #assert raw_limit.isdigit()
    self.limit = raw_limit

  def build(self):
    #assert self.table is not None
    #assert self.select is not None
    query = 'SELECT %s FROM %s ' % (self.select, self.table)
    if self.where is not None:
      query += 'WHERE % ' % self.where[0]
      for idx in range(1, len(self.where)):
        ' AND %s ' % self.where[idx]
    if self.orderby is not None:
      query += 'ORDER BY %s' % self.orderby
    if self.group is not None:
      query += 'GROUP BY %s ' % self.groupby
    if self.limit is not None:
      query += 'LIMIT %s' % self.limit
    return query

def process_fn(execute):
  def dataprocess2(table, limit=1000, spec={}):
    querybuilder = QueryBuilder(table)
    result = ''
    meta = spec['meta']
    if 'meta' in spec and spec['meta'] != {}:
      category = meta.iterkeys().next()

      # Step 1:
      querybuilder.reset()
      querybuilder.set_select(category)
      querybuilder.set_where(spec['filter'])
      querybuilder.set_orderby(meta[category])
      querybuilder.set_groupby(category)
      querybuilder.set_limit(meta[querybuilder.select]['limit'])

      query = querybuilder.build()
      result = execute(query)

      # Step 2:
      querybuilder.reset()
      querybuilder.set_select(spec['select'])
      where = copy.deepcopy(spec['filter'])
      where[category] = result
      querybuilder.set_where(where)
      querybuilder.set_groupby(spec['stats']['groups']);
      querybuilder.set_limit(limit)

      query = querybuilder.build()
      result = execute(query)
    else: 
      querybuilder.reset()
      querybuilder.set_select(spec['select'])
      querybuilder.set_where(spec['filter'])
      querybuilder.set_groupby(spec['stats']['groups'])
      querybuilder.set_limit(limit)
      query = querybuilder.build()
      result = execute(query)
    return { 'data': result, 'meta': spec['select'] }

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
  return dataprocess2
