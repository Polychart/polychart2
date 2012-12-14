(function() {
  var ScaleSet, poly,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  poly = this.poly || {};

  poly.scaleset = function(guideSpec, domains, ranges) {
    return new ScaleSet(guideSpec, domains, ranges);
  };

  ScaleSet = (function() {

    function ScaleSet(tmpRanges, coord) {
      this.axes = {
        x: poly.guide.axis(coord.axisType('x')),
        y: poly.guide.axis(coord.axisType('y'))
      };
      this.coord = coord;
      this.ranges = tmpRanges;
      this.legends = [];
      this.deletedLegends = [];
    }

    ScaleSet.prototype.make = function(guideSpec, domains, layers) {
      this.guideSpec = guideSpec;
      this.layers = layers;
      this.domains = domains;
      this.domainx = this.domains.x;
      this.domainy = this.domains.y;
      this.scales = this._makeScales(guideSpec, domains, this.ranges);
      this.reverse = {
        x: this.scales.x.finv,
        y: this.scales.y.finv
      };
      return this.layerMapping = this._mapLayers(layers);
    };

    ScaleSet.prototype.setRanges = function(ranges) {
      this.ranges = ranges;
      this._makeXScale();
      return this._makeYScale();
    };

    ScaleSet.prototype.setXDomain = function(d) {
      this.domainx = d;
      return this._makeXScale();
    };

    ScaleSet.prototype.setYDomain = function(d) {
      this.domainy = d;
      return this._makeYScale();
    };

    ScaleSet.prototype.resetDomains = function() {
      this.domainx = this.domains.x;
      this.domainy = this.domains.y;
      this._makeXScale();
      return this._makeYScale();
    };

    ScaleSet.prototype._makeXScale = function() {
      return this.scales.x.make(this.domainx, this.ranges.x);
    };

    ScaleSet.prototype._makeYScale = function() {
      return this.scales.y.make(this.domainy, this.ranges.y);
    };

    ScaleSet.prototype._makeScales = function(guideSpec, domains, ranges) {
      var scales, specScale, _ref, _ref2, _ref3, _ref4;
      specScale = function(a) {
        if (guideSpec && (guideSpec[a] != null) && (guideSpec[a].scale != null)) {
          return guideSpec[a].scale;
        }
        return null;
      };
      scales = {};
      scales.x = (_ref = specScale('x')) != null ? _ref : poly.scale.linear();
      scales.x.make(domains.x, ranges.x);
      scales.y = (_ref2 = specScale('y')) != null ? _ref2 : poly.scale.linear();
      scales.y.make(domains.y, ranges.y);
      if (domains.color != null) {
        if (domains.color.type === 'cat') {
          scales.color = (_ref3 = specScale('color')) != null ? _ref3 : poly.scale.color();
        } else {
          scales.color = (_ref4 = specScale('color')) != null ? _ref4 : poly.scale.gradient({
            upper: 'steelblue',
            lower: 'red'
          });
        }
        scales.color.make(domains.color);
      }
      if (domains.size != null) {
        scales.size = specScale('size') || poly.scale.area();
        scales.size.make(domains.size);
      }
      if (domains.opacity != null) {
        scales.opacity = specScale('opacity') || poly.scale.opacity();
        scales.opacity.make(domains.opacity);
      }
      scales.text = poly.scale.identity();
      scales.text.make();
      return scales;
    };

    ScaleSet.prototype.fromPixels = function(start, end) {
      var map, obj, x, y, _i, _j, _len, _len2, _ref, _ref2, _ref3;
      _ref = this.coord.getAes(start, end, this.reverse), x = _ref.x, y = _ref.y;
      obj = {};
      _ref2 = this.layerMapping.x;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        map = _ref2[_i];
        if ((map.type != null) && map.type === 'map') obj[map.value] = x;
      }
      _ref3 = this.layerMapping.y;
      for (_j = 0, _len2 = _ref3.length; _j < _len2; _j++) {
        map = _ref3[_j];
        if ((map.type != null) && map.type === 'map') obj[map.value] = y;
      }
      return obj;
    };

    ScaleSet.prototype.getSpec = function(a) {
      if ((this.guideSpec != null) && (this.guideSpec[a] != null)) {
        return this.guideSpec[a];
      } else {
        return {};
      }
    };

    ScaleSet.prototype.makeAxes = function() {
      this.axes.x.make({
        domain: this.domainx,
        type: this.scales.x.tickType(),
        guideSpec: this.getSpec('x'),
        key: poly.getLabel(this.layers, 'x')
      });
      this.axes.y.make({
        domain: this.domainy,
        type: this.scales.y.tickType(),
        guideSpec: this.getSpec('y'),
        key: poly.getLabel(this.layers, 'y')
      });
      return this.axes;
    };

    ScaleSet.prototype.renderAxes = function(dims, renderer) {
      this.axes.x.render(dims, renderer);
      return this.axes.y.render(dims, renderer);
    };

    ScaleSet.prototype._mapLayers = function(layers) {
      var aes, obj;
      obj = {};
      for (aes in this.domains) {
        obj[aes] = _.map(layers, function(layer) {
          if (layer.mapping[aes] != null) {
            return {
              type: 'map',
              value: layer.mapping[aes]
            };
          } else if (layer.consts[aes] != null) {
            return {
              type: 'const',
              value: layer["const"][aes]
            };
          } else {
            return layer.defaults[aes];
          }
        });
      }
      return obj;
    };

    ScaleSet.prototype._mergeAes = function(layers) {
      var aes, m, mapped, merged, merging, _i, _len;
      merging = [];
      for (aes in this.domains) {
        if (__indexOf.call(poly["const"].noLegend, aes) >= 0) continue;
        mapped = _.map(layers, function(layer) {
          return layer.mapping[aes];
        });
        if (!_.all(mapped, _.isUndefined)) {
          merged = false;
          for (_i = 0, _len = merging.length; _i < _len; _i++) {
            m = merging[_i];
            if (_.isEqual(m.mapped, mapped)) {
              m.aes.push(aes);
              merged = true;
              break;
            }
          }
          if (!merged) {
            merging.push({
              aes: [aes],
              mapped: mapped
            });
          }
        }
      }
      return _.pluck(merging, 'aes');
    };

    ScaleSet.prototype.makeLegends = function(mapping) {
      var aes, aesGroups, i, idx, legend, legenddeleted, _i, _j, _len, _len2, _ref;
      aesGroups = this._mergeAes(this.layers);
      idx = 0;
      while (idx < this.legends.length) {
        legend = this.legends[idx];
        legenddeleted = true;
        i = 0;
        while (i < aesGroups.length) {
          aes = aesGroups[i];
          if (_.isEqual(aes, legend.aes)) {
            aesGroups.splice(i, 1);
            legenddeleted = false;
            break;
          }
          i++;
        }
        if (legenddeleted) {
          this.deletedLegends.push(legend);
          this.legends.splice(idx, 1);
        } else {
          idx++;
        }
      }
      for (_i = 0, _len = aesGroups.length; _i < _len; _i++) {
        aes = aesGroups[_i];
        this.legends.push(poly.guide.legend(aes));
      }
      _ref = this.legends;
      for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
        legend = _ref[_j];
        aes = legend.aes[0];
        legend.make({
          domain: this.domains[aes],
          guideSpec: this.getSpec(aes),
          type: this.scales[aes].tickType(),
          mapping: this.layerMapping,
          keys: poly.getLabel(this.layers, aes)
        });
      }
      return this.legends;
    };

    ScaleSet.prototype.renderLegends = function(dims, renderer) {
      var legend, maxheight, maxwidth, newdim, offset, _i, _j, _len, _len2, _ref, _ref2, _results;
      _ref = this.deletedLegends;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        legend = _ref[_i];
        legend.remove(renderer);
      }
      this.deletedLegends = [];
      offset = {
        x: 0,
        y: 0
      };
      maxwidth = 0;
      maxheight = dims.height - dims.guideTop - dims.paddingTop;
      _ref2 = this.legends;
      _results = [];
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        legend = _ref2[_j];
        newdim = legend.getDimension();
        if (newdim.height + offset.y > maxheight) {
          offset.x += maxwidth + 5;
          offset.y = 0;
          maxwidth = 0;
        }
        if (newdim.width > maxwidth) maxwidth = newdim.width;
        legend.render(dims, renderer, offset);
        _results.push(offset.y += newdim.height);
      }
      return _results;
    };

    return ScaleSet;

  })();

}).call(this);
