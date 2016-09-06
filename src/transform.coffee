Matrix = require('./matrix').Matrix

sin = Math.sin
cos = Math.cos

proto = CanvasRenderingContext2D.prototype

_setTransform = proto.setTransform

_save = proto.save
_restore = proto.restore

proto._currentTransform = new Matrix
proto._tramsformStack = []

proto.save = ->
  _save.call this
  @_tramsformStack.push @_currentTransform

proto.restore = ->
  _restore.call this
  @setTransformWithMatrix @_tramsformStack.pop()

proto.setTransform = (a, b, c, d, e, f) ->
  _setTransform.call this, a, b, c, d, e, f
  @_currentTransform = new Matrix(a, b, c, d, e, f)

proto.setTransformWithMatrix = (m) ->
  _setTransform.call this, m.a, m.b, m.c, m.d, m.e, m.f
  @_currentTransform = m

proto.rotate = (angle) ->
  c = cos(angle)
  s = sin(angle)
  @transformWithMatrix new Matrix(c, s, -s, c, 0, 0)

proto.scale = (x, y) ->
  @transformWithMatrix new Matrix(x, 0, 0, y, 0, 0)

proto.translate = (x, y) ->
  @transformWithMatrix new Matrix(1, 0, 0, 1, x, y)

proto.transformWithMatrix = (m) ->
  @transform m.a, m.b, m.c, m.d, m.e, m.f

proto.transform = (a, b, c, d, e, f) ->
  m = new Matrix(a, b, c, d, e, f)
  m = @_currentTransform.multiply m
  @setTransformWithMatrix m

proto.getTransform = ->
  return @_currentTransform
