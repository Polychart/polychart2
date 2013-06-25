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
    @callback = callback
    @prepare = prepare
    @make(spec)

  make: (spec) ->
    # checking
    if not spec.value
      throw poly.error.defn "No value defined in numeral."

    @spec = toStrictMode(spec)
    ps = new poly.DataProcess(@spec, [], @spec.strict, poly.parser.numeralToData)
    ps.make @spec, [], @render

  handleEvent : (type) =>

  render: (err, statData, metaData) =>
    @value = statData[0][@spec.value.var]
    @title = @spec.title ? @spec.value.var
    # formatting the value (temporary)
    degree =
      if 0 < @value < 1      then undefined
      else if @value % 1 == 0 then 0
      else                        -1
    @value = poly.format.number(degree)(@value)
    # pre-preparation process
    if @prepare then @prepare @
    # prepare the dom
    @dom = @spec.dom
    @width = @spec.width ? 200
    @height = @spec.height ? 100
    @paper ?= @_makePaper @dom, @width, @height, @
    # rendering the title
    @titleObj ?= @paper.text(@width/2, 10,  '')
    @titleObj.attr text: @title, 'font-size':'12px'
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

  _makePaper: (dom, width, height, handleEvent) ->
    paper = poly.paper dom, width, height, handleEvent


poly.numeral = (spec, callback, prepare) -> new Numeral(spec, callback, prepare)
