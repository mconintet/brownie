$ = require('../dom').$
Canvas = require('../canvas').Canvas

module.exports.Handler = class Handler
  constructor: (@layer) ->
    @_prepareContainer()
    @_prepareBtnMove()
    @_prepareBtnRotate()
    @_prepareBtnDelete()
    @_prepareBtnResize()

  _prepareContainer: ->
    div = "<div id='b-layer-handler-#{ @id } b-layer-handler'>
<i class='fa fa-arrows move'></i>
<i class='fa fa-arrows-h resize'></i>
<i class='fa fa-repeat rotate'></i>
<i class='fa fa-trash-o delete'></i>
</div>"
    @container = $($(document.body).append div)
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
      left: '-17px',
      top: '-12px',
      cursor: 'pointer'
    }
    me = this
    @btnMove.on 'mousedown', (evt) =>
      @moveable = true
      @moveBegin = {
        left: me.container.css('left'),
        top: me.container.css('top')
      }
      @movePrevPoint = [evt.clientX, evt.clientY]

    $(document).on 'mousemove', (evt) =>
      if @moveable
        prevPoint = @movePrevPoint
        dx = evt.clientX - prevPoint[0]
        dy = evt.clientY - prevPoint[1]
        left = me.container.css('left')
        top = me.container.css('top')
        @container.css {
          left: (left + dx) + 'px',
          top: (top + dy) + 'px'
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

  _prepareBtnDelete: ->
    @btnDelete = @container.find('i.delete')
    @btnDelete.css {
      position: 'absolute',
      fontSize: '14px',
      left: '-17px',
      bottom: '-12px',
      cursor: 'pointer'
    }
    @btnDelete.on 'click', =>
      @close()
      @layer.removeFromSuperLayer()

  _prepareBtnRotate: ->
    @btnRotate = @container.find('i.rotate')
    @btnRotate.css {
      position: 'absolute',
      fontSize: '14px'
      right: '-16px',
      top: '-12px',
      cursor: 'pointer'
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

  _prepareBtnResize: ->
    @btnResize = @container.find('i.resize')
    @btnResize.css {
      position: 'absolute',
      fontSize: '14px',
      right: '-17px',
      bottom: '-9px',
      transform: 'rotate(44deg)',
      cursor: 'pointer'
    }

    @btnResize.on 'mousedown', (evt) =>
      @resizeable = true
      @saleablePrev = [evt.clientX, evt.clientY]

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

  open: ->
    if @layer.parent is null
      return
    @layer.syncByWindowPosition()
    @container.css {
      display: 'block',
      top: @layer.byWindowPosition.y + 'px',
      left: @layer.byWindowPosition.x + 'px',
    }
    @layer.setIsHidden true

  close: ->
    if @layer.parent is null
      return
    @container.css 'display', 'none'
    @layer.setIsHidden false

  destroy: ->
    document.body.removeChild @container.get(0)
    @container = null
    @layer = null