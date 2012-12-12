(function() {
  var Graph, poly,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  poly = this.poly || {};

  Graph = (function() {

    function Graph(spec) {
      this._legacy = __bind(this._legacy, this);
      this.handleEvent = __bind(this.handleEvent, this);
      this.merge = __bind(this.merge, this);
      this.reset = __bind(this.reset, this);
      var _ref;
      this.handlers = [];
      this.layers = null;
      this.scaleSet = null;
      this.axes = null;
      this.legends = null;
      this.dims = null;
      this.paper = null;
      this.coord = (_ref = spec.coord) != null ? _ref : poly.coord.cartesian();
      this.initial_spec = spec;
      this.make(spec, true);
    }

    Graph.prototype.reset = function() {
      return this.make(this.initial_spec);
    };

    Graph.prototype.make = function(spec, first) {
      var dataChange, id, layerObj, merge, _len, _len2, _ref, _ref2, _results;
      if (first == null) first = false;
      if (spec == null) spec = this.initial_spec;
      this.spec = spec;
      if (spec.layers == null) spec.layers = [];
      if (this.layers == null) this.layers = this._makeLayers(this.spec);
      if (first) {
        dataChange = this.handleEvent('data');
        _ref = this.layers;
        for (id = 0, _len = _ref.length; id < _len; id++) {
          layerObj = _ref[id];
          spec.layers[id].data.subscribe(dataChange);
        }
      }
      merge = _.after(this.layers.length, this.merge);
      _ref2 = this.layers;
      _results = [];
      for (id = 0, _len2 = _ref2.length; id < _len2; id++) {
        layerObj = _ref2[id];
        _results.push(layerObj.make(spec.layers[id], merge));
      }
      return _results;
    };

    Graph.prototype.merge = function() {
      var clipping, dom, domains, layer, renderer, scales, _i, _len, _ref;
      domains = this._makeDomains(this.spec, this.layers);
      if (this.scaleSet == null) {
        this.scaleSet = this._makeScaleSet(this.spec, domains);
      }
      this.scaleSet.make(this.spec.guides, domains, this.layers);
      if (!this.dims) {
        this.dims = this._makeDimensions(this.spec, this.scaleSet);
        this.coord.make(this.dims);
        this.ranges = this.coord.ranges();
      }
      this.scaleSet.setRanges(this.ranges);
      this._legacy(domains);
      if (this.spec.dom) {
        dom = this.spec.dom;
        scales = this.scaleSet.scales;
        this.coord.setScales(scales);
        if (this.paper == null) {
          this.paper = this._makePaper(dom, this.dims.width, this.dims.height, this.handleEvent);
        }
        clipping = this.coord.clipping(this.dims);
        renderer = poly.render(this.handleEvent, this.paper, scales, this.coord, true, clipping);
        _ref = this.layers;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          layer = _ref[_i];
          layer.render(renderer);
        }
        renderer = poly.render(this.handleEvent, this.paper, scales, this.coord, false);
        this.scaleSet.makeAxes();
        this.scaleSet.renderAxes(this.dims, renderer);
        this.scaleSet.makeLegends();
        return this.scaleSet.renderLegends(this.dims, renderer);
      }
    };

    Graph.prototype.addHandler = function(h) {
      return this.handlers.push(h);
    };

    Graph.prototype.removeHandler = function(h) {
      return this.handlers.splice(_.indexOf(this.handlers, h), 1);
    };

    Graph.prototype.handleEvent = function(type) {
      var graph, handler;
      graph = this;
      handler = function(params) {
        var end, h, obj, start, _i, _len, _ref, _results;
        obj = this;
        if (type === 'select') {
          start = params.start, end = params.end;
          obj.evtData = graph.scaleSet.fromPixels(start, end);
        } else if (type === 'data') {
          obj.evtData = {};
        } else {
          obj.evtData = obj.data('e');
        }
        _ref = graph.handlers;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          h = _ref[_i];
          if (_.isFunction(h)) {
            _results.push(h(type, obj));
          } else {
            _results.push(h.handle(type, obj));
          }
        }
        return _results;
      };
      return _.throttle(handler, 1000);
    };

    Graph.prototype._makeLayers = function(spec) {
      return _.map(spec.layers, function(layerSpec) {
        return poly.layer.make(layerSpec, spec.strict);
      });
    };

    Graph.prototype._makeDomains = function(spec, layers) {
      if (spec.guides == null) spec.guides = {};
      return poly.domain.make(layers, spec.guides, spec.strict);
    };

    Graph.prototype._makeScaleSet = function(spec, domains) {
      var tmpRanges;
      this.coord.make(poly.dim.guess(spec));
      tmpRanges = this.coord.ranges();
      return poly.scale.make(tmpRanges, this.coord);
    };

    Graph.prototype._makeDimensions = function(spec, scaleSet) {
      return poly.dim.make(spec, scaleSet.makeAxes(), scaleSet.makeLegends());
    };

    Graph.prototype._makePaper = function(dom, width, height, handleEvent) {
      var paper;
      return paper = poly.paper(document.getElementById(dom), width, height, handleEvent);
    };

    Graph.prototype._legacy = function(domains) {
      var axes, k, v, _results;
      this.domains = domains;
      this.scales = this.scaleSet.scales;
      axes = this.scaleSet.makeAxes();
      this.ticks = {};
      _results = [];
      for (k in axes) {
        v = axes[k];
        _results.push(this.ticks[k] = v.ticks);
      }
      return _results;
    };

    return Graph;

  })();

  poly.chart = function(spec) {
    return new Graph(spec);
  };

  this.poly = poly;

}).call(this);
