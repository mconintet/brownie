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

    listeners = @listeners[event]
    if listeners is undefined
      listeners = @listeners[event] = []

    if listeners.indexOf(listener) is -1
      listeners.push(listener)

    return this

  has: (event) ->
    return @listeners[event]?.length > 0

  off: (event, listener) ->
    if listener is undefined
      @listeners[event] = []
    else
      Util.aRemoveEqual(@listener[event], listener)

    return this

  listenersOf: (event) ->
    listeners = @listeners[event]
    return listeners ? []

  fire: (event, data) ->
    listeners = @listeners[event]
    if listeners is undefined
      return this

    for listener in listeners
      listener.call @context, data
    return this
