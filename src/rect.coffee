module.exports.Rect = class Rect
  constructor: (x = 0, y = 0, width = 0, height = 0) ->
    @origin =
      x: x
      y: y
    @size =
      width: width
      height: height