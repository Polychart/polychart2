  }
  return {
    data: poly.data,
    chart: poly.chart,
    pivot: poly.pivot,
    numeral: poly.numeral,
    handler: poly.handler,
    parse: poly.parser.getExpression,
    debug: poly
  }
})(window.polyjs);
