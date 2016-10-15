Layer = require('../layer').Layer
$ = require('../dom').$
Agent = require('../agent').Agent
Url = require('../url').Url

_Image = window.Image

module.exports.Image = class Image extends Layer
  constructor: (x, y, width, height, @src = '', @sx = 0, @sy = 0, @sWidth = 0, @sHeight = 0) ->
    super(x, y, width, height)

    @class = 'brownie.ImageLayer'

    @image = new _Image()
    @image.crossOrigin = "anonymous"

    @image.onload = =>
      @onImageLoaded()

    @image.src = @preventSrcFromCache(@src) if @src isnt ''

    @imageLoaded = false

    @backgroundColor = null

    @autoFireAfterDraw = false

  preventSrcFromCache: (src) ->
    if !Url.regOnline.test(src)
      lo = window.location
      host = lo.protocol + '//' + lo.host
      if src[0] is '/'
        src = host + src
      else
        src = host + lo.pathname + '/' + src
    url = Url.parse src
    url.search['_ec'] = new Date().getTime()
    url + ''

  exportableProperties: ->
    super().concat [
      'src',
      'sx',
      'sy',
      'sWidth',
      'sHeight'
    ]

  importReplace: ->
    rp = super()
    rp['src'] = (v) =>
      @setSrc v
    rp

  onImageLoaded: ->
    @imageLoaded = true
    @redraw()

  setImage: (@image) ->
    @imageLoaded = false
    if image.complete
      @onImageLoaded()
    else
      @image.onload = =>
        @onImageLoaded()

  setSrc: (src) ->
    if src is @src
      return
    @src = @preventSrcFromCache(src)
    @image.src = @src

  setSrcSize: (@sx = 0, @sy = 0, @sWidth = 0, @sHeight = 0) ->
    @redraw() if @imageLoaded

  draw: ->
    super(false)

  _drawPredefined: ->
    super()

    if @imageLoaded
      dx = @byCanvasPosition.x
      dy = @byCanvasPosition.y
      dWidth = @frame.size.width
      dHeight = @frame.size.height

      if @borderWidth > 0
        dx += @borderWidth
        dy += @borderWidth
        dWidth -= @borderWidth * 2
        dHeight -= @borderWidth * 2

      if @sWidth > 0 or @sHeight > 0
        @ctx.drawImage @image, @sx, @sy, @sWidth, @sHeight, dx, dy, dWidth, dHeight
      else
        @ctx.drawImage @image, dx, dy, dWidth, dHeight

      @fireDrew()

  getHandler: ->
    if @handler is null
      super()

      img = "<img src='#{ @src }' width='100%' height='100%' />"
      img = @handler.container.append img

      rm = 'crisp-edges'
      if Agent.isFF
        rm = '-moz-crisp-edges'
      else if Agent.isWebkit
        rm = '-webkit-optimize-contrast'

      $(img).css {
        imageRendering: rm
        msInterpolationMode: 'nearest-neighbor'
      }

      @handler.on 'beforeOpen', =>
        img.src = @src

    @handler
