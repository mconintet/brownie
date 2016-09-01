EventProducer = require('./event').EventProducer
Event = require('./event').Event

module.exports.Keycode = class Keycode
  @UP: 38
  @RIGHT 39
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

module.exports.KeyboardEventObserver = class KeyboardEventObserver

  constructor: ->
    @eventProducer = new EventProducer(this)

    document.addEventListener 'keypress', (evt) =>
      evt = new Event('keypress', evt)
      evt.keycode = new Keycode(evt.keyCode)
      @fire 'keypress', evt

    document.addEventListener 'keydown', (evt) =>
      evt = new Event('keydown', evt)
      evt.keycode = new Keycode(evt.keyCode)
      @fire 'keydown', evt

    document.addEventListener 'keyup', (evt) =>
      evt = new Event('keyup', evt)
      evt.keycode = new Keycode(evt.keyCode)
      @fire 'keyup', evt

  on: (event, listener) ->
    @eventProducer.on event, listener
    return this

  once: (event, listener) ->
    @eventProducer.once event, listener
    return this

  off: (event, listener) ->
    @eventProducer.off event, listener
    return this

  fire: (event, data) ->
    @eventProducer.fire event, data
    return this

module.exports.keyboardEventObserver = new KeyboardEventObserver
