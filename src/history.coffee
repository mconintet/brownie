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
      @fire('forward') if fire

  back: (fire = true) ->
    if @backable()
      @fire('back') if fire
      @currentIndex--

  forwardable: ->
    @currentIndex isnt @stack.length - 1

  backable: ->
    @currentIndex isnt -1

  newChanges: ->
    changes = new Changes()
    @push changes
    @currentIndex = @stack.length - 1
    changes

  currentChanges: ->
    @stack[@currentIndex]

  clear: ->
    @stack = []

  on: (event, listener) ->
    @eventProducer.on event, listener

  once: (event, listener) ->
    @eventProducer.once event, listener

  off: (event, listener) ->
    @eventProducer.off event, listener

  fire: (event, data) ->
    @eventProducer.fire event, data
