module.exports.$ = (selector) ->
  if typeof selector is 'string'
    new Result(document.querySelectorAll(selector))
  else
    new Result([selector])

tmpDiv = document.createElement 'div'

module.exports.Result = class Result
  constructor: (@nodeList) ->

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
        @nodeList[0]?.style[k]
    else if typeof k is 'object'
      @each (node) ->
        for own key,val of k
          node.style[key] = val

  val: (text) ->
    if text isnt undefined
      @each (node) ->
        node.value = text
    else
      @nodeList[0]?.value
