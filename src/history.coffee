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
      @currentIndex = 0 if @currentIndex < 0
      @fire('forward') if fire
      @currentIndex++

  back: (fire = true) ->
    if @backable()
      max = @stack.length - 1
      @currentIndex = max if @currentIndex > max
      @fire('back') if fire
      @currentIndex--

  forwardable: ->
    @currentIndex < @stack.length

  backable: ->
    @currentIndex > -1

  newChanges: ->
    changes = new Changes()
    @push changes
    @currentIndex = @stack.length - 1
    changes

  currentChanges: ->
    @stack[@currentIndex]

  on: (event, listener) ->
    @eventProducer.on event, listener

  once: (event, listener) ->
    @eventProducer.once event, listener

  off: (event, listener) ->
    @eventProducer.off event, listener

  fire: (event, data) ->
    @eventProducer.fire event, data
