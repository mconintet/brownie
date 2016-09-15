module.exports.Selection = class Selection
  @savedStack: []

  @save: ->
    sel = getSelection()
    saved = []
    for i in [0 ... sel.rangeCount]
      saved.push sel.getRangeAt i
    Selection.savedStack.push saved
    sel

  @restore: ->
    sel = getSelection()
    saved = @savedStack.pop()
    if saved
      sel.removeAllRanges()
      for range in saved
        sel.addRange range
    sel
