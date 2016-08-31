module.exports.Matrix = class Matrix
  @multiply: (a, b) ->
    return new Matrix(
      a.a * b.a + a.c * b.b,
      a.b * b.a + a.d * b.b,
      a.a * b.c + a.c * b.b,
      a.b * b.c + a.d * b.d,
      a.a * b.e + a.c * b.f + a.e,
      a.b * b.e + a.d * b.f + a.f
    )

  constructor: (@a = 1, @b = 0, @c = 0, @d = 1, @e = 0, @f = 0) ->

  set: (@a = 1, @b = 0, @c = 0, @d = 1, @e = 0, @f = 0) ->

  multiply: (m) ->
    return @constructor.multiply(this, m)
