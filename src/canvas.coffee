Util = require('./util').Util
Stage = require('./stage').Stage
Event = require('./event').Event
EventProducer = require('./event').EventProducer

module.exports.Canvas = class Canvas
  @devicePixelRatio: window.devicePixelRatio
  @isHighDPI: @devicePixelRatio > 1

  constructor: (@raw)->
    if typeof @raw is 'string'
      @raw = Util.$one @raw

    if not @raw
      throw new Error('deformed dom')

    @ctx = @raw.getContext('2d');

    if @constructor.isHighDPI
      @enableHighDPI()

    @eventProducer = new EventProducer(this)

    @currentStage = null

    @disableSelect()
    @bindMouseEvent()

  enableHighDPI: ->
    w = @raw.width
    h = @raw.height

    @raw.width = w * @constructor.devicePixelRatio
    @raw.height = h * @constructor.devicePixelRatio
    @raw.style.width = w + 'px'
    @raw.style.height = h + 'px'

    @ctx.scale @constructor.devicePixelRatio, @constructor.devicePixelRatio

  disableSelect: ->
    @raw.style.webkitUserSelect = 'none'
    @raw.style.mozUserSelect = 'none'
    @raw.style.msUserSelect = 'none'
    @raw.style.userSelect = 'none'

  bindMouseEvent: ->
    @raw.addEventListener 'click', (evt) =>
      evt = new Event('click', evt)
      evt.x = evt.data.offsetX * @constructor.devicePixelRatio
      evt.y = evt.data.offsetY * @constructor.devicePixelRatio
      if evt.x >= 0 and evt.y >= 0
        @fire 'click', evt

  clear: ->
    @ctx.clearRect 0, 0, @raw.width, @raw.height
    debugger;

  newStage: ->
    stage = new Stage(this)
    return stage

  on: (event, listener) ->
    @eventProducer.on event, listener
    return this

  off: (event, listener) ->
    @eventProducer.off event, listener
    return this

  fire: (event, data) ->
    @eventProducer.fire event, data
    return this

  hasEvent: (event) ->
    return @eventProducer.has event
