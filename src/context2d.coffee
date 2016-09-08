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

proto.fillTextFlexibly = (text, x, y, maxWidth, lineHeight = 0) ->
  t = @measureText('t')
  fontHeight = t.actualBoundingBoxAscent + t.actualBoundingBoxDescent
  paddingVertical = 2
  if lineHeight < fontHeight
    lineHeight = fontHeight + paddingVertical * 2
  else
    paddingVertical = (lineHeight - fontHeight) / 2

  w = 0
  lines = []
  line = {
    x: x,
    y: y,
    str: []
  }
  y += paddingVertical

  i = 0
  len = text.length
  while i < len
    c = text[i]
    w += @measureText(c).width
    if c is '\r' or c is '\n'
      lines.push line if line.str.length > 0
      y += fontHeight + paddingVertical
      w = 0
      line = {
        x: x,
        y: y,
        str: []
      }
      if c is '\r' and text[i + 1] is '\n'
        i += 2
        continue
    else if w <= maxWidth
      line.str.push c
    else
      lines.push line if line.str.length > 0
      y += fontHeight + paddingVertical
      w = 0
      line = {
        x: x,
        y: y
        str: [c]
      }
    i++

  lines.push line if line.str.length > 0
  for line in lines
    @fillText line.str.join(''), line.x, line.y
