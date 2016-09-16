Layer = require('../layer').Layer
$ = require('../dom').$
addCssRule = require('../dom').addCssRule
Util = require('../util').Util
Selection = require('../selection').Selection
Util = require('../util').Util

_addRuleOnceToken = Util.fOnceToken()

module.exports.Text = class Text extends Layer

  constructor: (x, y, width, height, @placeholder = 'please input text', @text = '') ->
    super(x, y, width, height)

    @fontFamily = 'serif'
    @fontSize = '12px'
    @textColor = '#000'
    @textAlign = 'left'

    @backgroundColor = null

    @textChanged = false

    Util.fOnce _addRuleOnceToken, @_addCssRule

  _addCssRule: ->
    addCssRule '.b-layer-handler .editable * { font: inherit }'

  execCmdOnAllTextareaChildren: (cmd, arg) ->
    sel = Selection.save()
    sel.removeAllRanges()
    range = document.createRange()
    range.selectNodeContents @textarea
    sel.addRange range
    document.execCommand cmd, false, arg
    Selection.restore()

  syncHandlerFontSize: ->
    @execCmdOnAllTextareaChildren 'fontSize', 7
    p = {
      fontSize: @fontSize
      verticalAlign: 'top'
    }
    $(@textarea).css p
    $(@textarea).find('font[size]').removeAttr('size').css p

  syncHandlerFontFamily: ->
    @execCmdOnAllTextareaChildren 'fontSize', 7
    $(@textarea).find('font[size]').removeAttr('size').css {
      fontFamily: @fontFamily
      verticalAlign: 'top'
    }

  syncHandlerTextColor: ->
    @execCmdOnAllTextareaChildren 'fontSize', 7
    $(@textarea).find('font[size]').removeAttr('size').css {
      color: @textColor
    }

  syncHandlerTextAlign: ->
    $(@textarea).css {
      textAlign: @textAlign
    }

  setText: (text) ->
    if text is @text
      return

    @text = @backupAttr 'text', text

    if @getHandler().isOpen
      @syncHandlerText()

    @redraw()

  setPlaceholder: (placeholder) ->
    if placeholder is @placeholder
      return

    @placeholder = placeholder
    @redraw()

  setFontFamily: (fontFamily) ->
    if fontFamily is @fontFamily
      return

    @fontFamily = @backupAttr 'fontFamily', fontFamily

    if @getHandler().isOpen
      @syncHandlerFontFamily()

    @redraw()

  setFontSize: (fontSize) ->
    if fontSize is @fontSize
      return

    @fontSize = @backupAttr 'fontSize', fontSize

    if @getHandler().isOpen
      @syncHandlerFontSize()

    @redraw()

  setTextColor: (textColor)->
    if textColor is @textColor
      return

    @textColor = @backupAttr 'textColor', textColor

    if @getHandler().isOpen
      @syncHandlerTextColor()

    @redraw()

  setTextAlign: (align) ->
    if align is @textAlign
      return

    @textAlign = @backupAttr 'textAlign', align

    if @getHandler().isOpen
      @syncHandlerTextAlign()

    @redraw()

  syncHandlerText: ->
    text = @text
    text = @placeholder if text is ''
    @textarea.innerText = text

  getHandler: ->
    if @handler is null
      super()
      textarea = "<div class='editable' contenteditable='true'></div>"
      textarea = @handler.container.append textarea
      @textarea = textarea
      me = this
      $(textarea).css {
        width: '100%'
        height: '100%'
        padding: '0'
        border: '0'
        outline: 'none'
        wordBreak: 'break-all'
      }
      .on 'blur', ->
        if me.textChanged
          me.text = me.backupAttr 'text', Util.sTrimR this.innerText
      .on 'keyup', ->
        me.textChanged = true

      @handler.on 'beforeOpen', =>
        @syncHandlerText()
        $(textarea).css {
          fontSize: @fontSize
          fontFamily: @fontFamily
          color: @textColor
          overflow: @maskToBounds && 'hidden' || 'auto'
        }

      @handler.on 'afterOpen', =>
        textarea.focus()
        if @text is ''
          @textChanged = false
          range = document.createRange()
          range.selectNodeContents textarea.firstChild
          sel = getSelection()
          sel.removeAllRanges()
          sel.addRange range
        else
          sel = getSelection()
          sel.removeAllRanges()
          range = document.createRange()
          range.selectNodeContents @textarea
          range.collapse false
          sel.addRange range

    @handler

  _drawPredefined: ->
    super()

    text = @text
    text = @placeholder if text is ''

    @ctx.font = @fontSize + ' ' + @fontFamily
    @ctx.fillStyle = @textColor

    x = @byCanvasPosition.x
    y = @byCanvasPosition.y + @ctx.measureText('t', @fontSize, @fontFamily).height
    @ctx.textBaseline = 'bottom'
    maxWidth = @frame.size.width
    if @borderWidth > 0
      x += @borderWidth / 2
      y += @borderWidth / 2
      maxWidth -= @borderWidth
    @ctx.fillTextFlexibly text, x, y, maxWidth, @fontSize, @fontFamily, @textAlign
