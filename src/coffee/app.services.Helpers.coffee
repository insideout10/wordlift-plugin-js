angular.module('wordlift.tinymce.plugin.services.Helpers', [])
.service('Helpers', [ ->

    # Merges two objects by copying overrides param onto the options.
    merge: (options, overrides) ->
      @extend (@extend {}, options), overrides

    extend: (object, properties) ->
      for key, val of properties
        object[key] = val
      object

    # Creates a unique ID of the specified length (default 8).
    uniqueId: (length = 8) ->
      id = ''
      id += Math.random().toString(36).substr(2) while id.length < length
      id.substr 0, length

  ])