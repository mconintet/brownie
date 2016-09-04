Point = require('./point').Point

module.exports.Rect = class Rect
  constructor: (x = 0, y = 0, width = 0, height = 0) ->
    @origin = new Point(x, y)
    @size =
      width: width
      height: height