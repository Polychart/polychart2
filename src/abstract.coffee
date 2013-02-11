###
Abstract Classes
---------
Abstract classes, almost used like interfaces throughout the codebase
###
class Renderable
  render: () -> poly.error.impl()
  dispose: () -> poly.error.impl()

class Guide extends Renderable
  getDimension: () -> throw poly.error.impl()

class GuideSet extends Renderable
  getDimension: () -> throw poly.error.impl()
  make: () -> throw poly.error.impl()

###
This should probably be in its own class folder, and should technically
be named "Renderable", but whatever. It manages what is currently on the
screen, and what needs to be rendered.
  @geoms : a key-value pair of an identifier to a group of objects to be
           rendered. It should be of the following form:
            @geoms = {
              'id' : {
                marks: {
                  # an assoc array of renderable "marks", acceptable by 
                  # poly.render() function
                },
                evtData: {
                  # data bound to a click/mouseover/mouseout event
                  # on the marks plotted
                },
                tooltip: # tooltip text to show on mouseover
              }
            }
  @pts   : a key-value pair of identfier to a group of objects rendered.
           the group of objects is also a key-value pair, corresponding
           to the key-value pair provided by `marks` as above.
###
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
      try
        objs[id2] =
          if points[id2]
            renderer.animate points[id2], mark, geom.evtData, geom.tooltip
          else
            renderer.add mark, geom.evtData, geom.tooltip
      catch error
        if error.name is 'MissingData'
          console.log error.message
        else
          throw error
    objs
  _add: (renderer, geom) ->
    objs = {}
    for id2, mark of geom.marks
      try
        objs[id2] = renderer.add mark, geom.evtData, geom.tooltip
      catch error
        if error.name is 'MissingData'
          console.log error.message
        else
          throw error
    objs
  dispose: (renderer) =>
    for id, pt of @pts
      @_delete renderer, pt
    @pts = {}

poly.Renderable = Renderable
poly.Guide = Guide
poly.GuideSet = GuideSet
poly.Geometry = Geometry
