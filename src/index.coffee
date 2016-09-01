module.exports.IndexGenerator = class IndexGenerator
  constructor: (@seed = 0) ->

  auto: ->
    return @seed++

  reset: (@seed = 0) ->
