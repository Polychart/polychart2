(function() {
  var CategoricalDomain, DateDomain, NumericDomain, aesthetics, domainMerge, flattenGeoms, makeDomain, makeDomainSet, mergeDomainSets, mergeDomains, poly;

  poly = this.poly || {};

  /*
  # CONSTANTS
  */

  aesthetics = poly["const"].aes;

  /*
  # GLOBALS
  */

  poly.domain = {};

  /*
  Produce a domain set for each layer based on both the information in each
  layer and the specification of the guides, then merge them into one domain
  set.
  */

  poly.domain.make = function(layers, guideSpec, strictmode) {
    var domainSets, layerObj, _i, _len;
    domainSets = [];
    for (_i = 0, _len = layers.length; _i < _len; _i++) {
      layerObj = layers[_i];
      domainSets.push(makeDomainSet(layerObj, guideSpec, strictmode));
    }
    return mergeDomainSets(domainSets);
  };

  poly.domain.sortfn = function(domain) {
    switch (domain.type) {
      case 'num':
        return function(x) {
          return x;
        };
      case 'date':
        return function(x) {
          return x;
        };
      case 'cat':
        return function(x) {
          var idx;
          idx = _.indexOf(domain.levels, x);
          if (idx === -1) return idx = Infinity;
        };
    }
  };

  /*
  # CLASSES & HELPER
  */

  /*
  Domain classes
  */

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

  /*
  Public-ish interface for making different domain types
  */

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

  /*
  Make a domain set. A domain set is an associate array of domains, with the
  keys being aesthetics
  */

  makeDomainSet = function(layerObj, guideSpec, strictmode) {
    var aes, domain, fromspec, meta, values, _ref, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8;
    domain = {};
    for (aes in layerObj.mapping) {
      if (strictmode) {
        domain[aes] = makeDomain(guideSpec[aes]);
      } else {
        values = flattenGeoms(layerObj.geoms, aes);
        meta = (_ref = layerObj.getMeta(aes)) != null ? _ref : {};
        fromspec = function(item) {
          if (guideSpec[aes] != null) {
            return guideSpec[aes][item];
          } else {
            return null;
          }
        };
        switch (meta.type) {
          case 'num':
            domain[aes] = makeDomain({
              type: 'num',
              min: (_ref2 = fromspec('min')) != null ? _ref2 : _.min(values),
              max: (_ref3 = fromspec('max')) != null ? _ref3 : _.max(values),
              bw: (_ref4 = fromspec('bw')) != null ? _ref4 : meta.bw
            });
            break;
          case 'date':
            domain[aes] = makeDomain({
              type: 'date',
              min: (_ref5 = fromspec('min')) != null ? _ref5 : _.min(values),
              max: (_ref6 = fromspec('max')) != null ? _ref6 : _.max(values),
              bw: (_ref7 = fromspec('bw')) != null ? _ref7 : meta.bw
            });
            break;
          case 'cat':
            domain[aes] = makeDomain({
              type: 'cat',
              levels: (_ref8 = fromspec('levels')) != null ? _ref8 : _.uniq(values),
              sorted: fromspec('levels') != null
            });
        }
      }
    }
    return domain;
  };

  /*
  VERY preliminary flatten function. Need to optimize
  */

  flattenGeoms = function(geoms, aes) {
    var geom, k, l, mark, values, _ref;
    values = [];
    for (k in geoms) {
      geom = geoms[k];
      _ref = geom.marks;
      for (l in _ref) {
        mark = _ref[l];
        values = values.concat(poly.flatten(mark[aes]));
      }
    }
    return values;
  };

  /*
  Merge an array of domain sets: i.e. merge all the domains that shares the
  same aesthetics.
  */

  mergeDomainSets = function(domainSets) {
    var aes, domains, merged, _i, _len;
    merged = {};
    for (_i = 0, _len = aesthetics.length; _i < _len; _i++) {
      aes = aesthetics[_i];
      domains = _.without(_.pluck(domainSets, aes), void 0);
      if (domains.length > 0) merged[aes] = mergeDomains(domains);
    }
    return merged;
  };

  /*
  Helper for merging domains of the same type. Two domains of the same type
  can be merged if they share the same properties:
   - For numeric/date variables all domains must have the same binwidth parameter
   - For categorial variables, sorted domains must have any categories in common
  */

  domainMerge = {
    'num': function(domains) {
      var bw, max, min, _ref;
      bw = _.uniq(_.map(domains, function(d) {
        return d.bw;
      }));
      if (bw.length > 1) {
        throw new poly.LengthError("All binwidths are not of the same length");
      }
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
    'date': function(domains) {
      var bw, max, min, _ref;
      bw = _.uniq(_.map(domains, function(d) {
        return d.bw;
      }));
      if (bw.length > 1) {
        throw new poly.LengthError("All binwidths are not of the same length");
      }
      bw = (_ref = bw[0]) != null ? _ref : void 0;
      min = _.min(_.map(domains, function(d) {
        return d.min;
      }));
      max = _.max(_.map(domains, function(d) {
        return d.max;
      }));
      return makeDomain({
        type: 'date',
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
        throw new poly.UnknownError();
      }
      sortedLevels = [_.flatten(sortedLevels, true)];
      levels = _.union.apply(this, sortedLevels.concat(unsortedLevels));
      if (sortedLevels[0].length === 0) levels = levels.sort();
      return makeDomain({
        type: 'cat',
        levels: levels,
        sorted: true
      });
    }
  };

  /*
  Merge an array of domains: Two domains can be merged if they are of the
  same type, and they share certain properties.
  */

  mergeDomains = function(domains) {
    var types;
    types = _.uniq(_.map(domains, function(d) {
      return d.type;
    }));
    if (types.length > 1) {
      throw new poly.TypeError("Not all domains are of the same type");
    }
    return domainMerge[types[0]](domains);
  };

  /*
  # EXPORT
  */

  this.poly = poly;

}).call(this);
