module.exports.Url = class Url
  @regOnline: /^((ftp|http|https):)\/\/([a-zA-Z0-9.-]+)(:(\d+))?(\/[^?#]*)?(\?([^#]*))?(#(.*))?$/
  @regOffline: /^file:\/\/([^?#]+)?(\?([^#]*))?(#(.*))?/

  constructor: ->
    @protocol = ''
    @host = ''
    @port = ''
    @path = ''
    @search = {}
    @hash = ''

  toString: ->
    @protocol + '//' + @host +
      (if @port isnt '' then ':' + @port else '') +
      (if @path isnt '' then '/' + @path else '') +
      (if Object.keys(@search).length > 0 then '?' + Url.buildSearch(@search) else '') +
      (if @hash isnt '' then '#' + @hash else '')

  @parse: (str) ->
    url = new Url()
    if Url.regOnline.test(str)
      str.replace Url.regOnline, ->
        url.protocol = arguments[1]
        url.host = arguments[3]
        url.port = arguments[5] ? ''
        url.path = arguments[6] ? ''
        url.search = arguments[7] ? ''
        url.hash = arguments[9] ? ''
        url.search = url.search.slice(1)
        url.search = Url.parseSearch(url.search)

    else if Url.regOffline.test(str)
      str.replace Url.regOffline, ->
        url.protocol = 'file:'
        url.path = arguments[1] ? ''
        url.hash = arguments[4] ? ''
        url.search = arguments[2] ? ''
        url.search = url.search.slice(1)
        url.search = Url.parseSearch(url.search)
    url

  @parseSearch: (search) ->
    ret = {}
    for kv in search.split('&')
      [k,v] = kv.split(',')
      if k? and v?
        ret[decodeURIComponent(k)] = decodeURIComponent(v)
    ret

  @buildSearch: (search) ->
    ret = []
    for own k,v of search
      ret.push encodeURIComponent(k) + '=' + encodeURIComponent(v)
    ret.join '&'