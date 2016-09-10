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

  once: (event, listener) ->
    if typeof listener isnt 'function'
      return this

    listener.__fire_once__ = true
    @on event, listener

  has: (event) ->
    return @listeners[event]?.length > 0

  off: (event, listener) ->
    if listener is undefined
      @listeners[event] = []
    else
      ls = @listeners[event]
      if Util.isArray(ls)
        Util.aRemoveEqual ls, listener

    return this

  listenersOf: (event) ->
    return @listeners[event] ? []

  fire: (event, data) ->
    ls = @listeners[event]
    if ls is undefined
      return this

    once = []

    for listener in ls
      if typeof listener isnt 'function'
        continue
      stop = listener.call @context, data
      if listener.__fire_once__ is true
        once.push listener
      if stop is true
        break

    once.forEach (listener) ->
      listener.__fire_once__ = false
      Util.aRemoveEqual ls, listener

    return this
