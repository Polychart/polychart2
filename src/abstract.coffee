###
Abstract Classes
---------
Abstract classes, almost used like interfaces throughout the codebase
###
class Renderable
  render: () -> poly.error.impl()
  dispose: () -> poly.error.impl()

poly.Renderable = Renderable
