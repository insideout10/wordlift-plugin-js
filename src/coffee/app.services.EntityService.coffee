angular.module('wordlift.tinymce.plugin.services.EntityService', [])
.service('EntityService', [ ->

    # Find an entity in the provided entities collection using the provided filters.
    find: (entities, filter) ->
#      dump (entity for entityId, entity of entities when filter.uri is entity?.id or filter.uri in entity?.sameAs)
#      return (entity for entityId, entity of entities when filter.uri is entity?.id or filter.uri in entity?.sameAs)
#      for entityId, entity of entities
#        console.log "[ filter.uri :: #{filter.uri }][ found :: #{filter.uri is entity?.id or filter.uri in entity?.sameAs} ][ entity.id :: #{entity.id} ][ entity.sameAs :: #{entity?.sameAs} ]"

      if filter.uri?
        return (entity for entityId, entity of entities when filter.uri is entity?.id or filter.uri in entity?.sameAs)

  ])
