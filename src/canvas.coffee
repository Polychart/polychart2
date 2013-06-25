class PolyCanvas
  # Simulates paper element of Raphael
  constructor: (dom, w, h) ->
    if dom.getContext then @context = dom.getContext '2d'
    else throw poly.error.depn "Neither Raphael nor Canvas is available."

    dom.width = w
    dom.height = h

    @items = []
    @_counter = 0

  _makeItem: (type, params) ->
    id = @_newId()
    switch type
      when 'rect' then item = new PolyRect id, @, params
      when 'circle' then item = new PolyCirc id, @, params
      when 'path' then item = new PolyPath id, @, params
      when 'text' then item = new PolyText id, @, params
    @items[id] = item
    item

  _newId: () -> @_counter += 1

  rect: (args...) -> @_makeItem 'rect', args
  circle: (args...) ->  @_makeItem 'circle', args
  path: (args...) -> @_makeItem 'path', args
  text: (args...) -> @_makeItem 'text', args

  # TODO: Erase item
  remove: (id) ->
    item = @items[id]


class PolyCanvasItem
  constructor: (@id, @canvas, params) ->
    @context = @canvas.context
    @_resetContext()
    @attr params

  _setFont: (fontSize, fontFamily) ->
    if fontFamily?
      @context.font = "#{fontSize}px #{fontFamily}"
    else
      @context.font = "#{fontSize}px sans-serif"

  _resetContext: () ->
    @context.fillStyle = '#000000'
    @context.strokeStyle = '#000000'
    @context.globalAlpha = 1
    @context.lineWidth = 0.5

  # Sets the attr of some drawn thing
  attr: (args) ->
    if args.len == 1
      params = args[0]
      if params['stroke-width']? then @context.lineWidth = params['stroke-width']
      if params.stroke? then @context.strokeStyle = params.stroke
      if params.fill? then @context.fillStyle = params.fill
      if params.opacity? then @context.globalAlpha = params.opacity

      if params['font-size']? then @_setFont params['font-size'], params['font-family']
      if params['text-anchor']?
        anchor = params['text-anchor']
        switch anchor
          when 'left' then @context.textAlign = 'start'
          when 'middle' then @context.textAlign = 'center'
          when 'right' then @context.textAlign = 'right'
    else
      [key, val] = [args[0], args[1]]
      if val?
        switch key
          when 'fill' then @context.fillStyle = @_stringToHex val
          when 'opacity' then @context.globalAlpha = val
          when 'stroke' then @context.strokeStyle = @_stringToHex val
          when 'stoke-width' then @context.lineWidth = val

  _stringToHex: (colour) ->
    switch colour
      when 'black' then '#000000'
      when 'white' then '#ffffff'
      when 'steelblue' then '#4692B4'
      else colour

  _setProps: (args, props) ->
    if args.length == 1
      params = args[0]
      _.each props, (prop) =>
        if params[prop]? then @[prop] = params[prop]
    else
      [key, val] = [args[0], args[1]]
      _.each props, (prop) =>
        if key == prop and val? then @[prop] = val

  # TODO: Implement a scene tree type object
  remove: () -> @canvas.remove @id
  toBack: () -> undefined
  toFront: () -> undefined

  animate: () -> undefined

  click: (handler) -> undefined
  drag: (onmove, onstart, onend) -> undefined
  data: (type, handler) -> undefined
  hover: (handler) -> undefined

  touchstart: (handler) -> undefined
  touchend: (handler) -> undefined
  touchmove: (handler) -> undefined
  touchcancel: (handler) -> undefined

# Simulates paper.rect(x, y, w, h)
class PolyRect extends PolyCanvasItem
  attr: (args...) ->
    super(args)
    @_setProps args, ['x', 'y', 'width', 'height']
    @_draw()

  _draw: () ->
    @context.fillRect @x, @y, @width, @height
    @

# Simulates paper.circle(x, y, r)
class PolyCirc extends PolyCanvasItem
  attr: (args...) ->
    super(args)
    @_setProps args, ['x', 'y', 'r']
    @_draw()

  _draw: () ->
    @context.arc @cx, @cy, @r, 0, 2 * Math.PI, false
    @context.fill()
    @context.stroke()
    @

# Simulates paper.path([pathString])
class PolyPath extends PolyCanvasItem
  attr: (args...) ->
    super(args)
    @_setProps args, ['path']
    console.log args
    @_draw()

  _draw: () ->
    if @path?
      path = @path.split(' ')
      console.log path
      @context.beginPath()
      while path.length > 0
        chr = path.shift()
        switch chr
          when 'M'
            x = path.shift()
            y = path.shift()
            @context.moveTo x, y
          when 'L'
            x = path.shift()
            y = path.shift()
            @context.lineTo x, y
          when 'R'
            undefined
          when 'A'
            undefined
          when 'Z'
            @context.closePath()
          else throw poly.error.defn "Unknown line type!"
      @context.stroke()
    @

# Simulates paper.text(x, y, text)
class PolyText extends PolyCanvasItem
  attr: (args...) ->
    super(args)
    @_setProps args, ['x', 'y', 'text']
    @_draw()

  _draw: () ->
    if @text? then @context.fillText @text, @x, @y
    @

poly.canvas = (dom, w, h) -> new PolyCanvas dom, w, h
