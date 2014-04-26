angular.module('wordlift.tinymce.plugin.services.EntityService', ['wordlift.tinymce.plugin.services.Helpers'])
.service('EntityService', [ 'Helpers', (h) ->

    # Find an entity in the provided entities collection using the provided filters.
    find: (entities, filter) ->
      if filter.uri?
        return (entity for entityId, entity of entities when filter.uri is entity?.id or filter.uri in entity?.sameAs)

    createProps: (item, context) ->
      # Initialize the props
      # console.log "createProps [ item :: #{item} ][ context :: #{context} ]"
      props = {}
      # Populate the props.
      for key, value of item
        # Ignore properties with object (most likely strings with the language code.
        # TODO: enable multilanguge WordLift here.
        continue if angular.isObject value
        expKey = h.expand key, context
        # console.log "createProps [ key :: #{key} ][ expKey :: #{expKey} ][ value :: #{value} ]"
        # Initialize the array.
        props[expKey] = [] if not props[expKey]?
        # Add the value to the array.
        props[expKey].push h.expand(value, context)

      # Return the props.
      props
  ])
