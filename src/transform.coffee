Matrix = require('./matrix').Matrix

sin = Math.sin
cos = Math.cos

proto = CanvasRenderingContext2D.prototype

hasCT = 'currentTransform' of proto
hasMozCT = 'mozCurrentTransform' of proto

if hasCT or hasMozCT
  proto.getTransform = do ->
    if hasCT isnt undefined
      return ->
        return @currentTransform
    else
      return ->
        return @mozCurrentTransform

else
  _rotate = proto.rotate
  _scale = proto.scale
  _setTransform = proto.setTransform
  _translate = proto.translate
  _transform = proto.transform

  proto.currentTransform = new Matrix

  proto.setTransform = (a, b, c, d, e, f) ->
    _setTransform.call this, a, b, c, d, e, f
    @currentTransform.set a, b, c, d, e, f
    return undefined

  proto.rotate = (angle) ->
    m = new Matrix(cos(angle), sin(angle), -sin(angle), cos(angle), 0, 0)
    @currentTransform = @currentTransform.multiply m
    _rotate.call this, angle
    return undefined

  proto.scale = (x, y) ->
    m = new Matrix(x, 0, 0, y, 0, 0)
    @currentTransform = @currentTransform.multiply m
    _scale.call this, x, y
    return undefined

  proto.translate = (x, y) ->
    m = new Matrix(0, 0, 0, 0, x, y)
    @currentTransform = @currentTransform.multiply m
    _translate.call this, x, y
    return undefined

  proto.transform = (a, b, c, d, e, f) ->
    m = new Matrix(a, b, c, d, e, f)
    @currentTransform = @currentTransform.multiply m
    _transform.call this, a, b, c, d, e, f
    return undefined

  proto.getTransform = ->
    return @currentTransform
