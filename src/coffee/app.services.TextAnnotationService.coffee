angular.module('wordlift.tinymce.plugin.services.TextAnnotationService', [])
.service('TextAnnotationService', [ 'Helpers', (Helpers)->

    # Create a Text Annotation.
    create: (params = {}) ->

      # Set the defalut values.
      defaults =
        id: 'urn:local-text-annotation-' + Helpers.uniqueId 32
        text: ''
        start: 0
        end: 0
        confidence: 0.0
        entityAnnotations: {}
        _item: null

      # Return the Text Annotation structure by merging the defaults with the provided params.
      Helpers.merge defaults, params

    # Find a text annotation in the provided collection given its start and end parameters.
    find: (textAnnotations, start, end) ->
      return textAnnotation for textAnnotationId, textAnnotation of textAnnotations when textAnnotation.start is start and textAnnotation.end is end

  ])

