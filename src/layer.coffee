EventProducer = require('./event').EventProducer
Util = require('./util').Util
Rect = require('./rect').Rect
IndexGenerator = require('./index').IndexGenerator
Canvas = require('./canvas').Canvas
Point = require('./point').Point

module.exports.Layer = class Layer
  @BORDER_DIRECTION:
    TOP: (1 << 0)
    RIGHT: 1 << 1
    BOTTOM: 1 << 2
    LEFT: 1 << 3
    ALL: 0b1111

  @indexGenerator: new IndexGenerator

  constructor: (x, y, width, height) ->
    @id = @constructor.indexGenerator.auto()
    @drawingIndex = -1

    @zIndex = 0

    @byCanvasPosition = new Point
    @byWindowPosition = new Point

    @frame = new Rect(x, y, width, height)
    @bounds = new Rect(0, 0, width, height)

    @maskToBounds = false

    @rotate = 0

    @borderWidth = 0
    @borderColor = '#000'
    @borderDirection = @constructor.BORDER_DIRECTION.ALL

    @borderSemiMinorAxes = 0
    @borderSemiMajorAxes = 0

    @backgroundColor = '#fff'

    @eventProducer = new EventProducer(this)

    @parent = null
    @children = []

    @stage = null
    @ctx = null

    @capturedTransform = null

    @focusable = false
    @useDefaultFocusStyle = true
    @focusing = false

    @dragable = false

    @moveDelta = new Point

  setupFocusableIfNeeded: ->
    if @focusable isnt false
      @on 'mousedown', @focus
      @on 'mouseup', @blur
    else
      @off 'mousedown', @focus

  focus: ->
    @stage.focusingLayer?.blur()
    @stage.focusingLayer = this
    @focusing = true
    @redraw()
    @stage.canvas.once 'mouseup', =>
      @blur()

  blur: ->
    @stage.focusingLayer = null
    @focusing = false
    @redraw()

  moveTo: (x, y) ->
    @moveDelta.x = x
    @moveDelta.y = y
    @redraw()

  move: (x = 0, y = 0) ->
    @moveDelta.x += x;
    @moveDelta.y += y;
    @redraw()

  moveLeft: (x = 1) ->
    @move -x, 0

  moveRight: (x = 1)->
    @move x, 0

  moveUp: (y = 1) ->
    @move 0, -y

  moveDown: (y = 1) ->
    @move 0, y

  _applyMoving: ->
    @ctx.translate @moveDelta.x, @moveDelta.y

  _calculatePosition: ->
    if @parent isnt null
      @byCanvasPosition.x = @parent.byCanvasPosition.x + @parent.bounds.origin.x + @frame.origin.x
      @byCanvasPosition.y = @parent.byCanvasPosition.y + @parent.bounds.origin.y + @frame.origin.y
    else
      @byCanvasPosition.x = @frame.origin.x
      @byCanvasPosition.y = @frame.origin.y

  _applyRotate: ->
    if @rotate isnt 0
      tx = @byCanvasPosition.x + @frame.size.width / 2
      ty = @byCanvasPosition.y + @frame.size.height / 2

      @ctx.translate tx, ty
      @ctx.rotate @rotate * Math.PI / 180
      @ctx.translate -tx, -ty

  _applyParentTransform: ->
    if @parent isnt null and @parent.capturedTransform isnt null
      @ctx.setTransformWithMatrix @parent.capturedTransform

  captureTransform: ->
    @capturedTransform = @ctx.getTransform()

  _drawPredefined: ->
    @ctx.beginPath()

    @_applyParentTransform()

    if @dragable
      @_applyMoving()

    @_calculatePosition()
    @_applyRotate()

    @captureTransform()

    @ctx.beginPath()

    @ctx.rect @byCanvasPosition.x, @byCanvasPosition.y, @frame.size.width, @frame.size.height

    if @borderWidth > 0
      @ctx.strokeStyle = @borderColor
      @ctx.stroke()

    if @focusing and @useDefaultFocusStyle
      @ctx.shadowColor = "#1B93F1"
      @ctx.shadowBlur = 20 * Canvas.devicePixelRatio

    @ctx.fillStyle = @backgroundColor
    @ctx.fill()

    @ctx.closePath()

  drawing: ->

  draw: ->
    if @ctx is null
      return this

    @drawingIndex = @stage.drawingIndexGenerator.auto()
    @setupFocusableIfNeeded()

    @ctx.save()

    @_drawPredefined()
    @drawing()

    @ctx.restore()

    return this

  redraw: ->
    if @stage isnt null
      @stage.redraw()

  setZIndex: (i) ->
    @zIndex = i
    @redraw()

  setRotate: (degree) ->
    @rotate = degree
    @redraw()

  setBackgroundColor: (color) ->
    @backgroundColor = color
    @redraw()

  setBorderWidth: (width) ->
    @borderWidth = width
    @redraw()

  addChild: (child) ->
    child.parent = this
    @children.push child
    @redraw()
    return this

  addChildBefore: (child, before) ->
    child.parent = this
    Util.aInsertBefore @children, child, before
    @redraw()
    return this

  addChildAfter: (child, after) ->
    child.parent = this
    Util.aInsertAfter @children, child, after
    @redraw()
    return this

  removeChild: (child) ->
    Util.aRemoveEqual @children, child
    @redraw()
    return this

  clearChildren: () ->
    @children = []
    @redraw()
    return this

  containPoint: (x, y) ->
    if @ctx is null
      return false

    @ctx.save()
    @ctx.setTransform @capturedTransform.a,
      @capturedTransform.b,
      @capturedTransform.c,
      @capturedTransform.d
      @capturedTransform.e,
      @capturedTransform.f

    @_calculatePosition()

    @ctx.beginPath()

    @ctx.rect @byCanvasPosition.x, @byCanvasPosition.y, @frame.size.width, @frame.size.height
    ret = @ctx.isPointInPath x, y

    @ctx.closePath()
    @ctx.restore()
    return ret

  on: (event, listener) ->
    @eventProducer.on event, listener
    return this

  once: (event, listener) ->
    @eventProducer.once event, listener
    return this

  off: (event, listener) ->
    @eventProducer.off event, listener
    return this

  fire: (event, data) ->
    @eventProducer.fire event, data
    return this

  hasEvent: (event) ->
    return @eventProducer.has event

  listenersOf: (event) ->
    return @eventProducer.listenersOf event
