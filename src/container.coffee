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

    @dom.append dc
    @canvas = new Canvas(dc)
    @canvas.container = this