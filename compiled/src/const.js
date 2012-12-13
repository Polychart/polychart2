(function() {
  var poly;

  poly = this.poly || {};

  /*
  CONSTANTS
  ---------
  These are constants that are referred to throughout the coebase
  */

  poly["const"] = {
    aes: ['x', 'y', 'color', 'size', 'opacity', 'shape', 'id', 'text'],
    noLegend: ['x', 'y', 'id', 'text', 'tooltip'],
    trans: {
      'bin': ['key', 'binwidth'],
      'lag': ['key', 'lag']
    },
    stat: {
      'count': ['key'],
      'sum': ['key'],
      'mean': ['key'],
      'box': ['key']
    },
    timerange: ['second', 'minute', 'hour', 'day', 'week', 'month', 'year'],
    metas: {
      sort: null,
      stat: null,
      limit: null,
      asc: true
    },
    scaleFns: {
      novalue: function() {
        return {
          v: null,
          f: 'novalue',
          t: 'scalefn'
        };
      },
      max: function(v) {
        return {
          v: v,
          f: 'max',
          t: 'scalefn'
        };
      },
      min: function(v) {
        return {
          v: v,
          f: 'min',
          t: 'scalefn'
        };
      },
      upper: function(v) {
        return {
          v: v,
          f: 'upper',
          t: 'scalefn'
        };
      },
      lower: function(v) {
        return {
          v: v,
          f: 'lower',
          t: 'scalefn'
        };
      },
      middle: function(v) {
        return {
          v: v,
          f: 'middle',
          t: 'scalefn'
        };
      },
      jitter: function(v) {
        return {
          v: v,
          f: 'jitter',
          t: 'scalefn'
        };
      },
      identity: function(v) {
        return {
          v: v,
          f: 'identity',
          t: 'scalefn'
        };
      }
    },
    epsilon: Math.pow(10, -7),
    defaults: {
      'x': {
        v: null,
        f: 'novalue',
        t: 'scalefn'
      },
      'y': {
        v: null,
        f: 'novalue',
        t: 'scalefn'
      },
      'color': 'steelblue',
      'size': 2,
      'opacity': 0.7
    },
    formatter: {
      'cat': function(x) {
        return x;
      },
      'num': function(x) {
        return x;
      },
      'date': function(x) {
        return moment.unix(x).format('L');
      }
    }
  };

  this.poly = poly;

}).call(this);
