module.exports.Util = class Util
  @type: (obj) ->
    return Object::toString.call obj

  @isString: (obj) ->
    return typeof obj is 'string'

  @isObject: (obj) ->
    return typeof obj is 'object' and obj isnt null

  @isArray: (obj) ->
    return Array.isArray obj

  @toArray: (obj) ->
    return  Array::slice.call obj

  @$one: (selector) ->
    return document.querySelector(selector)

  @$all: (selector) ->
    return @toArray document.querySelectorAll(selector)

  @aRemoveEqual: (arr, eq) ->
    for item, i in arr
      if item is eq
        arr.splice i, 1
        return

  @aInsertAfter: (arr, stuff, after) ->
    for item, i in arr
      if item is after
        arr.splice i + 1, 0, stuff
        return

  @aInsertBefore: (arr, stuff, before) ->
    for item, i in arr
      if item is before
        arr.splice i, 0, stuff
        return
