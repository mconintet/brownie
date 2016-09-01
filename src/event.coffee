Util = require('./util').Util

module.exports.Event = class Event
  constructor: (@name, @data) ->

module.exports.EventProducer = class EventProducer
  constructor: (context) ->
    @context = context
    @listeners = {}

  on: (event, listener) ->
    if typeof listener isnt 'function'
      return this

    ls = @listeners[event]
    if ls is undefined
      ls = @listeners[event] = []

    if ls.indexOf(listener) is -1
      ls.push listener

    return this

  has: (event) ->
    return @listeners[event]?.length > 0

  off: (event, listener) ->
    if listener is undefined
      @listeners[event] = []
    else
      Util.aRemoveEqual @listeners[event], listener

    return this

  listenersOf: (event) ->
    return @listeners[event] ? []

  fire: (event, data) ->
    ls = @listeners[event]
    if ls is undefined
      return this

    for listener in ls
      listener.call @context, data
    return this
