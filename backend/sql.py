import copy
import re

class Validate:
  @staticmethod
  def check_not_keywords(w):
    keywords = ['SELECT', 'DELETE', 'FROM', 'JOIN', 'WHERE', 'ORDER BY', 'GROUP BY']
    assert all(w.upper() != k  for k in keywords)

  @staticmethod
  def check_func(w):
    """Checks for function format: func(param1, param2, ...)"""
    match = re.search(r'(\w+)\((.*)\)(.*)', w)
    assert match is not None
    assert match.group(3) == ''
    name = match.group(1)
    params = match.group(2)
    Validate.check_not_keywords(name)
    if params == '':
      return
    params = params.split(',')
    for p in params:
      p = p.strip()
      Validate.check_not_keywords(p)
      assert '(' not in p and ')' not in p

  @staticmethod
  def word(w):
    assert ';' not in w
    Validate.check_not_keywords(w)
    if '(' in w or ')' in w:
      assert '(' in w and ')' in w
      Validate.check_func(w)

  @staticmethod
  def list_of_words(lst):
    for w in lst:
      Validate.word(w)

  @staticmethod
  def num(n):
    if type(n) is int:
      return
    if type(n) is str or type(n) is unicode:
      assert n.isdigit()

class Parser:
  @staticmethod
  def parse_select(select):
    if type(select) is list:
      Validate.list_of_words(select)
      return ', '.join(select) if select != [] else None
    else:
      Validate.word(select)
      return select

  @staticmethod
  def parse_where(where):
    if where == {}:
      return None
    result = []
    for category in where:
      dict_of_quant = where[category]
      Validate.word(category)
      for quantifier in dict_of_quant:
        val = dict_of_quant[quantifier]
        Validate.num(val) if type(val) != [] else Validate.list_of_words(val)
        if quantifier is 'ge':
          result.append("%s >= %s" % (category, val))
        elif quantifier is "gt":
          result.append("%s > %s" % (category, val))
        elif quantifier is "lt":
          result.append("%s < %s" % (category, val))
        elif quantifier is "le":
          result.append("%s <= %s" % (category, val))
        elif quantifier is "in":
          result.append("%s in (%s)" % (category, (', ').join(["'%s'" % col   for col in val])))
        else:
          raise NameError("Unrecognized filter quantifier: %s" % quantifier)
    return result

  @staticmethod
  def parse_group(group):
    # Does same thing as parse_select
    return Parser.parse_select(group)

  @staticmethod
  def parse_order(order):
    assert 'sort' in order
    Validate.word(order['sort'])
    if 'asc' in order:
      assert type(order['asc']) is bool
    return '%s %s' % (order['sort'], 'ASC' if 'asc' in order and order['asc'] is True else 'DESC')

class QueryBuilder:
  def __init__(self, raw_table):
    self.select = None
    self.table = None
    self.where = None
    self.groupby = None
    self.orderby = None
    self.limit = None

    self.set_table(raw_table)

  def set_select(self, raw_select):
    assert type(raw_select) is str or type(raw_select) is unicode or type(raw_select) is list
    self.select = Parser.parse_select(raw_select)

  def set_table(self, raw_table):
    assert type(raw_table) is str or type(raw_table) is unicode
    self.table = raw_table

  def set_where(self, raw_where):
    assert type(raw_where) is dict
    self.where = Parser.parse_where(raw_where)

  def set_groupby(self, raw_group):
    assert type(raw_group) is str or type(raw_group) is unicode or type(raw_group) is list
    self.groupby = Parser.parse_group(raw_group)

  def set_orderby(self, raw_order):
    assert type(raw_order) is dict
    assert 'sort' in raw_order 
    self.orderby = Parser.parse_order(raw_order)

  def set_limit(self, raw_limit):
    assert type(raw_limit) is str or type(raw_limit) is unicode or type(raw_limit) is int
    if type(raw_limit) is int:
      self.limit = str(raw_limit)
    else:
      assert raw_limit.isdigit()
      self.limit = raw_limit

  def build(self):
    assert self.table is not None
    assert self.select is not None
    query = 'SELECT %s FROM %s ' % (self.select, self.table)
    if self.where is not None:
      query += ('WHERE %s ' % self.where[0])
      for idx in range(1, len(self.where)):
        ' AND %s ' % self.where[idx]
    if self.groupby is not None:
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
