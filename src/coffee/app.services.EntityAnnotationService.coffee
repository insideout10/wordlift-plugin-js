angular.module('wordlift.tinymce.plugin.services.EntityAnnotationService', [])
.service('EntityAnnotationService', [ 'Helpers', (Helpers) ->

    # Create an entity annotation using the provided params.
    create: (params) ->
      defaults =
        id: 'uri:local-entity-annotation-' + Helpers.uniqueId(32)
        label: ''
        confidence: 0.0
        entity: null
        relation: null
        selected: false
        _item: null

      # Copy over the label from the entity annotation if the label is not set on the entity.
      params.entity.label = params.label if params.entity? and not params.entity.label?

      # Merge the params with the default settings.
      Helpers.merge defaults, params


    # Find an entity annotation with the provided filters.
    find: (entityAnnotations, filter) ->
      if filter.uri?
        return (entityAnnotation for entityAnnotationId, entityAnnotation of entityAnnotations when filter.uri is entityAnnotation.entity.id or filter.uri in entityAnnotation.entity.sameAs)

      if filter.selected?
        return (entityAnnotation for entityAnnotationId, entityAnnotation of entityAnnotations when entityAnnotation.selected is filter.selected)

  ])