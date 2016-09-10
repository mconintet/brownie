IndexGenerator = require('./index').IndexGenerator

indexer = new IndexGenerator

module.exports.$ = (selector) ->
  if typeof selector is 'string'
    new Result(document.querySelectorAll(selector))
  else
    new Result([selector])

tmpDiv = document.createElement 'div'

module.exports.Result = class Result
  constructor: (@nodeList) ->

  get: (i) ->
    @nodeList[i]

  each: (cb) ->
    for node in @nodeList
      cb(node)
    this

  on: (event, cb) ->
    @each (node) ->
      node.addEventListener event, cb

  off: (event, cb) ->
    @each (node) ->
      node.removeEventListener event, cb

  append: (stuff) ->
    if typeof stuff is 'string'
      tmpDiv.innerHTML = stuff
      if !tmpDiv.hasChildNodes()
        return
      stuff = tmpDiv.childNodes[0]

    @each (node) ->
      node.appendChild stuff
    stuff

  boundRect: ->
    @nodeList[0]?.getBoundingClientRect()

  css: (k, v) ->
    if typeof k is 'string'
      if v isnt undefined
        @each (node) ->
          node.style[k] = v
      else
        v = @nodeList[0]?.style[k]?.replace(/(px|pt)$/, '')
        if /^[0-9.]+$/.test v
          return parseInt v
        v
    else if typeof k is 'object'
      @each (node) ->
        for own key,val of k
          node.style[key] = val

  data: do ->
    store = {}
    (k, v) ->
      node = @nodeList[0]
      if node
        id = node.dataset.__store_id__
        if id is undefined
          node.dataset.__store_id__ = indexer.auto()

        if store[id] is undefined
          store[id] = {}

        if v is undefined
          store[id][k] ? node.dataset[k]
        else
          store[id][k] = v

  val: (text) ->
    if text isnt undefined
      @each (node) ->
        node.value = text
    else
      @nodeList[0]?.value

  find: (selector) ->
    found = []
    @each (node) ->
      for n in node.querySelectorAll(selector)
        found.push n
    new Result(found)