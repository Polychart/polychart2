###
Abstract Classes
---------
Abstract classes, almost used like interfaces throughout the codebase
###
class Renderable
  render: () -> poly.error.impl()
  dispose: () -> poly.error.impl()

class Geometry extends Renderable
  constructor: () ->
    @geoms = {}
    @pts = {}
  set: (geoms) ->
    @geoms = geoms
  render: (renderer) ->
    newpts = {}
    {deleted, kept, added} = poly.compare _.keys(@pts), _.keys(@geoms)
    for id in deleted
      @_delete renderer, @pts[id]
    for id in added
      newpts[id] = @_add renderer, @geoms[id]
    for id in kept
      newpts[id] = @_modify renderer, @pts[id], @geoms[id]
    @pts = newpts
  _delete : (renderer, points) ->
    for id2, pt of points
      renderer.remove pt
  _modify: (renderer, points, geom) ->
    objs = {}
    for id2, mark of geom.marks
      objs[id2] = renderer.animate points[id2], mark, geom.evtData, geom.tooltip
    objs
  _add: (renderer, geom) ->
    objs = {}
    for id2, mark of geom.marks
      objs[id2] = renderer.add mark, geom.evtData, geom.tooltip
    objs
  dispose: (renderer) =>
    for id, pt of @pts
      @_delete renderer, pt
    @pts = {}

poly.Renderable = Renderable
poly.Geometry = Geometry
