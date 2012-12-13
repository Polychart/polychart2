(function() {
  var POSTFIXES, formatNumber, poly, postfix,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  poly = this.poly || {};

  poly.format = function(type, step) {
    switch (type) {
      case 'cat':
        return poly.format.identity;
      case 'num':
        return poly.format.number(step);
      case 'date':
        return poly.format.date(step);
    }
  };

  poly.format.identity = function(x) {
    return x;
  };

  POSTFIXES = {
    0: '',
    3: 'k',
    6: 'm',
    9: 'b',
    12: 't'
  };

  postfix = function(num, pow) {
    if (!_.isUndefined(POSTFIXES[pow])) {
      return num + POSTFIXES[pow];
    } else {
      return num + 'e' + (pow > 0 ? '+' : '-') + Math.abs(pow);
    }
  };

  formatNumber = function(n) {
    var abs, i, s, v;
    if (!isFinite(n)) return n;
    s = "" + n;
    abs = Math.abs(n);
    if (abs >= 1000) {
      v = ("" + abs).split(/\./);
      i = v[0].length % 3 || 3;
      v[0] = s.slice(0, i + (n < 0)) + v[0].slice(i).replace(/(\d{3})/g, ',$1');
      s = v.join('.');
    }
    return s;
  };

  poly.format.number = function(exp_original) {
    return function(num) {
      var exp, exp_fixed, exp_precision, rounded;
      exp_fixed = 0;
      exp_precision = 0;
      exp = exp_original != null ? exp_original : Math.floor(Math.log(Math.abs(num === 0 ? 1 : num)) / Math.LN10);
      if ((exp_original != null) && (exp === 2 || exp === 5 || exp === 8 || exp === 11)) {
        exp_fixed = exp + 1;
        exp_precision = 1;
      } else if (exp === -1) {
        exp_fixed = 0;
        exp_precision = exp_original != null ? 1 : 2;
      } else if (exp === -2) {
        exp_fixed = 0;
        exp_precision = exp_original != null ? 2 : 3;
      } else if (exp === 1 || exp === 2) {
        exp_fixed = 0;
      } else if (exp > 3 && exp < 6) {
        exp_fixed = 3;
      } else if (exp > 6 && exp < 9) {
        exp_fixed = 6;
      } else if (exp > 9 && exp < 12) {
        exp_fixed = 9;
      } else if (exp > 12 && exp < 15) {
        exp_fixed = 12;
      } else {
        exp_fixed = exp;
        exp_precision = exp_original != null ? 0 : 1;
      }
      rounded = Math.round(num / Math.pow(10, exp_fixed - exp_precision));
      rounded /= Math.pow(10, exp_precision);
      rounded = rounded.toFixed(exp_precision);
      return postfix(formatNumber(rounded), exp_fixed);
    };
  };

  poly.format.date = function(level) {
    if (!(__indexOf.call(poly["const"].timerange, level) >= 0)) level = 'day';
    if (level === 'second') {
      return function(date) {
        return moment.unix(date).format('h:mm:ss a');
      };
    } else if (level === 'minute') {
      return function(date) {
        return moment.unix(date).format('h:mm a');
      };
    } else if (level === 'hour') {
      return function(date) {
        return moment.unix(date).format('MMM D h a');
      };
    } else if (level === 'day' || level === 'week') {
      return function(date) {
        return moment.unix(date).format('MMM D');
      };
    } else if (level === 'month') {
      return function(date) {
        return moment.unix(date).format('YY/MM');
      };
    } else if (level === 'year') {
      return function(date) {
        return moment.unix(date).format('YYYY');
      };
    }
  };

}).call(this);
