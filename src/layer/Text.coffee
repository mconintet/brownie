Layer = require('../layer').Layer

module.exports.Text = class Text extends Layer

  constructor: (x, y, width, height, @placeholder = 'please input text', @text = '') ->
    super(x, y, width, height)

    @fontFamily = 'serif'
    @fontSize = '12px'
    @textColor = '#000'

  _drawPredefined: ->
    super()

    text = @text
    text = @placeholder if text is ''

    @ctx.font = @fontSize + ' ' + @fontFamily
    @ctx.fillStyle = @textColor

    textMetrics = @ctx.measureText(text)
    x = @frame.origin.x + textMetrics.actualBoundingBoxLeft
    y = @frame.origin.y + textMetrics.actualBoundingBoxAscent + textMetrics.actualBoundingBoxDescent
    @ctx.fillText text, x, y

  setText: (text) ->
    if text is @text
      return

    @text = text
    @redraw()

  setPlaceholder: (placeholder) ->
    if placeholder is @placeholder
      return

    @placeholder = placeholder
    @redraw()

  setFontFamily: (fontFamily) ->
    if fontFamily is @fontFamily
      return

    @fontFamily = fontFamily
    @redraw()

  setTextColor: (textColor)->
    if textColor is @textColor
      return

    @textColor = textColor
    @redraw()
