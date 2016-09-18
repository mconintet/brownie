$ = require('./dom').$
Canvas = require('./canvas').Canvas

module.exports.Container = class Container
  constructor: (selector) ->
    dom = $(selector).first()
    if not dom?
      throw new Error("no dom with selector #{ selector }")

    @dom = $(dom).css {
      position: 'relative'
      overflow: 'hidden'
    }

    @_prepareCanvas()

  _prepareCanvas: ->
    dc = document.createElement('canvas')
    dc.width = @dom.css 'width'
    dc.height = @dom.css 'height'

    if dc.width is 0 or dc.height is 0
      rect = @dom.first().getBoundingClientRect()
      dc.width = rect.right - rect.left
      dc.height = rect.bottom - rect.top

    @dom.append dc
    @canvas = new Canvas(dc)
    @canvas.container = this