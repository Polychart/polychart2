(function() {
  var poly;

  poly = this.poly || {};

  poly.scaleFns = {
    novalue: function() {
      return {
        v: null,
        f: 'novalue'
      };
    },
    upper: function(v) {
      return {
        v: v,
        f: 'upper'
      };
    },
    lower: function(v) {
      return {
        v: v,
        f: 'lower'
      };
    },
    middle: function(v) {
      return {
        v: v,
        f: 'middle'
      };
    },
    jitter: function(v) {
      return {
        v: v,
        f: 'jitter'
      };
    },
    identity: function(v) {
      return {
        v: v,
        f: 'identity'
      };
    }
  };

  this.poly = poly;

}).call(this);
