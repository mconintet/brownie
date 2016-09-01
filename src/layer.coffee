EventProducer = require('./event').EventProducer
Util = require('./util').Util
Rect = require('./rect').Rect
IndexGenerator = require('./index').IndexGenerator
Canvas = require('./canvas').Canvas

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

    @positionX = 0
    @positionY = 0

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

    @editable = false
    @useEditingStyle = true
    @editing = false

  _applyEditingStyle: ->
    if @useEditingStyle
      @redraw()

  beginEdit: ->
    if @stage.currentEditingLayer isnt null
      @stage.currentEditingLayer.endEdit()
    @stage.currentEditingLayer = this
    @editing = true
    @_applyEditingStyle()

  endEdit: ->
    @stage.currentEditingLayer = null
    @editing = false
    @redraw()

  moveTo: (x, y) ->
    @frame.origin.x = x
    @frame.origin.y = y
    @redraw()

  move: (x, y) ->
    @frame.origin.x += x
    @frame.origin.y += y
    @redraw()

  enableEditIfNeeded: ->
    if @editable isnt false
      @on 'click', @beginEdit
    else
      @off 'click', @beginEdit

  _calculatePosition: ->
    if @parent isnt null
      @positionX = @parent.positionX + @parent.bounds.origin.x + @frame.origin.x
      @positionY = @parent.positionY + @parent.bounds.origin.y + @frame.origin.y
    else
      @positionX = @frame.origin.x
      @positionY = @frame.origin.y

  _applyRotate: ->
    if @rotate isnt 0
      tx = @positionX + @frame.size.width / 2
      ty = @positionY + @frame.size.height / 2

      @ctx.translate tx, ty
      @ctx.rotate @rotate * Math.PI / 180
      @ctx.translate -tx, -ty

  _applyParentTransform: ->
    if @parent isnt null and @parent.capturedTransform isnt null
      @ctx.setTransform @parent.capturedTransform.a,
        @parent.capturedTransform.b,
        @parent.capturedTransform.c,
        @parent.capturedTransform.d,
        @parent.capturedTransform.e,
        @parent.capturedTransform.f

  _drawPredefined: ->
    @ctx.beginPath()

    @_applyParentTransform()

    @_calculatePosition()
    @_applyRotate()

    @capturedTransform = @ctx.getTransform()

    @ctx.beginPath()

    @ctx.rect @positionX, @positionY, @frame.size.width, @frame.size.height

    if @borderWidth > 0
      @ctx.strokeStyle = @borderColor
      @ctx.stroke()

    if @editing and @useEditingStyle
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
    @enableEditIfNeeded()

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

    @ctx.rect @positionX, @positionY, @frame.size.width, @frame.size.height
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
