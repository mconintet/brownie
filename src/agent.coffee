tmpDiv = document.createElement('div')

isIE = 'msTransform' of tmpDiv.style
isFF = 'mozTransform' of tmpDiv.style
isWebkit = 'webkitTransform' of tmpDiv.style

tmpDiv = null

module.exports.Agent = class Agent

  @isIE: isIE
  @isFF: isFF
  @isWebkit: isWebkit
