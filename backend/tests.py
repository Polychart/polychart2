import unittest
from sql import Validate, Parser, QueryBuilder

class CheckTests(unittest.TestCase):
  def test_fail_on_sql_restricted_keywords(self):
    keywords = ['select', 'Delete', 'fRom', 'join', 'wherE', 'ORDER BY', 'GROUP BY']
    for k in keywords:
      self.assertRaises(AssertionError, Validate.check_not_keywords, k)

  def test_fail_on_improperly_formatted_func_names(self):
    name_with_semicolon = 'sum;'
    name_with_nesting_func = 'sum(cat(val))'
    name_with_long_tail = 'bin(grouping, 10); delete blah'
    name_with_keyword = 'sum(select, jon)'
    self.assertRaises(AssertionError, Validate.check_func, name_with_semicolon)
    self.assertRaises(AssertionError, Validate.check_func, name_with_nesting_func)
    self.assertRaises(AssertionError, Validate.check_func, name_with_long_tail)
    self.assertRaises(AssertionError, Validate.check_func, name_with_keyword)

  def test_succeed_on_func_names(self):
    name_with_parens = 'bin(grouping, 10)'
    name_with_multiple_params = 'sum(col1, col2, col3)'
    Validate.check_func(name_with_parens)
    Validate.check_func(name_with_multiple_params)

class ValidateTests(unittest.TestCase):
  def test_fail_on_bad_word(self):
    word_with_semicolon = 'asdf;'
    word_with_bad_func_name = 'bin(grouping, select)'
    self.assertRaises(AssertionError, Validate.word, word_with_semicolon)
    self.assertRaises(AssertionError, Validate.word, word_with_bad_func_name)

  def test_fail_on_list_of_bad_words(self):
    lst_with_one_bad = ['asdf;', 'bin(grouping, 10)']
    self.assertRaises(AssertionError, Validate.list_of_words, lst_with_one_bad)

  def test_fail_on_bad_num(self):
    not_num = u'asd2'
    self.assertRaises(AssertionError, Validate.num, not_num)

  def test_succeed_on_word(self):
    word_with_func_name = 'asdf(jon, doe)'
    word_normal = 'hellothisisyourmaster'
    Validate.word(word_with_func_name)
    Validate.word(word_normal)

  def test_succeed_on_num(self):
    num_in_unicode = u'1337'
    num_in_str = '1337'
    num_normal = 1337
    Validate.num(num_in_unicode)
    Validate.num(num_in_str)
    Validate.num(num_normal)

class ParserTests(unittest.TestCase):
  def test_succeed_on_parse_select(self):
    select_as_str = 'group'
    select_as_lst = ['darth', 'vader']
    self.assertEqual(Parser.parse_select(select_as_str), 'group')
    self.assertEqual(Parser.parse_select(select_as_lst), 'darth, vader')

  def test_fail_on_parse_select(self):
    select_as_invalid_keyword = 'select'
    select_as_invalid_lst = ['bin(group, ', 'jondoe']
    self.assertRaises(AssertionError, Parser.parse_select, select_as_invalid_keyword)
    self.assertRaises(AssertionError, Parser.parse_select, select_as_invalid_lst)

  def test_succeed_on_parse_where(self):
    filter_with_inequalities = {'val1': { 'ge': 8, 'le': 17 }}
    filter_with_strict_inequalities = { 'val2': { 'lt': 9, 'gt':2} }
    filter_with_in = { 'color': {'in': ['blue', 'red']}}
    self.assertEqual(Parser.parse_where(filter_with_inequalities), [('val1', '>=', 8), ('val1', '<=', 17)])
    self.assertEqual(Parser.parse_where(filter_with_strict_inequalities), [('val2', '<', 9), ('val2', '>', 2)])
    self.assertEqual(Parser.parse_where(filter_with_in), [('color', 'in', ['blue', 'red'])])

  def test_fail_on_parse_where(self):
    filter_with_non_numerical_inequalities = { 'hour': {'ge': 'somenum'}}
    filter_with_invalid_qualifier = { 'hour': { 'blap': '3'} }
    self.assertRaises(AssertionError, Parser.parse_where, filter_with_non_numerical_inequalities)
    self.assertRaises(NameError, Parser.parse_where, filter_with_invalid_qualifier)

  def test_succeed_on_parse_group(self):
    # Does same thing as parse_select
    group_as_str = 'group'
    group_as_lst = ['darth', 'vader']
    self.assertEqual(Parser.parse_group(group_as_str), 'group')
    self.assertEqual(Parser.parse_group(group_as_lst), 'darth, vader')

  def test_succeed_on_parse_order(self):
    order_asc = {u'sort': u'sum(val1)', u'asc': True }
    order_non_specicied_asc = {u'sort': u'sum(val1)' }
    self.assertEqual(Parser.parse_order(order_asc), ('sum(val1)', 'ASC'))
    self.assertEqual(Parser.parse_order(order_non_specicied_asc), ('sum(val1)', 'DESC'))

  def test_fail_on_parse_order(self):
    order_without_sort = { 'limit': 2}
    self.assertRaises(AssertionError, Parser.parse_order, order_without_sort)

class QueryBuilderTests(unittest.TestCase):
  def test_succeed_build_sort_query(self):
    table = 'example1'
    spec = {u'filter': {}, u'meta': {u'grp': {u'sort': u'sum(val1)', u'asc': True, u'stat': {u'stat': u'sum', u'name': u'sum(val1)', u'key': u'val1'}}}, u'trans': [], u'stats': {u'stats': [{u'stat': u'sum', u'name': u'sum(val1)', u'key': u'val1'}], u'groups': [u'grp']}, u'select': [u'grp', u'sum(val1)']}
    query, params = QueryBuilder.build_sort_query(table, spec)
    self.assertEqual(query, 'SELECT grp FROM example1 GROUP BY grp ORDER BY ? ASC ')
    self.assertEqual(params, [u'sum(val1)'])

  def test_succeed_build_calc_query(self):
    table = 'example1'
    limit = 1000
    spec = {u'filter': {}, u'meta': {u'grp': {u'sort': u'sum(val1)', u'asc': True, u'stat': {u'stat': u'sum', u'name': u'sum(val1)', u'key': u'val1'}}}, u'trans': [], u'stats': {u'stats': [{u'stat': u'sum', u'name': u'sum(val1)', u'key': u'val1'}], u'groups': [u'grp']}, u'select': [u'grp', u'sum(val1)']}
    result = [(u'A',), (u'B',)]
    query, params = QueryBuilder.build_calc_query(table, spec, limit, result)
    self.assertEqual(query, "SELECT grp, sum(val1) FROM example1 WHERE grp in (?,?) GROUP BY grp LIMIT ?")
    self.assertEqual(params, [u'A', u'B', '1000'])

if __name__ == '__main__':
    unittest.main()
