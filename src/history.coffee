EventProducer = require('./event').EventProducer
Util = require('./util').Util

module.exports.Element = class Element
  constructor: ->
    @changes = []

  push: (attr) ->
    @changes.push attr

  pop: ->
    @changes.pop()

  shift: ->
    @changes.shift()

  removeAt: (index) ->
    Util.aRemoveAt @changes, index

  forEach: (cb) ->
    for change in @changes
      cb(change)

module.exports.History = class History
  constructor: (@maxSize = 20) ->
    @stack = []
    @currentIndex = -1

    @eventProducer = new EventProducer(this)

  push: (element) ->
    if @stack.length is @maxSize
      @stack.shift()

    @stack.push element
    @forward false
    element

  forward: (fire = true) ->
    if @forwardable()
      @currentIndex++
      max = @stack.length - 1
      @currentIndex = max if @currentIndex > max
      @fire('forward') if fire

  back: (fire = true) ->
    if @backable()
      @currentIndex--
      @currentIndex = 0 if @currentIndex < 0
      @fire('back') if fire

  forwardable: ->
    @currentIndex < @stack.length - 1

  backable: ->
    @currentIndex > 0

  newElement: ->
    element = new Element()
    @push element

  currentElement: ->
    if @currentIndex is -1
      @newElement()
    else
      @stack[@currentIndex]

  on: (event, listener) ->
    @eventProducer.on event, listener

  once: (event, listener) ->
    @eventProducer.once event, listener

  off: (event, listener) ->
    @eventProducer.off event, listener

  fire: (event, data) ->
    @eventProducer.fire event, data
