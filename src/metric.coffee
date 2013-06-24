##
# "Meric" Object And Entry Point: poly.metric()
# ------------------------------------------
# This produces a single value
##

toStrictMode = (spec) ->
  if _.isString spec.value
    spec.value = {var: spec.value}
  spec

class Metric
  constructor: (spec, callback, prepare) ->
    if not spec?
      throw poly.error.defn "No metric specification is passed in!"
    @callback = callback
    @prepare = prepare
    @make(spec)

  make: (spec) ->
    # checking
    if not spec.value
      throw poly.error.defn "No value defined in metric."

    @spec = toStrictMode(spec)
    ps = new poly.DataProcess(@spec, [], @spec.strict, poly.parser.metricToData)
    ps.make @spec, [], @render

  handleEvent : (type) =>

  render: (err, statData, metaData) =>
    @value = statData[0][@spec.value.var]

    # formatting (temporary)
    @value =
      if 0 < @value < 1
        poly.format.number(false)(@value)
      else if @value % 1 == 0
        poly.format.number(0)(@value)
      else
        poly.format.number(-1)(@value)

    if @prepare then @prepare @

    @dom = @spec.dom
    @width = @spec.width ? 200
    @height = @spec.height ? 100
    @paper ?= @_makePaper @dom, @width, @height, @

    # make a filler object; this makes rendering & re-rendering consistent
    @textObj ?= @paper.text(@width/2, @height/2,  '')
    # update the object to the correct value & position
    @textObj.attr
      x: @width/2
      y: @height/2
      text: @value
    # now resize the object to take up 80% of the space
    {width, height} = @textObj.getBBox()
    scale = Math.min(@width*0.8/width, @height*0.8/height)
    @textObj.transform "s#{scale}"

    if @callback then @callback null, @

  _makePaper: (dom, width, height, handleEvent) ->
    paper = poly.paper dom, width, height, handleEvent


poly.metric = (spec, callback, prepare) -> new Metric(spec, callback, prepare)
