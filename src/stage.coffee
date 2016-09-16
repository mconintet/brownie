Util = require('./util').Util
IndexGenerator = require('./index').IndexGenerator
History = require('./history').History

module.exports.Stage = class Stage
  constructor: (@canvas) ->
    if not @canvas?
      throw new Error('must specify a canvas')

    @bindEvent()

    @layers = []

    @indexGenerator = new IndexGenerator

    @focusingLayer = null

    @history = new History

    @history.on 'forward', =>
      @handleHistoryChanged()

    @history.on 'back', =>
      @handleHistoryChanged false

    @maxZIndex = 0

  handleHistoryChanged: (forward = true) ->
    changes = @history.currentChanges()
    changes?.forEach (change) =>
      action = change['action']
      if action
        switch action
          when 'add'
            if forward
              @addLayer change['layer'], false
            else
              @removeLayer change['layer'], false
          when 'del'
            if forward
              @removeLayer change['layer'], false
            else
              @addLayer change['layer'], false
      else
        id = change['id']
        if id?
          layer = @getLayerById id
          layer.closeHandler()
          layer.syncChange change, forward
          @redraw()

  _backupAdding: (layer) ->
    change = {
      action: 'add',
      layer: layer
    }
    changes = @history.newChanges()
    changes.push change

  _backupRemoving: (layer) ->
    change = {
      action: 'del',
      layer: layer
    }
    changes = @history.newChanges()
    changes.push change

  addLayer: (layer, history = true) ->
    layer.parent = this
    @layers.push layer
    if history
      @_backupAdding layer
    @redraw()

  addLayerBefore: (layer, before) ->
    layer.parent = this
    Util.aInsertBefore @layers, layer, before
    @redraw()

  addLayerAfter: (layer, after) ->
    layer.parent = this
    Util.aInsertAfter @layers, layer, after
    @redraw()

  removeLayer: (layer, history = true) ->
    layer.parent = null
    Util.aRemoveEqual @layers, layer
    if history
      @_backupRemoving layer
    @redraw()

  clearLayers: ->
    @layers = []
    @redraw()

  closeLayerHandler: ->
    @focusingLayer?.closeHandler()

  bindEvent: ->
    @canvas.on 'mousedown', (evt) =>
      @broadcastMouseEvent evt

    @canvas.on 'mouseup', (evt) =>
      @broadcastMouseEvent evt

    @canvas.on 'click', (evt) =>
      @broadcastMouseEvent evt

    @canvas.on 'dblclick', (evt) =>
      @broadcastMouseEvent evt

  _walkLayers: (layers, cb, depth = 0, skipHidden = true) ->
    if depth > 100
      return

    for layer in layers
      if layer.isHidden and skipHidden
        continue

      if cb(layer, depth) is true
        break

      if layer.children.length > 0
        @_walkLayers layer.children, cb, depth++, skipHidden

  walkLayers: (cb, skipHidden = true) ->
    @_walkLayers @layers, cb, 0, skipHidden

  getLayerById: (id) ->
    found = null
    @walkLayers (layer) ->
      if layer.id is id
        found = layer
        return true
    , false
    found

  broadcastMouseEvent: (evt) ->
    fulfilled = []
    fulfilledZIndexed = []
    @walkLayers (layer) ->
      if not layer.isHidden and layer.containPoint evt.x, evt.y
        if layer.zIndex is 0
          fulfilled.push layer
        else
          fulfilledZIndexed.push layer

    fulfilled.sort (a, b) ->
      b.addedIndex - a.addedIndex

    fulfilledZIndexed.sort (a, b) ->
      b.zIndex - a.zIndex

    fulfilled = fulfilledZIndexed.concat fulfilled
    fulfilled.every (layer) ->
      listeners = layer.listenersOf evt.name
      bubbling = false
      listeners.forEach (listener) ->
        bubbling = listener.call layer, evt.name, evt
      bubbling is true
    false

  _draw: ->
    zIndexed = []
    @walkLayers (layer) =>
      layer.stage = this
      layer.addedIndex = @indexGenerator.auto() if layer.addedIndex is -1
      layer.ctx = @canvas.ctx
      if layer.zIndex > 0
        zIndexed.push layer
      else
        layer.draw()

    if zIndexed.length > 0
      zIndexed.sort (a, b) ->
        return a.zIndex - b.zIndex

      zIndexed.forEach (layer) ->
        layer.draw()

      @maxZIndex = zIndexed[zIndexed.length - 1].zIndex

  redraw: ->
    @canvas.clear()
    @canvas.currentStage = this
    @_draw()
    return this

  focusingLayerIs: (cls, cb) ->
    if @focusingLayer and @focusingLayer instanceof cls
      cb @focusingLayer
