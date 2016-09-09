EventProducer = require('./event').EventProducer
Util = require('./util').Util

module.exports.Changes = class Changes
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

  push: (changes) ->
    if @stack.length is @maxSize
      @stack.shift()

    @stack.push changes
    @forward false
    changes

  getLastChange: ->
    len = @stack.length
    if len > 0
      ls = @stack[len - 1]
      if ls
        len = ls.changes.length
        return ls.changes[len - 1] if len > 0

  forward: (fire = true) ->
    if @forwardable()
      @currentIndex++
      max = @stack.length - 1
      @currentIndex = max if @currentIndex > max
      console.log @stack
      @fire('forward') if fire

  back: (fire = true) ->
    if @backable()
      @currentIndex--
      @currentIndex = 0 if @currentIndex < 0
      console.log @stack
      @fire('back') if fire

  forwardable: ->
    @currentIndex < @stack.length - 1

  backable: ->
    @currentIndex > 0

  newChanges: ->
    changes = new Changes()
    @push changes
    @currentIndex = @stack.length - 1

  currentChanges: ->
    if @currentIndex is -1
      @newChanges()
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
