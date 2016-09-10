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

    @ctx = @raw.getContext '2d'

    if @constructor.isHighDPI
      @enableHighDPI()

    @eventProducer = new EventProducer(this)

    @currentStage = null

    @disableSelect()
    @bindMouseEvent()

    @mousemovePrevPoint = [0, 0]

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

  _prepareEvent: (raw, eventName) ->
    evt = new Event(eventName, raw)
    evt.x = raw.offsetX * @constructor.devicePixelRatio
    evt.y = raw.offsetY * @constructor.devicePixelRatio
    return evt

  bindMouseEvent: ->
    @raw.addEventListener 'dblclick', (evt) =>
      evt = @_prepareEvent evt, 'dblclick'
      if evt.x >= 0 and evt.y >= 0
        @fire 'dblclick', evt

    @raw.addEventListener 'mousedown', (evt) =>
      @mousemoveDelta = [0, 0]

      evt = @_prepareEvent evt, 'mousedown'
      if evt.x >= 0 and evt.y >= 0
        @fire 'mousedown', evt

    @raw.addEventListener 'mousemove', (evt) =>
      evt = @_prepareEvent evt, 'mousemove'
      [x, y] = @mousemovePrevPoint
      x = evt.x - x
      y = evt.y - y

      @mousemovePrevPoint = [evt.x, evt.y]

      if @currentStage?.focusingLayer?.moveable
        @_moveLayer x, y

    @raw.addEventListener 'mouseup', (evt) =>
      evt = @_prepareEvent evt, 'mouseup'
      if evt.x >= 0 and evt.y >= 0
        @fire 'mouseup', evt

    @raw.addEventListener 'click', (evt) =>
      evt = @_prepareEvent evt, 'click'
      if evt.x >= 0 and evt.y >= 0
        @fire 'click', evt

  _moveLayer: (x, y) ->
    @currentStage.focusingLayer.move x, y

  resetTransform: ->
    @ctx.setTransform @constructor.devicePixelRatio,
      0, 0, @constructor.devicePixelRatio, 0, 0

  clear: ->
    @ctx.clearRect 0, 0, @raw.width, @raw.height
    @resetTransform()

  newStage: ->
    new Stage(this)

  on: (event, listener) ->
    @eventProducer.on event, listener

  once: (event, listener) ->
    @eventProducer.once event, listener

  off: (event, listener) ->
    @eventProducer.off event, listener

  fire: (event, data) ->
    @eventProducer.fire event, data

  listenersOf: (event) ->
    @eventProducer.listenersOf event

  hasEvent: (event) ->
    @eventProducer.has event
