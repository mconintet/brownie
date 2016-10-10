EventProducer = require('./event').EventProducer
Util = require('./util').Util
Rect = require('./rect').Rect
IndexGenerator = require('./index').IndexGenerator
Canvas = require('./canvas').Canvas
Point = require('./point').Point
Matrix = require('./matrix').Matrix
Handler = require('./layer/handler').Handler

module.exports.Layer = class Layer
  @indexGenerator: new IndexGenerator

  constructor: (x, y, width, height) ->
    @class = 'brownie.Layer'

    @id = Layer.indexGenerator.auto()
    @addedIndex = -1

    @zIndex = 0

    @byCanvasPosition = new Point
    @byWindowPosition = new Point

    @frame = new Rect(x, y, width, height)
    @bounds = new Rect(x, y, width, height)

    @maskToBounds = true

    @rotate = 0

    @borderWidth = 0
    @borderColor = '#000'

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
    @handlerEnable = false
    @handlerOpenTrigger = 'click'

  exportableProperties: ->
    [
      'class',
      'zIndex',
      'frame',
      'maskToBounds',
      'rotate',
      'borderWidth',
      'borderColor',
      'backgroundColor',
      'focusable',
      'useDefaultFocusStyle',
      'draggable',
      'moveDelta',
      'handlerEnable',
      'handlerOpenTrigger'
    ]

  export: ->
    ret = {
      children: []
    }
    ps = @exportableProperties()
    for p in ps
      ret[p] = Util.oClone this[p]
    for layer in @children
      ret.children.push layer.export()
    ret

  importReplace: ->
    {
      'children': (v) ->
        ret = []
        for lp in v
          cls = Util.oGetByPath window, v['class']
          layer = new cls
          ret.push(layer.import v, false)
        ret
      'handlerEnable': (v) =>
        @enableHandler()
        v
    }

  import: (data, jsonString = true) ->
    data = JSON.parse(data) if jsonString
    for own k,v of data
      rp = @importReplace()[k]
      if rp?
        this[k] = rp(v)
      else
        this[k] = v
    this

  applyCaptureRate: (rate) ->
    @frame.origin.x *= rate
    @frame.origin.y *= rate
    @frame.size.width *= rate
    @frame.size.height *= rate

    @moveDelta.x *= rate
    @moveDelta.y *= rate

  enableHandler: (@handlerEnable = true) ->
    if @handlerEnable
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

  backupAttr: (attr, newVal, newChanges = true) ->
    val = this[attr]
    if val isnt undefined
      change = {
        id: @id,
        attr: attr,
        old: Util.oClone val
        new: Util.oClone newVal
      }

      if newChanges
        @stage.history.newChanges()

      changes = @stage.history.currentChanges()
      changes?.push change
    newVal

  syncChange: (change, forward = true) ->
    if forward
      this[change['attr']] = change['new']
    else
      this[change['attr']] = change['old']

  focus: ->
    @stage.focusingLayer?.blur()
    @stage.focusingLayer = this
    @focusing = true
    @moveable = true
    if @draggable
      @stage.canvas.once 'mouseup', =>
        @moveable = @backupAttr 'moveDelta', false
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
      m = m.multiply @ctx.getTransform()
    else
      if @parent?.capturedTransform?
        m = @parent.capturedTransform
    @ctx.setTransformWithMatrix m if m?

  captureTransform: ->
    @capturedTransform = @ctx.getTransform()

  _drawPredefined: ->

    if @maskToBounds
      @applyParentMask()

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

    @ctx.closePath()

  drawing: ->

  applyParentMask: ->
    p = @parent
    if p? and p.byCanvasPosition?
      t = @ctx.getTransform().clone()
      @ctx.setTransformWithMatrix p.capturedTransform
      @ctx.rect p.byCanvasPosition.x, p.byCanvasPosition.y, p.frame.size.width, p.frame.size.height
      @ctx.clip()
      @ctx.setTransformWithMatrix t

  draw: (fire = true) ->
    if @ctx is null
      return this

    @ctx.save()

    @_drawPredefined()

    @drawing()

    @ctx.restore()

    @fireDrew() if fire
    return this

  fireDrew: ->
    @fire 'afterDraw'

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
    @zIndex = @backupAttr 'zIndex', @stage.maxZIndex + 1
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
