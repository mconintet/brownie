module.exports.IndexGenerator = class IndexGenerator
  constructor: (@seed = new Date().getTime()) ->

  auto: ->
    return @seed++

  reset: (@seed = new Date().getTime()) ->
