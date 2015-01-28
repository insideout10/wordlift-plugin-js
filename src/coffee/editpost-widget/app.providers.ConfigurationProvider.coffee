angular.module('wordlift.editpost.widget.providers.ConfigurationProvider', [])
.provider("configuration", ()->
  
  boxes = undefined
  
  provider =
    setBoxes: (items)->
      boxes = items
    $get: ()->
      { boxes: boxes }

  provider
)

