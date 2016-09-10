Util = require('./util').Util
IndexGenerator = require('./index').IndexGenerator
History = require('./history').History

module.exports.Stage = class Stage
  constructor: (@canvas) ->
    if not @canvas?
      throw new Error('must specify a canvas')

    @bindEvent()

    @layers = []

    @drawingIndexGenerator = new IndexGenerator

    @focusingLayer = null

    @history = new History

    @history.on 'forward', =>
      console.log 'forward'
      @handleHistoryChanged()

    @history.on 'back', =>
      @handleHistoryChanged()

    @maxZIndex = 0

  handleHistoryChanged: ->
    element = @history.currentChanges()
    element?.forEach (change) =>
      id = change['id']
      if id?
        layer = @getLayerById id
        layer.sync change
    @redraw() if element?

  addLayer: (layer) ->
    layer.parent = this
    @layers.push layer
    @redraw()

  addLayerBefore: (layer, before) ->
    layer.parent = this
    Util.aInsertBefore @layers, layer, before
    @redraw()

  addLayerAfter: (layer, after) ->
    layer.parent = this
    Util.aInsertAfter @layers, layer, after
    @redraw()

  removeLayer: (layer) ->
    layer.parent = null
    Util.aRemoveEqual @layers, layer
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
    @_walkLayers @layers, cb, skipHidden

  getLayerById: (id) ->
    found = null
    @walkLayers (layer) ->
      if layer.id is id
        found = layer
        return true
    found

  broadcastMouseEvent: (evt) ->
    fulfilled = []
    @walkLayers (layer) ->
      if not layer.isHidden and layer.containPoint evt.x, evt.y
        fulfilled.push layer

    fulfilled.sort (a, b) ->
      return b.drawingIndex - a.drawingIndex

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
    @drawingIndexGenerator.reset()
    @_draw()
    return this
