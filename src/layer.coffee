EventProducer = require('./event').EventProducer
Util = require('./util').Util
Rect = require('./rect').Rect
IndexGenerator = require('./index').IndexGenerator
Canvas = require('./canvas').Canvas
Point = require('./point').Point
Matrix = require('./matrix').Matrix
$ = require('./dom').$
pageXOffset = require('./dom').pageXOffset
pageYOffset = require('./dom').pageYOffset
Handler = require('./layer/handler').Handler

module.exports.Layer = class Layer
  @BORDER_DIRECTION:
    TOP: (1 << 0)
    RIGHT: 1 << 1
    BOTTOM: 1 << 2
    LEFT: 1 << 3
    ALL: 0b1111

  @indexGenerator: new IndexGenerator

  constructor: (x, y, width, height) ->
    @id = Layer.indexGenerator.auto()
    @drawingIndex = -1

    @zIndex = 0

    @byCanvasPosition = new Point
    @byWindowPosition = new Point

    @frame = new Rect(x, y, width, height)
    @bounds = new Rect(0, 0, width, height)

    @maskToBounds = true

    @rotate = 0

    @borderWidth = 0
    @borderColor = '#000'
    @borderDirection = Layer.BORDER_DIRECTION.ALL

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

    @draggable = false
    @moveable = false

    @moveDelta = new Point

    @isHidden = false

    @handler = null

    @handlerOpenTrigger = 'click'

  enableHandler: (enable = true) ->
    if enable
      @focusable = true if not @focusable
      @draggable = true if not @draggable

      if @handlerOpenTrigger is 'click'
        this.on 'click', @openHandler
      else if @handlerOpenTrigger is 'dblclick'
        this.on 'dblclick', @openHandler
    else
      if @handlerOpenTrigger is 'click'
        this.off 'click', @openHandler
      else if @handlerOpenTrigger is 'dblclick'
        this.off 'dblclick', @openHandler

  zIndexUp: ->
    @zIndex++
    @redraw()

  zIndexDown: ->
    if @zIndex is 0
      return
    @zIndex--
    @redraw()

  syncByWindowPosition: ->
    m = new Matrix()
    if @draggable
      m.e = @moveDelta.x
      m.f = @moveDelta.y
      if @parent?.capturedTransform?
        m = m.multiply @parent.capturedTransform
      else
        m = m.multiply @ctx.getTransform()
    else
      if @parent?.capturedTransform?
        m = @parent.capturedTransform

    @byWindowPosition.x = @byCanvasPosition.x + m.e / Canvas.devicePixelRatio
    @byWindowPosition.y = @byCanvasPosition.y + m.f / Canvas.devicePixelRatio

  getHandler: ->
    @handler = new Handler(this) if @handler is null
    @handler

  openHandler: ->
    @getHandler().open()

  closeHandler: ->
    @getHandler().close()

  backupAttr: (attr, newChanges = true) ->
    val = this[attr]
    if val?
      last = @stage.history.getLastChange()
      change = {
        id: @id,
        attr: attr,
        val: Util.clone(val)
      }
      if Util.oEqual last, change
        return

      if newChanges
        @stage.history.newChanges()

      changes = @stage.history.currentChanges()
      changes?.push change

  sync: (change) ->
    this[change['attr']] = change['val']

  focus: ->
    @stage.focusingLayer?.blur()
    @stage.focusingLayer = this
    @focusing = true
    @moveable = true
    if @draggable
      @backupAttr 'moveDelta'
      @stage.canvas.once 'mouseup', =>
        @moveable = false
        @backupAttr 'moveDelta'
    @redraw()

  blur: ->
    if @stage.focusingLayer is @
      @stage.focusingLayer = null
      @focusing = false
      @redraw()

  moveTo: (x, y) ->
    @moveDelta.x = x
    @moveDelta.y = y
    @redraw()

  move: (x = 0, y = 0) ->
    @moveDelta.x += x
    @moveDelta.y += y
    @redraw()

  moveLeft: (x = 1) ->
    @move -x, 0

  moveRight: (x = 1)->
    @move x, 0

  moveUp: (y = 1) ->
    @move 0, -y

  moveDown: (y = 1) ->
    @move 0, y

  _calculatePosition: ->
    if @parent isnt null and @parent instanceof Layer
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

  _applyTransform: ->
    if @draggable
      m = new Matrix()
      m.e = @moveDelta.x
      m.f = @moveDelta.y
      if @parent?.capturedTransform?
        m = m.multiply @parent.capturedTransform
      else
        m = m.multiply @ctx.getTransform()
    else
      if @parent?.capturedTransform?
        m = @parent.capturedTransform
    @ctx.setTransformWithMatrix m if m?

  captureTransform: ->
    @capturedTransform = @ctx.getTransform()

  _drawPredefined: ->
    @ctx.beginPath()

    @_applyTransform()

    @_calculatePosition()
    @_applyRotate()

    @captureTransform()

    @ctx.beginPath()

    @ctx.rect @byCanvasPosition.x, @byCanvasPosition.y, @frame.size.width, @frame.size.height

    if @backgroundColor
      @ctx.fillStyle = @backgroundColor
      @ctx.fill()

    if @borderWidth > 0
      @ctx.lineWidth = @borderWidth
      @ctx.strokeStyle = @borderColor
      @ctx.stroke()

    if @focusing and @useDefaultFocusStyle
      @ctx.shadowColor = "#1B93F1"
      @ctx.shadowBlur = 20 * Canvas.devicePixelRatio

    if @maskToBounds
      @ctx.clip()

    @ctx.closePath()

  drawing: ->

  draw: ->
    if @ctx is null
      return this

    @drawingIndex = @stage.drawingIndexGenerator.auto()

    @ctx.save()

    @_drawPredefined()
    @drawing()

    @ctx.restore()

    return this

  redraw: ->
    if @stage isnt null
      @stage.redraw()

  enableDragWithoutHandler: (enable = true) ->
    if enable
      @draggable = true if not @draggable
      @on 'mousedown', @focus
    else
      @off 'mousedown', @focus

  resize: (nw, nh) ->
    @frame.size.width = nw
    @frame.size.height = nh
    @redraw()

  bringToFront: ->
    @backupAttr 'zIndex'
    @zIndex = @stage.maxZIndex + 1
    @backupAttr 'zIndex'
    @redraw()

  removeFromSuperLayer: ->
    @capturedTransform = null
    if @parent isnt null
      if @parent instanceof Layer
        @parent.removeChild this
      else
        @parent.removeLayer this
    @handler?.destroy()
    @handler = null
    @redraw()

  setIsHidden: (@isHidden) ->
    @redraw()

  setZIndex: (@zIndex) ->
    @redraw()

  setRotate: (@rotate) ->
    @redraw()

  setBackgroundColor: (@backgroundColor) ->
    @redraw()

  setBorderWidth: (@borderWidth) ->
    @redraw()

  addChild: (child) ->
    child.parent = this
    @children.push child
    @redraw()

  addChildBefore: (child, before) ->
    child.parent = this
    Util.aInsertBefore @children, child, before
    @redraw()

  addChildAfter: (child, after) ->
    child.parent = this
    Util.aInsertAfter @children, child, after
    @redraw()

  removeChild: (child) ->
    child.parent = null
    Util.aRemoveEqual @children, child
    @redraw()

  clearChildren: () ->
    @children = []
    @redraw()

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

  once: (event, listener) ->
    @eventProducer.once event, listener

  off: (event, listener) ->
    @eventProducer.off event, listener

  fire: (event, data) ->
    @eventProducer.fire event, data

  hasEvent: (event) ->
    @eventProducer.has event

  listenersOf: (event) ->
    @eventProducer.listenersOf event
