angular.module('wordlift.tinymce.plugin.services.EntityService', [])
.service('EntityService', [ ->

    # Find an entity in the provided entities collection using the provided filters.
    find: (entities, filter) ->
      if filter.uri?
        return (entity for entityId, entity of entities when filter.uri is entity?.id or filter.uri in entity?.sameAs)

  ])
