Layer = require('../layer').Layer
$ = require('../dom').$
Util = require('../util').Util

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
    x = @frame.origin.x
    y = @frame.origin.y + textMetrics.actualBoundingBoxAscent + textMetrics.actualBoundingBoxDescent
    @ctx.fillTextFlexibly text, x, y, @frame.size.width

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

  getHandlerDom: ->
    if @handlerDom is null
      super()
      console.log @handlerDom
      text = @text
      text = @placeholder if @text is ''
      textarea = "<textarea>#{ text }</textarea>"
      textarea = $(@handlerDom).append textarea
      me = this
      $(textarea).css {
        width: '100%',
        height: '100%',
        padding: '0',
        border: '0'
      }
      .on 'blur', ->
        me.text =  Util.sTrim $(this).val()
        me.closeHandler()
    @handlerDom