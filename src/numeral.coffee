##
# "Meric" Object And Entry Point: poly.numeral()
# ------------------------------------------
# This produces a single value
##

toStrictMode = (spec) ->
  if _.isString spec.value
    spec.value = {var: spec.value}
  spec

class Numeral
  constructor: (spec, callback, prepare) ->
    if not spec?
      throw poly.error.defn "No numeral specification is passed in!"
    @handlers = []
    @callback = callback
    @prepare = prepare
    @make(spec)

  make: (spec) ->
    # checking
    if not spec.value
      throw poly.error.defn "No value defined in numeral."

    @spec = toStrictMode(spec)
    ps = new poly.DataProcess(@spec, [], @spec.strict, poly.spec.numeralToData)
    ps.make @spec, [], @render

  handleEvent: (type) =>
    numeral = @
    handler = (event) ->
      if type is 'guide-title'
        event = poly.event.make type, @
        event.dispatch numeral.dom
      for h in numeral.handlers
        if _.isFunction(h)
          h(type, @, event, numeral)
        else
          h.handle(type, @, event, numeral)
    _.throttle handler, 300

  addHandler: (h) -> if h not in @handlers then @handlers.push h

  render: (err, statData, metaData) =>
    if err?
      console.error err
      return
    name = poly.parser.normalize @spec.value.var
    @value = statData[0][name]
    @title = @spec.title ? name
    # formatting the value (temporary)
    degree =
      if 0 < @value < 1       then undefined
      else if @value % 1 == 0 then 0
      else                        -1
    @value = poly.format.number(degree)(@value)
    if _.isNaN(@value) or @value is 'NaN' then @value = "Not a Number"

    if @prepare? then @prepare @
    @dom    = @spec.dom
    @width  = @spec.width  ? 200
    @height = @spec.height ? 100
    @paper ?= @_makePaper @dom, @width, @height, @

    @titleObj ?= @paper.text(@width/2, 10,  '')
    @titleObj.attr text: @title, 'font-size':'12px'

    @titleObj.click @handleEvent('guide-title')
    @titleObj.hover @handleEvent('tover'), @handleEvent('tout')

    # actually render the text --
    # first make a filler object; this makes rendering & re-rendering consistent
    @textObj ?= @paper.text(@width/2, @height/2,  '')
    # update the object to the correct value & position
    @textObj.attr
      x: @width/2
      y: 7+@height/2 # =(@height-20)/2 + 14  # -- i.e. push down by 20px
      text: @value
    # now resize the object to take up 80% of the space
    {width, height} = @textObj.getBBox()
    scale = Math.min(@width*0.9/width, (@height-14)*0.9/height)
    @textObj.transform "s#{scale}"

    if @callback then @callback null, @
    return

  _makePaper: (dom, width, height, numeral) ->
    paper = poly.paper dom, width, height, {numeral}, false

poly.numeral = (spec, callback, prepare) ->
  try
    new Numeral(spec, callback, prepare)
  catch err
    console.log err
    if callback? then callback err, null
    else throw poly.error.defn "Bad specification."
