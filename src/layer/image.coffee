Layer = require('../layer').Layer

_Image = window.Image

module.exports.Image = class Image extends Layer
  constructor: (x, y, width, height, @src = '', @sx = 0, @sy = 0, @sWidth = 0, @sHeight = 0) ->
    super(x, y, width, height)

    @image = new _Image()
    @image.crossOrigin = "anonymous"

    @image.onload = =>
      @onImageLoaded()

    @image.src = @src if @src isnt ''

    @imageLoaded = false;

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
    @src = src
    @image.src = @src

  setSrcSize: (@sx = 0, @sy = 0, @sWidth = 0, @sHeight = 0) ->
    @redraw() if @imageLoaded

  _drawPredefined: ->
    super()

    if @imageLoaded
      dx = @frame.origin.x
      dy = @frame.origin.y
      dWidth = @frame.size.width
      dHeight = @frame.size.height

      if @sWidth > 0 or @sHeight > 0
        @ctx.drawImage @image, @sx, @sy, @sWidth, @sHeight, dx, dy, dWidth, dHeight
      else
        @ctx.drawImage @image, dx, dy, dWidth, dHeight
