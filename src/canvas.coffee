Stage = require('./stage').Stage
Event = require('./event').Event
EventProducer = require('./event').EventProducer
TextLayer = require('./layer/text').Text

module.exports.Canvas = class Canvas
  @devicePixelRatio: window.devicePixelRatio ? 1
  @isHighDPI: @devicePixelRatio > 1

  constructor: (@raw)->
    if not @raw
      throw new Error('deformed dom')

    @cantainer = null

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

  toBlob: (type, encoderOptions) ->
    du = @raw.toDataURL type, encoderOptions
    data = du.split(',')[1]
    bs = atob(data)
    b = new ArrayBuffer(bs.length)
    bv = new Uint8Array(b)
    for c,i in bs
      bv[i] = bs.charCodeAt(i)
    new Blob([b], {type: 'image/octet-stream'})

  saveAs: (filename, type = 'png') ->
    if 'toBlob' of @raw
      @raw.toBlob (blob) ->
        saveAs(blob, filename + '.' + type)
    else
      Canvas2Image.saveAsImage(@raw, @raw.width, @raw.height, type)

  makeShadow: (rate) ->
    raw = document.createElement('canvas')
    raw.style.display = 'none'
    document.body.appendChild raw
    shadow = new Canvas(raw)

    rate = rate / Canvas.devicePixelRatio
    shadow.raw.width = @raw.width * rate
    shadow.raw.height = @raw.height * rate
    shadow.raw.style.width = shadow.raw.width + 'px'
    shadow.raw.style.height = shadow.raw.height + 'px'

    scale = Canvas.devicePixelRatio * rate
    shadow.ctx.setTransform(1, 0, 0, 1, 0, 0)
    shadow.ctx.scale scale, scale

    data = @currentStage.export false
    stage = shadow.newStage()
    stage.import data, false
    stage.walkLayers (layer) ->
      frame = layer.frame
      frame.origin.x *= rate
      frame.origin.y *= rate
      frame.size.width *= rate
      frame.size.height *= rate

      moveDelta = layer.moveDelta
      moveDelta.x *= rate
      moveDelta.y *= rate

      if layer instanceof TextLayer
        layer.fontSize = (parseInt(layer.fontSize) * rate) + 'px'

    {
      shadow: shadow
      stage: stage
    }

  destroyShadow: (shadow) ->
    document.body.removeChild shadow.raw

  capture: (rate = 1, type = 'png', cb, encoderOptions = null) ->
    {shadow, stage} = @makeShadow rate
    stage.redraw =>
      cb?(shadow.raw.toDataURL type, encoderOptions)
      @destroyShadow shadow

  captureAs: (rate = 1, filename, type) ->
    {shadow, stage} = @makeShadow rate
    stage.redraw =>
      shadow.saveAs filename, type
      @destroyShadow shadow
