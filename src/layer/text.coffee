Layer = require('../layer').Layer
$ = require('../dom').$
Util = require('../util').Util
Selection = require('../selection').Selection

module.exports.Text = class Text extends Layer

  constructor: (x, y, width, height, @placeholder = 'please input text', @text = '') ->
    super(x, y, width, height)

    @fontFamily = 'serif'
    @fontSize = '12px'
    @textColor = '#000'

    @backgroundColor = null

    @textChanged = false

  execCmdOnAllTextareaChildren: (cmd, arg) ->
    Selection.save()
    document.execCommand cmd, false, arg
    Selection.restore()

  syncHandlerFontSize: ->
    @execCmdOnAllTextareaChildren 'fontSize', 7
    $(@textarea).find('font[size]').removeAttr('size').css {
      fontSize: @fontSize
      verticalAlign: 'top'
    }

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

  setText: (text) ->
    if text is @text
      return

    @backupAttr 'text'
    @text = text
    @backupAttr 'text'
    @redraw()

  setPlaceholder: (placeholder) ->
    if placeholder is @placeholder
      return

    @placeholder = placeholder
    @redraw()

  setFontFamily: (fontFamily) ->
    if fontFamily is @fontFamily
      return

    @backupAttr 'fontFamily'
    @fontFamily = fontFamily
    @backupAttr 'fontFamily'

    if @getHandler().isOpen
      @syncHandlerFontFamily()

    @redraw()

  setFontSize: (fontSize) ->
    if fontSize is @fontSize
      return

    @backupAttr 'fontSize'
    @fontSize = fontSize
    @backupAttr 'fontSize'

    if @getHandler().isOpen
      @syncHandlerFontSize()

    @redraw()

  setTextColor: (textColor)->
    if textColor is @textColor
      return

    @backupAttr 'textColor'
    @textColor = textColor
    @backupAttr 'textColor'

    if @getHandler().isOpen
      @syncHandlerTextColor()

    @redraw()

  syncHandlerText: ->
    text = @text
    text = @placeholder if text is ''
    @textarea.innerHTML = "<div>#{ text }</div>"

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
          me.backupAttr 'text'
          me.text = Util.sTrimR this.innerText
          me.backupAttr 'text'
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
    @ctx.fillTextFlexibly text, x, y, maxWidth, @fontSize, @fontFamily
