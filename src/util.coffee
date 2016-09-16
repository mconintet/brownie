module.exports.Util = class Util
  @type: (obj) ->
    Object::toString.call obj

  @isString: (obj) ->
    typeof obj is 'string'

  @isObject: (obj) ->
    typeof obj is 'object' and obj isnt null

  @isArray: (obj) ->
    Array.isArray obj

  @toArray: (obj) ->
    Array::slice.call obj

  @aRemoveAt: (arr, index) ->
    arr.splice(index, 1)

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

  @oExtend: (dst, src) ->
    args = @toArray arguments
    target = args.shift()

    for arg in args
      if !arg
        continue

      for own k, v of arg
        if @isObject v
          if !target[k]
            target[k] = {}
          @oExtend target[k], v
        else if @isArray v
          if !target[k]
            target[k] = []
          v.forEach (v) ->
            target[k].push @oClone(v)
        else
          target[k] = v

    target

  @oGetByPath: (obj, path) ->
    parts = path.split '.'
    ret = obj
    for part in parts
      if ret?
        ret = ret[part]
      else
        break
    ret

  @oClone: (target) ->
    if @isObject target
      @oExtend {}, target
    else if @isArray target
      ret = []
      for v in target
        ret.push @clone(v)
      ret
    else
      target

  @sTrim: (str, sep = '\\s') ->
    str.replace(new RegExp('^' + sep + '+|' + sep + '+$', 'g'), '')

  @sTrimL: (str, sep = '\\s') ->
    str.replace(new RegExp('^' + sep + '+', 'g'), '')

  @sTrimR: (str, sep = '\\s') ->
    str.replace(new RegExp(sep + '+$', 'g'), '')

  @aEqual: (a, b) ->
    if @isArray(a) and @isArray(b)
      for i, v in a
        if v isnt b[i]
          return false
      true
    else
      a is b

  @oEqual: (a, b) ->
    if @isArray(a) and @isArray(b)
      @aEqual(a, b)
    else if typeof a is 'object' and typeof b is 'object'
      eq = true
      for own k, v of a
        eq = @oEqual(v, b[k])
        if not eq
          return false
      true
    else
      a is b

  @fOnceToken: do ->
    seed = 0
    ->
      seed++

  @fOnce: do ->
    pool = {}
    (token, fn) ->
      if pool[token] isnt true
        fn()
        pool[token] = true
