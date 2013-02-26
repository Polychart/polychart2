import copy

class Parser:
  @staticmethod
  def parse_select(select):
    if type(select) is list:
      return ', '.join(select) if select != [] else None
    else:
      return select

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
          result.append("%s in (%s)" % (key, (', ').join(["'%s'" % col   for col in v[quantifier]])))
        else:
          raise NameError("Unrecognized filter quantifier: %s" % quantifier)
    return result

  @staticmethod
  def parse_group(group):
    if type(group) is list:
      return ', '.join(group) if group != [] else None
    else:
      return group

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
    #assert type(raw_group) is str or type(raw_group) is list
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
      query += ('WHERE %s ' % self.where[0])
      for idx in range(1, len(self.where)):
        ' AND %s ' % self.where[idx]
    if self.group is not None:
      query += 'GROUP BY %s ' % self.groupby
    if self.orderby is not None:
      query += 'ORDER BY %s ' % self.orderby
    if self.limit is not None:
      query += 'LIMIT %s' % self.limit
    return query

  @staticmethod
  def build_sort_query(table, spec):
    builder = QueryBuilder(table)
    meta = spec['meta']
    category = meta.iterkeys().next()

    builder.set_select(category)
    builder.set_where(spec['filter'])
    builder.set_orderby(meta[category])
    builder.set_groupby(category)
    if 'limit' in meta[builder.select]:
      builder.set_limit(meta[builder.select]['limit'])
    return builder.build()
    
  @staticmethod
  def build_calc_query(table, spec, limit, categories=None):
    builder = QueryBuilder(table)
    meta = spec['meta']
    
    where = copy.deepcopy(spec['filter']) if spec['filter'] != {} else {}
    if categories is not None:
      category = meta.iterkeys().next()
      where[category] = { 'in' : [elem[0]  for elem in categories] } # Gets the first elem of the tuple
    builder.set_select(spec['select'])
    builder.set_where(where)
    builder.set_groupby(spec['stats']['groups']);
    builder.set_limit(limit)
    return builder.build()

def process_fn(execute):
  def dataprocess(table, limit=1000, spec={}):
    result = ''
    if 'meta' in spec and spec['meta'] != {}:
      # Step 1:
      query = QueryBuilder.build_sort_query(table, spec)
      result = execute(query)

      # Step 2:
      query = QueryBuilder.build_calc_query(table, spec, limit, result)
      result = execute(query)
    else: 
      query = QueryBuilder.build_calc_query(table, spec, limit)
      result = execute(query)
    return { 'data': result, 'meta': spec['select'] }
  return dataprocess
