module.exports.Matrix = class Matrix
  @multiply: (a, b) ->
    new Matrix(
      a.a * b.a + a.c * b.b,
      a.b * b.a + a.d * b.b,
      a.a * b.c + a.c * b.d,
      a.b * b.c + a.d * b.d,
      a.a * b.e + a.c * b.f + a.e,
      a.b * b.e + a.d * b.f + a.f
    )

  constructor: (@a = 1, @b = 0, @c = 0, @d = 1, @e = 0, @f = 0) ->

  set: (@a = 1, @b = 0, @c = 0, @d = 1, @e = 0, @f = 0) ->

  multiply: (m) ->
    @constructor.multiply(this, m)

  toString: ->
    '[' + [@a, @b, @c, @d, @e, @f] + ']'

  scale: (sx, sy)->
    @multiply new Matrix(sx, 0, 0, sy, 0, 0)

  clone: ->
    m = new Matrix()
    m.a = @a
    m.b = @b
    m.c = @c
    m.d = @d
    m.e = @e
    m.f = @f
    m
