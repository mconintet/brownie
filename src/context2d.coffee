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

_calcDiv = document.createElement('div')
_calcDiv.style.position = 'absolute'
_calcDiv.style.left = '-1000px'
_calcDiv.style.top = '-1000px'
_calcDiv.style.padding = 0
document.body.appendChild _calcDiv

proto.measureText = (text, fontSize = '10px', fontFamily = 'sans-serif') ->
  _calcDiv.style.fontSize = fontSize
  _calcDiv.style.fontFamily = fontFamily
  _calcDiv.innerText = text
  rect = _calcDiv.getBoundingClientRect()
  {
    width: rect.right - rect.left
    height: rect.bottom - rect.top
  }

proto.fillTextFlexibly = (text, x, y, maxWidth, fontSize, fontFamily, textAlign = 'left', lineHeight = 0) ->
  t = @measureText('t', fontSize, fontFamily)
  th = t.height

  paddingVertical = 0
  if lineHeight > 0
    paddingVertical = (lineHeight - th) / 2

  w = 0
  y += paddingVertical

  lines = []
  line = {
    x: x
    y: y
    w: w
    str: ''
  }

  for c, i in text
    if c is '\r' or c is '\n'
      lines.push line if line.str isnt ''
      y += th + paddingVertical
      w = 0
      line = {
        x: x
        y: y
        w: w
        str: ''
      }
      continue

    str = line.str + c
    mw = @measureText(str, fontSize, fontFamily).width
    if mw <= maxWidth
      line.str = str
      line.w = mw
    else
      lines.push line
      y += th + paddingVertical
      line = {
        x: x
        y: y
        w: w
        str: c
      }
      w = 0

  lines.push line if line.str isnt ''

  for line in lines
    switch textAlign
      when 'center'
        line.x += (maxWidth - line.w) / 2
      when 'right'
        line.x += maxWidth - line.w

    @fillText line.str, line.x, line.y
