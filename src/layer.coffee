EventProducer = require('./event').EventProducer
Util = require('./util').Util
Rect = require('./rect').Rect

module.exports.Layer = class Layer
  @BORDER_DIRECTION:
    TOP: (1 << 0)
    RIGHT: 1 << 1
    BOTTOM: 1 << 2
    LEFT: 1 << 3
    ALL: 0b1111

  constructor: (x, y, width, height) ->
    @id = -1

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

    @backgroundColor = null

    @eventProducer = new EventProducer(this)

    @parent = null;
    @children = [];

    @stage = null;
    @ctx = null;

    @capturedTransform = null;

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

  _drawPredefined: ->
    @ctx.beginPath()

    @_calculatePosition()
    @_applyRotate()

    @capturedTransform = @ctx.getTransform()

    @ctx.beginPath()

    @ctx.rect @positionX, @positionY, @frame.size.width, @frame.size.height

    if @backgroundColor isnt null
      @ctx.fillStyle = @backgroundColor
      @ctx.fill()

    if @borderWidth > 0
      @ctx.strokeStyle = @borderColor
      @ctx.stroke()

    @ctx.closePath()

  _drawChildren: ->
    for child in @children
      child.stage = @stage
      child.ctx = @ctx
      child.draw()

  drawing: ->

  draw: ->
    if @ctx is null
      return this

    @id = @stage.idGenerator.id()

    @ctx.save()

    @_drawPredefined()
    @drawing()

    @_drawChildren()

    @ctx.restore()
    return this

  redraw: ->
    if @stage isnt null
      @stage.redraw()

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

    @ctx.beginPath();

    @ctx.rect @positionX, @positionY, @frame.size.width, @frame.size.height
    ret = @ctx.isPointInPath x, y

    @ctx.closePath()
    @ctx.restore()
    return ret

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

  listenersOf: (event) ->
    return @eventProducer.listenersOf event
