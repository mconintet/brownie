EventProducer = require('./event').EventProducer
Event = require('./event').Event

module.exports.Code = class Code
  @UP: 38
  @RIGHT: 39
  @BOTTOM: 40
  @LEFT: 37

  constructor: (@code) ->

  isUp: ->
    @code is @constructor.UP

  isRight: ->
    @code is @constructor.RIGHT

  isBottom: ->
    @code is @constructor.BOTTOM

  isLeft: ->
    @code is @constructor.LEFT

module.exports.EventObserver = class EventObserver

  constructor: ->
    @eventProducer = new EventProducer(this)

    document.addEventListener 'keypress', (evt) =>
      evt = new Event('keypress', evt)
      evt.code = new Code(evt.data.keyCode)
      @fire 'keypress', evt

    document.addEventListener 'keydown', (evt) =>
      evt = new Event('keydown', evt)
      evt.code = new Code(evt.data.keyCode)
      @fire 'keydown', evt

    document.addEventListener 'keyup', (evt) =>
      evt = new Event('keyup', evt)
      evt.code = new Code(evt.data.keyCode)
      @fire 'keyup', evt

  on: (event, listener) ->
    if event in ['arrow']
      @on 'keydown', listener
    else
      @eventProducer.on event, listener

  once: (event, listener) ->
    @eventProducer.once event, listener

  off: (event, listener) ->
    @eventProducer.off event, listener

  fire: (event, data) ->
    @eventProducer.fire event, data

module.exports.eventObserver = new EventObserver
