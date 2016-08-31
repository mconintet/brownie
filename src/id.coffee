module.exports.IDGenerator = class IDGenerator
  constructor: (@seed = 0) ->

  id: ->
    return @seed++

  reset: (@seed = 0) ->
