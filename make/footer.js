  }
  return {
    data: poly.data,
    chart: poly.chart,
    pivot: poly.pivot,
    numeral: poly.numeral,
    handler: poly.handler,
    parser: {
      bracket: poly.parser.bracket,
      unbracket: poly.parser.unbracket,
      parse: poly.parser.parse,
      getExpression: poly.parser.getExpression
    },
    debug: poly
  }
})(window.polyjs);
