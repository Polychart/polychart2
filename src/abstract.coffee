# Contains abstract classes
class Renderable
  render: () -> poly.error.impl()
  dispose: () -> poly.error.impl()

poly.Renderable = Renderable
