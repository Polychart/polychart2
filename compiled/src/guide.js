(function() {
  var CategoricalDomain, DateDomain, NumericDomain, Tick, aesthetics, domainMerge, makeDomain, makeDomainSet, makeGuides, makeTicks, mergeDomainSets, mergeDomains, poly, tickFactory, tickValues;

  poly = this.poly || {};

  aesthetics = poly["const"].aes;

  makeGuides = function(layers, guideSpec, strictmode) {
    var domainSets;
    domainSets = [];
    _.each(layers, function(layerObj) {
      return domainSets.push(makeDomainSet(layerObj, guideSpec, strictmode));
    });
    return mergeDomainSets(domainSets);
  };

  makeDomainSet = function(layerObj, guideSpec, strictmode) {
    var domain;
    domain = {};
    _.each(_.keys(layerObj.mapping), function(aes) {
      if (strictmode) return domain[aes] = makeDomain(guideSpec[aes]);
    });
    return domain;
  };

  mergeDomainSets = function(domainSets) {
    var merged;
    merged = {};
    _.each(aesthetics, function(aes) {
      var domains;
      domains = _.without(_.pluck(domainSets, aes), void 0);
      if (domains.length > 0) return merged[aes] = mergeDomains(domains);
    });
    return merged;
  };

  NumericDomain = (function() {

    function NumericDomain(params) {
      this.type = params.type, this.min = params.min, this.max = params.max, this.bw = params.bw;
    }

    return NumericDomain;

  })();

  DateDomain = (function() {

    function DateDomain(params) {
      this.type = params.type, this.min = params.min, this.max = params.max, this.bw = params.bw;
    }

    return DateDomain;

  })();

  CategoricalDomain = (function() {

    function CategoricalDomain(params) {
      this.type = params.type, this.levels = params.levels, this.sorted = params.sorted;
    }

    return CategoricalDomain;

  })();

  makeDomain = function(params) {
    switch (params.type) {
      case 'num':
        return new NumericDomain(params);
      case 'date':
        return new DateDomain(params);
      case 'cat':
        return new CategoricalDomain(params);
    }
  };

  domainMerge = {
    'num': function(domains) {
      var bw, max, min, _ref;
      bw = _.uniq(_.map(domains, function(d) {
        return d.bw;
      }));
      if (bw.length > 1) console.log('wtf');
      bw = (_ref = bw[0]) != null ? _ref : void 0;
      min = _.min(_.map(domains, function(d) {
        return d.min;
      }));
      max = _.max(_.map(domains, function(d) {
        return d.max;
      }));
      return makeDomain({
        type: 'num',
        min: min,
        max: max,
        bw: bw
      });
    },
    'cat': function(domains) {
      var levels, sortedLevels, unsortedLevels;
      sortedLevels = _.chain(domains).filter(function(d) {
        return d.sorted;
      }).map(function(d) {
        return d.levels;
      }).value();
      unsortedLevels = _.chain(domains).filter(function(d) {
        return !d.sorted;
      }).map(function(d) {
        return d.levels;
      }).value();
      if (sortedLevels.length > 0 && _.intersection.apply(this, sortedLevels)) {
        console.log('wtf');
      }
      sortedLevels = [_.flatten(sortedLevels, true)];
      levels = _.union.apply(this, sortedLevels.concat(unsortedLevels));
      return makeDomain({
        type: 'cat',
        levels: levels,
        sorted: true
      });
    }
  };

  mergeDomains = function(domains) {
    var types;
    types = _.uniq(_.map(domains, function(d) {
      return d.type;
    }));
    if (types.length > 1) console.log('wtf');
    return domainMerge[types[0]](domains);
  };

  Tick = (function() {

    function Tick(params) {
      this.location = params.location, this.value = params.value;
    }

    return Tick;

  })();

  tickFactory = function(scale, formatter) {
    return function(value) {
      return new Tick({
        location: scale(value),
        value: formatter(value)
      });
    };
  };

  tickValues = {
    'cat': function(domain, numticks) {
      return domain.levels;
    },
    'num': function(domain, numticks) {
      var error, max, min, span, step, ticks, tmp;
      min = domain.min, max = domain.max;
      span = max - min;
      step = Math.pow(10, Math.floor(Math.log(span / numticks) / Math.LN10));
      error = numticks / span * step;
      if (error < 0.15) {
        step *= 10;
      } else if (error <= 0.35) {
        step *= 5;
      } else if (error <= 0.75) {
        step *= 2;
      }
      tmp = Math.ceil(min / step) * step;
      ticks = [];
      while (tmp < max) {
        ticks.push(tmp);
        tmp += step;
      }
      return ticks;
    },
    'num-log': function(domain, numticks) {
      return 2;
    },
    'date': function(domain, numticks) {
      return 2;
    }
  };

  makeTicks = function(domain, guideSpec, range, scale) {
    var formatter, ticks, _ref, _ref2;
    ticks = (_ref = guideSpec.ticks) != null ? _ref : tickValues[domain.type](domain, (_ref2 = guideSpec.numticks) != null ? _ref2 : 5);
    scale = scale || function(x) {
      return x;
    };
    formatter = function(x) {
      return x;
    };
    if (guideSpec.labels) {
      formatter = function(x) {
        var _ref3;
        return (_ref3 = guideSpec.labels[x]) != null ? _ref3 : x;
      };
    } else if (guideSpec.formatter) {
      formatter = guideSpec.formatter;
    }
    return ticks = _.map(ticks, tickFactory(scale, formatter));
  };

  poly.guide = {
    makeGuides: makeGuides,
    makeTicks: makeTicks
  };

  this.poly = poly;

}).call(this);
