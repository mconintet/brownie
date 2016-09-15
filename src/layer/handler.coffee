$ = require('../dom').$
Canvas = require('../canvas').Canvas
EventProducer = require('../event').EventProducer

module.exports.Handler = class Handler
  constructor: (@layer) ->
    @isOpen = false

    @_prepareContainer()
    @_prepareBtnMove()
    @_prepareBtnRotate()
    @_prepareBtnDelete()
    @_prepareBtnResize()

    @eventProducer = new EventProducer(this)

  _prepareContainer: ->
    div = "<div id='b-layer-handler-#{ @layer.id } b-layer-handler'>
<i class='fa fa-arrows move'></i>
<i class='fa fa-arrows-h resize'></i>
<i class='fa fa-repeat rotate'></i>
<i class='fa fa-trash-o delete'></i>
</div>"

    @container = $(@layer.stage.canvas.container.dom.append div)
    @container.css {
      display: 'none',
      width: @layer.frame.size.width + 'px',
      height: @layer.frame.size.height + 'px',
      backgroundColor: 'rgba(0,0,0,0.3)',
      position: 'absolute',
      border: '1px solid #000'
    }

  _prepareBtnMove: ->
    @btnMove = @container.find('i.move')
    @btnMove.css {
      position: 'absolute',
      fontSize: '14px',
      left: '-19px',
      top: '-12px',
      cursor: 'pointer',
      width: '20px',
      height: '20px',
      textAlign: 'center',
      lineHeight: '20px',
    }
    me = this
    @btnMove.on 'mousedown', (evt) =>
      @moveable = true
      @moveBegin = {
        left: me.container.css('left'),
        top: me.container.css('top')
      }
      @movePrevPoint = [evt.clientX, evt.clientY]
      @layer.backupAttr 'moveDelta'

    $(document).on 'mousemove', (evt) =>
      if @moveable
        prevPoint = @movePrevPoint
        dx = evt.clientX - prevPoint[0]
        dy = evt.clientY - prevPoint[1]
        left = me.container.css('left')
        top = me.container.css('top')
        ch = me.container.css('height')
        top = Math.max(top + dy, -ch / 2)
        @container.css {
          left: (left + dx) + 'px',
          top: top + 'px'
        }
        @movePrevPoint = [evt.clientX, evt.clientY]
        evt.preventDefault()

    $(document).on 'mouseup', =>
      if @moveable
        @moveable = false
        begin = @moveBegin
        left = @container.css('left')
        top = @container.css('top')
        dx = left - begin.left
        dy = top - begin.top
        @layer.move dx * Canvas.devicePixelRatio, dy * Canvas.devicePixelRatio
        @layer.backupAttr 'moveDelta'

  _prepareBtnDelete: ->
    @btnDelete = @container.find('i.delete')
    @btnDelete.css {
      position: 'absolute',
      fontSize: '15px',
      left: '-19px',
      bottom: '-12px',
      cursor: 'pointer',
      width: '20px',
      height: '20px',
      textAlign: 'center',
      lineHeight: '20px',
    }
    @btnDelete.on 'click', =>
      @close()
      @layer.removeFromSuperLayer()

  _prepareBtnRotate: ->
    @btnRotate = @container.find('i.rotate')
    @btnRotate.css {
      position: 'absolute',
      fontSize: '14px'
      right: '-20px',
      top: '-12px',
      cursor: 'pointer',
      width: '20px',
      height: '20px',
      textAlign: 'center',
      lineHeight: '20px',
    }

    @btnRotate.on 'mousedown', (evt) =>
      @rotate = 0
      @rotateBegin = {
        x: evt.clientX,
        y: evt.clientY
      }

      rect = @container.boundRect()
      cx = (rect.right - rect.left) / 2 + rect.left
      cy = (rect.bottom - rect.top) / 2 + rect.top
      @rotateCenter = [cx, cy]
      @rotatable = true
      @rotatePrev = 0
      @layer.backupAttr 'rotate'

    $(document).on 'mousemove', (evt) =>
      if @rotatable
        nx = evt.clientX
        ny = evt.clientY

        begin = @rotateBegin
        center = @rotateCenter

        a = begin.x - center[0]
        b = center[1] - begin.y
        d1 = Math.atan(b / a)

        a = Math.abs(nx - center[0])
        b = Math.abs(center[1] - ny)
        d2 = Math.atan(b / a)

        if nx > center[0] and ny <= center[1]
          d = d1 - d2
        else if nx > center[0] and ny > center[1]
          d = d1 + d2
        else if nx < center[0] and ny > center[1]
          d = Math.PI - d2 + d1
        else if nx < center[0] and ny < center[1]
          d = Math.PI + d1 + d2

        r = @container.css('transform')?.replace(/rotate|\(|\)|deg/g, '')
        r = 0 if r is ''
        r = parseFloat(r)
        nd = d * 180 / Math.PI
        d = nd - @rotatePrev
        @rotatePrev = nd
        @rotate = r + d
        @container.css 'transform', "rotate(#{ @rotate }deg)"
        evt.preventDefault()

    $(document).on 'mouseup', () =>
      if @rotatable
        @rotatable = false
        @layer.setRotate @rotate
        @layer.backupAttr 'rotate'

  _prepareBtnResize: ->
    @btnResize = @container.find('i.resize')
    @btnResize.css {
      position: 'absolute',
      fontSize: '14px',
      right: '-19px',
      bottom: '-12px',
      transform: 'rotate(44deg)',
      cursor: 'pointer',
      width: '20px',
      height: '20px',
      textAlign: 'center',
      lineHeight: '20px',
    }

    @btnResize.on 'mousedown', (evt) =>
      @resizeable = true
      @saleablePrev = [evt.clientX, evt.clientY]
      @layer.backupAttr 'frame'

    $(document).on 'mousemove', (evt) =>
      if @resizeable
        prev = @saleablePrev
        dx = evt.clientX - prev[0]
        dy = evt.clientY - prev[1]
        width = @container.css('width') + dx
        height = @container.css('height') + dy
        @container.css {
          width: width + 'px',
          height: height + 'px'
        }
        @saleablePrev = [evt.clientX, evt.clientY]
        evt.preventDefault()

    $(document).on 'mouseup', =>
      if @resizeable
        @resizeable = false
        nw = @container.css('width')
        nh = @container.css('height')
        @layer.resize nw, nh
        @layer.backupAttr 'frame'

  syncStyleWithLayer: ->
    width = @layer.frame.size.width
    height = @layer.frame.size.height
    top = @layer.byWindowPosition.y
    left = @layer.byWindowPosition.x

    # calc drawing size if border is set
    if @layer.borderWidth > 0
      width -= @layer.borderWidth
      height -= @layer.borderWidth
      top += @layer.borderWidth / 2
      left += @layer.borderWidth / 2

    # reposition since handler's border width is 1
    top -= 1
    left -= 1

    style = {
      width: width + 'px'
      height: height + 'px'
      transform: "rotate(#{ @layer.rotate }deg)"
      top: top + 'px'
      left: left + 'px'
    }
    @container.css(style)

  open: ->
    if @layer.parent is null or @isOpen
      return

    @fire 'beforeOpen'

    @layer.stage.focusingLayer = @layer

    @layer.syncByWindowPosition()
    @container.css {
      display: 'block'
    }
    @syncStyleWithLayer()
    @layer.setIsHidden true
    @isOpen = true

    me = this
    @_close = ->
      if me.isOpen
        me.close()
        me.layer.stage.canvas.off 'click', me._close

    @layer.stage.canvas.on 'click', @_close

    @fire 'afterOpen'

  close: ->
    if @layer.parent is null or not @isOpen
      return

    @fire 'beforeClose'

    if @_close
      @layer.stage.canvas.off 'click', @_close
    @layer.blur()
    @container.css 'display', 'none'
    @layer.setIsHidden false
    @isOpen = false

    @fire 'afterClose'

  destroy: ->
    c = @container.first()
    c.parentNode.removeChild c
    @container = null
    @layer = null

  on: (event, listener) ->
    @eventProducer.on event, listener

  once: (event, listener) ->
    @eventProducer.once event, listener

  off: (event, listener) ->
    @eventProducer.off event, listener

  fire: (event, data) ->
    @eventProducer.fire event, data
