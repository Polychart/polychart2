(function() {
  var poly;

  poly = this.poly || {};

  poly.scaleFns = {
    novalue: function() {
      return {
        v: null,
        f: 'novalue',
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
  };

  this.poly = poly;

}).call(this);
