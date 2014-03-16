# The AnalysisService aim is to parse the Analysis response from an analysis process
# and create a data structure that's is suitable for displaying in the UI.
# The main method of the AnalysisService is parse. The parse method includes some
# helpful functions.
# The return is a structure like this:
#  * language : the language code for the specified post.
#  * languages: an array of languages (and related confidence) identified for the provided text.
#  * entities : the list of entities for the post, each entity provides:
#     * label      : the label in the post language.
#     * description: the description in the post language.
#     * type       : the known type for the entity
#     * types      : a list of types as provided by the entity
#     * thumbnails : URL to thumbnail images

angular.module( 'AnalysisService', [] )
  .service( 'AnalysisService', [ '$http', '$q', '$rootScope', '$log', ($http, $q, $rootScope, $log) ->

    # If true, an analysis is running.
    isRunning: false

    # <a name="analyze"></a>
    # Analyze the provided content. Only one analysis at a time is run.
    # The merge parameter is passed to the parse call and merges together entities related via sameAs.
    analyze: (content, merge = false) ->
      # Exit if an analysis is already running.
      return if @isRunning
      # Set that an analysis is running.
      @isRunning = true

      # Create a reference to the service for use in callbacks.
      that = @

#      ajaxurl = '/wp-content/plugins/wordlift/tests/english.json'
      # Alternatively you can fix the URL to a local test json, e.g.:
      #
      #     '/wp-content/plugins/wordlift/tests/english.json'
      $http.post(ajaxurl + '?action=wordlift_analyze',
        data: content
      )
      # If successful, broadcast an *analysisReceived* event.
      .success (data, status, headers, config) ->
        $rootScope.$broadcast 'analysisReceived', that.parse(data, merge)
        # Set that the analysis is complete.
        that.isRunning = false
      # In case of error, we don't do anything (for now).
      .error  (data, status, headers, config) ->
        console.log 'error received'
        # TODO: implement error handling.
        # Set that the analysis is complete.
        that.isRunning = false

    # Parse the response data from the analysis request (Redlink).
    # If *merge* is set to true, entity annotations and entities with matching sameAs will be merged.
    parse: (data, merge = false) ->

      languages         = []
      textAnnotations   = {}
      entityAnnotations = {}
      entities          = {}

      # support functions:

      # Get the known type given the specified types. Current supported types are:
      #  * person
      #  * organization
      #  * place
      getKnownType = (types) ->
        return 'thing' if not types?

        typesArray = if angular.isArray types then types else [ types ]
        return 'person'       for type in typesArray when 'http://schema.org/Person' is expand(type)
        return 'person'       for type in typesArray when 'http://rdf.freebase.com/ns/people.person' is expand(type)
        return 'organization' for type in typesArray when 'http://schema.org/Organization' is expand(type)
        return 'organization' for type in typesArray when 'http://rdf.freebase.com/ns/government.government' is expand(type)
        return 'organization' for type in typesArray when 'http://schema.org/Newspaper' is expand(type)
        return 'place'        for type in typesArray when 'http://schema.org/Place' is expand(type)
        return 'place'        for type in typesArray when 'http://rdf.freebase.com/ns/location.location' is expand(type)
        return 'event'        for type in typesArray when 'http://schema.org/Event' is expand(type)
        return 'event'        for type in typesArray when 'http://dbpedia.org/ontology/Event' is expand(type)
        return 'music'        for type in typesArray when 'http://rdf.freebase.com/ns/music.artist' is expand(type)
        return 'music'        for type in typesArray when 'http://schema.org/MusicAlbum' is expand(type)
        return 'place'        for type in typesArray when 'http://www.opengis.net/gml/_Feature' is expand(type)

#        $log.debug "[ types :: #{typesArray} ]"
        'thing'

      # create an entity.
      createEntity = (item, language) ->
        id         = get('@id', item)
        types      = get('@type', item)
        sameAs     = get('http://www.w3.org/2002/07/owl#sameAs', item)
        sameAs     = if angular.isArray sameAs then sameAs else [ sameAs ]

#        console.log "createEntity [ id :: #{id} ][ language :: #{language} ][ types :: #{types} ][ sameAs :: #{sameAs} ]"

        # Get all the thumbnails; for each thumbnail execute the provided function.
        thumbnails = get(
          ['http://xmlns.com/foaf/0.1/depiction', 'http://rdf.freebase.com/ns/common.topic.image', 'http://schema.org/image'],
          item,
          (values) ->
            values = if angular.isArray values then values else [ values ]
            for value in values
              match = /m\.(.*)$/i.exec value
              if null is match
                value
              else
                # If it's a Freebase URL normalize the link to the image.
                "https://usercontent.googleapis.com/freebase/v1/image/m/#{match[1]}?maxwidth=4096&maxheight=4096"
        )

        # create the entity model.
        entity =
          id          : id
          thumbnail   : if 0 < thumbnails.length then thumbnails[0] else null
          thumbnails  : thumbnails
          type        : getKnownType(types)
          types       : types
          label       : getLanguage('http://www.w3.org/2000/01/rdf-schema#label', item, language)
          labels      : get('http://www.w3.org/2000/01/rdf-schema#label', item)
          sameAs      : sameAs
          source      : if id.match('^http://rdf.freebase.com/.*$')
                          'freebase'
                        else if id.match('^http://dbpedia.org/.*$')
                          'dbpedia'
                        else
                          'wordlift'
          _item       : item

        entity.description = getLanguage(
          [
            'http://www.w3.org/2000/01/rdf-schema#comment',
            'http://rdf.freebase.com/ns/common.topic.description',
            'http://schema.org/description'
          ], item, language
        )
        entity.descriptions = get(
          [
            'http://www.w3.org/2000/01/rdf-schema#comment',
            'http://rdf.freebase.com/ns/common.topic.description',
            'http://schema.org/description'
          ],
          item
        )

        # Avoid null in entity description.
        entity.description = '' if not entity.description?

        # Check if thumbnails exists.
#        if thumbnails? and angular.isArray thumbnails
#          $q.all(($http.head thumbnail for thumbnail in thumbnails))
#            .then (results) ->
#              # Populate the thumbnails array only with existing images (those that return *status code* 200).
#              entity.thumbnails = (result.config.url for result in results when 200 is result.status)
#              # Set the main thumbnail as the first.
#              # TODO: use the lightest image as first.
#              entity.thumbnail  = entity.thumbnails[0] if 0 < entity.thumbnails.length'

        # return the entity.
#        console.log "createEntity [ entity id :: #{entity.id} ][ language :: #{language} ][ types :: #{types} ][ sameAs :: #{sameAs} ]"
        entity

      createEntityAnnotation = (item) ->
        reference = get('http://fise.iks-project.eu/ontology/entity-reference', item)
        entity = entities[reference]

#        console.log "[ reference :: #{reference} ][ entity :: #{entity} ]"
        # If the referenced entity is not found, return null
        return null if not entity?

        # Get the text annotation id.
        id = get('@id', item)

        # get the related text annotation.
        relations = get('http://purl.org/dc/terms/relation', item)
        # Ensure we're dealing with an array.
        relations = if angular.isArray relations then relations else [ relations ]

        # Create an entity annotation.
        entityAnnotation = {
          id        : id
          label     : get('http://fise.iks-project.eu/ontology/entity-label', item)
          confidence: get('http://fise.iks-project.eu/ontology/confidence', item)
          entity    : entity
          relation  : null
          _item     : item
        }

        # For each text annotation bound to this entity annotation, create an entity annotation and add it to the text annotation.
        for relation in relations
          textAnnotation = textAnnotations[relation]
#          console.log "[ id :: #{id} ][ relation :: #{relation} ][ entity id :: #{entity.id} ][ text annotation :: #{textAnnotation} ]"

          # Create a binding from the textannotation to the entity annotation.
          textAnnotation.entityAnnotations[entityAnnotation.id] = entityAnnotation if textAnnotation?

        # Return the annotations.
        entityAnnotation


      createTextAnnotation = (item) ->
        {
          id               : get('@id', item),
          selectedText     : get('http://fise.iks-project.eu/ontology/selected-text', item)['@value'],
          selectionPrefix  : get('http://fise.iks-project.eu/ontology/selection-prefix', item)['@value'],
          selectionSuffix  : get('http://fise.iks-project.eu/ontology/selection-suffix', item)['@value'],
          confidence       : get('http://fise.iks-project.eu/ontology/confidence', item),
          entityAnnotations: {},
          _item            : item
        }

      createLanguage = (item) ->
        {
          code      : get('http://purl.org/dc/terms/language', item),
          confidence: get('http://fise.iks-project.eu/ontology/confidence', item)
          _item     : item
        }

      # Get the values associated with the specified key(s). Keys are expanded.
      get = (what, container, filter) ->
        # If it's a single key, call getA
        return getA(what, container, filter) if not angular.isArray what

        # Prepare the return array.
        values = []

        # For each key, add the result.
        for key in what
          add = getA(key, container, filter)
          # Ensure the result is an array.
          add = if angular.isArray add then add else [ add ]
          # Merge unique the results.
          mergeUnique values, add

        # Return the result array.
        values

      # Get the values associated with the specified key. Keys are expanded.
      getA = (what, container, filter = (a) -> a ) ->
        # expand the what key.
        whatExp = expand(what)
        # return the value bound to the specified key.
#        console.log "[ what exp :: #{whatExp} ][ key :: #{expand key} ][ value :: #{value} ][ match :: #{whatExp is expand(key)} ]" for key, value of container
        return filter(value) for key, value of container when whatExp is expand(key)
        []

      # get the value for specified property (what) in the provided container in the specified language.
      # items must conform to {'@language':..., '@value':...} format.
      getLanguage =  (what, container, language) ->
        # if there's no item return null.
        return if null is items = get(what, container)
        # transform to an array if it's not already.
        items = if angular.isArray items then items else [ items ]
        # cycle through the array.
        return item['@value'] for item in items when language is item['@language']
        # if not found return null.
        null

      containsOrEquals = (what, where) ->
#        dump "containsOrEquals [ what :: #{what} ][ where :: #{where} ]"
        # if where is not defined return false.
        return false if not where?
        # ensure the where argument is an array.
        whereArray = if angular.isArray where then where else [ where ]
        # expand the what string.
        whatExp    = expand(what)
        if '@' is what.charAt(0)
          # return true if the string is found.
          return true for item in whereArray when whatExp is expand(item)
        else
          # return true if the string is found.
          return true for item in whereArray when whatExp is expand(item)
        # otherwise false.
        false

      mergeUnique = (array1, array2) ->
        array1.push item for item in array2 when item not in array1

      mergeEntities = (entity, entities) ->
        for sameAs in entity.sameAs
          if entities[sameAs]? and entities[sameAs] isnt entity
            existing = entities[sameAs]
            # TODO: make concats unique.
            mergeUnique(entity.sameAs, existing.sameAs)
            mergeUnique(entity.thumbnails, existing.thumbnails)
            entity.source += ", #{existing.source}"
            # Prefer the DBpedia description.
            # TODO: have a user-set priority.
            entity.description = existing.description if 'dbpedia' is existing.source

            # Delete the sameAs entity from the index.
            entities[sameAs] = entity
            mergeEntities(entity, entities)
        entity

      # expand a string to a full path if it contains a prefix.
      expand = (content) ->
        # if there's no prefix, return the original string.
        if null is matches = content.match(/([\w|\d]+):(.*)/)
          prefix = content
          path = ''
        else
          # get the prefix and the path.
          prefix  = matches[1]
          path    = matches[2]

        # if the prefix is unknown, leave it.
        if context[prefix]?
          prepend = if angular.isString context[prefix] then context[prefix] else context[prefix]['@id']
        else
          prepend = prefix + ':'

        # return the full path.
        prepend + path

      # data is split in a context and a graph.
      context  = if data['@context']? then data['@context'] else {}
      graph    = if data['@graph']? then data['@graph'] else {}

      for item in graph
        id     = item['@id']
#        console.log "[ id :: #{id} ]"

        types  = item['@type']
        dctype = get('http://purl.org/dc/terms/type', item)

#        console.log "[ id :: #{id} ][ dc:type :: #{dctype} ]"

        # TextAnnotation/LinguisticSystem
        if containsOrEquals('http://fise.iks-project.eu/ontology/TextAnnotation', types) and containsOrEquals('http://purl.org/dc/terms/LinguisticSystem', dctype)
#          dump "language [ id :: #{id} ][ dc:type :: #{dctype} ]"
          languages.push createLanguage(item)

        # TextAnnotation
        else if containsOrEquals('http://fise.iks-project.eu/ontology/TextAnnotation', types)
#          $log.debug "TextAnnotation [ @id :: #{id} ][ types :: #{types} ]"
          textAnnotations[id] = item

        # EntityAnnotation
        else if containsOrEquals('http://fise.iks-project.eu/ontology/EntityAnnotation', types)
#          $log.debug "EntityAnnotation [ @id :: #{id} ][ types :: #{types} ]"
          entityAnnotations[id] = item

        # Entity
        else
#          $log.debug "Entity [ @id :: #{id} ][ types :: #{types} ]"
          entities[id] = item

      # sort the languages by confidence.
      languages.sort (a, b) ->
        if a.confidence < b.confidence
          return -1
        if a.confidence > b.confidence
          return 1
        0

      # create a reference to the default language.
      language = languages[0].code

      # Create entities instances in the entities array.
      entities[id] = createEntity(item, language) for id, item of entities

      # Cycle in every entity.
      mergeEntities(entity, entities) for id, entity of entities if merge

      # Create text annotation instances.
      textAnnotations[id] = createTextAnnotation(item) for id, item of textAnnotations

      # Create entity annotations instances.
      for id, item of entityAnnotations
#        console.log "[ id :: #{id} ]"
        entityAnnotations[id] = createEntityAnnotation(item)

      # For every text annotation delete entity annotations that refer to the same entity (after merging).
      if merge
        # Cycle in text annotations.
        for textAnnotationId, textAnnotation of textAnnotations
          # Cycle in entity annotations.
          for id, entityAnnotation of textAnnotation.entityAnnotations
#            console.log "[ text-annotation id :: #{textAnnotationId} ][ entity-annotation id :: #{entityAnnotation.id} ]"
            # Check if there are entity annotations referring to the same entity, and if so, delete it.
            for anotherId, anotherEntityAnnotation of textAnnotation.entityAnnotations when id isnt anotherId and entityAnnotation.entity is anotherEntityAnnotation.entity
#              console.log "[ id :: #{id} ][ another id :: #{anotherId} ]"
              delete textAnnotation.entityAnnotations[anotherId]

      # return the analysis result.
      {
        language         : language,
        entities         : entities,
        entityAnnotations: entityAnnotations,
        textAnnotations  : textAnnotations,
        languages        : languages
      }

  ])
