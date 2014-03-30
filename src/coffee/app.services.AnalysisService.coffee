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

angular.module('AnalysisService', [])
.service('AnalysisService', [ '$http', '$q', '$rootScope', ($http, $q, $rootScope) ->

    # Constants
    CONTEXT = '@context'
    GRAPH = '@graph'
    VALUE = '@value'

    ANALYSIS_EVENT = 'analysisReceived'

    RDFS = 'http://www.w3.org/2000/01/rdf-schema#'
    RDFS_LABEL = "#{RDFS}label"
    RDFS_COMMENT = "#{RDFS}comment"

    FREEBASE = 'freebase'
    FREEBASE_COM = "http://rdf.#{FREEBASE}.com/"
    FREEBASE_NS = "#{FREEBASE_COM}ns/"
    FREEBASE_NS_DESCRIPTION = "#{FREEBASE_NS}common.topic.description"

    SCHEMA_ORG = 'http://schema.org/'
    SCHEMA_ORG_DESCRIPTION = "#{SCHEMA_ORG}description"

    FISE_ONT = 'http://fise.iks-project.eu/ontology/'
    FISE_ONT_ENTITY_ANNOTATION = "#{FISE_ONT}EntityAnnotation"
    FISE_ONT_TEXT_ANNOTATION = "#{FISE_ONT}TextAnnotation"
    FISE_ONT_CONFIDENCE = "#{FISE_ONT}confidence"

    DCTERMS = 'http://purl.org/dc/terms/'

    DBPEDIA = 'dbpedia'
    DBPEDIA_ORG = "http://#{DBPEDIA}.org/"

    WGS84_POS = 'http://www.w3.org/2003/01/geo/wgs84_pos#'

    # Set the known types as provided by the environment.
    KNOWN_TYPES = if window.wordlift?.types? then window.wordlift.types else []

    # Find a text annotation in the provided collection which matches the start and end values.
    findTextAnnotation = (textAnnotations, start, end) ->
      return textAnnotation for textAnnotationId, textAnnotation of textAnnotations when textAnnotation.start is start and textAnnotation.end is end
    # Find a text annotation in the provided collection which matches the start and end values.
    # Otherwise a new text annotation is created
    findOrCreateTextAnnotation = (analysis, textAnnotation) ->
      ta = findTextAnnotation analysis.textAnnotations, textAnnotation.start, textAnnotation.end
      if null is ta
        # A new textAnnotation is created if needed
        ta = 
          id: 'wordlift-ta-' + textAnnotation.start + '-' + textAnnotation.end
          selectedText: textAnnotation.label
          selectionPrefix: ''
          selectionSuffix: ''
          start: textAnnotation.start
          end: textAnnotation.end
          confidence: null
          entityAnnotations: {}
          _item: null
        # The new textAnnotation is added to the analysis 
        analysis.textAnnotations[ta.id] = ta
      ta         

    service =
    # Holds the analysis promise, used to abort the analysis.
      promise: undefined

    # If true, an analysis is running.
      isRunning: false

    # Abort a running analysis.
      abort: ->
        # Abort the analysis if an analysis is running and there's a reference to its promise.
        @promise.resolve() if @isRunning and @promise?

    # Preselect entity annotations in the provided analysis using the provided collection of annotations.
      preselect: (analysis, annotations) ->

        # Find the existing entities in the html
        for annotation in annotations
          textAnnotation = findOrCreateTextAnnotation analysis, annotation
          entityAnnotation = @findEntityAnnotation textAnnotation.entityAnnotations, uri: annotation.uri
          if entityAnnotation?
            entityAnnotation.selected = true
          else
            # Retrieve entity from the entity storage if needed
            unless analysis.entities[annotation.uri]
              analysis.entities[annotation.uri] = window.wordlift.entities[annotation.uri]

            # Create the new entityAssociation 
            ea =
              id: 'wordlift-ea-from-' + textAnnotation.id
              label: annotation.label
              confidence: null
              entity: analysis.entities[annotation.uri]
              relation: analysis.textAnnotations[textAnnotation.id]
              _item: null
              selected: true
            # Add the new entity association to the analysis  
            analysis.entityAnnotations[ea.id] = ea
            # Add a reference to the current textAssociation
            textAnnotation.entityAnnotations[ea.id] = analysis.entityAnnotations[ea.id]
               
          
    # TODO: if the entity is not found, it needs to be added.

    # <a name="analyze"></a>
    # Analyze the provided content. Only one analysis at a time is run.
    # The merge parameter is passed to the parse call and merges together entities related via sameAs.
      analyze: (content, merge = false) ->
        # Exit if an analysis is already running.
        return if @isRunning

        # Set that an analysis is running.
        @isRunning = true

        # Store the promise in the class to allow interrupting the request.
        @promise = $q.defer()

        that = @

        $http(
          method: 'post'
          url: ajaxurl + '?action=wordlift_analyze'
          data: content
          timeout: @promise.promise
        )
        # If successful, broadcast an *analysisReceived* event.
        .success (data) ->
            $rootScope.$broadcast ANALYSIS_EVENT, that.parse(data, merge)
            # Set that the analysis is complete.
            that.isRunning = false

        .error (data, status) ->
            # Set that the analysis is complete.
            that.isRunning = false
            $rootScope.$broadcast ANALYSIS_EVENT, undefined

            return if 0 is status # analysis aborted.
            $rootScope.$broadcast 'error', 'An error occurred while requesting an analysis.'

    # Find an entity annotation in the provided collection using the provided filter.
      findEntityAnnotation: (entityAnnotations, filter) ->
        if filter.uri?
          return entityAnnotation for entityAnnotationId, entityAnnotation of entityAnnotations when filter.uri is entityAnnotation.entity.id or filter.uri in entityAnnotation.entity.sameAs

        if filter.selected?
          return entityAnnotation for entityAnnotationId, entityAnnotation of entityAnnotations when entityAnnotation.selected

    # Parse the response data from the analysis request (Redlink).
    # If *merge* is set to true, entity annotations and entities with matching sameAs will be merged.
      parse: (data, merge = false) ->
        languages = []
        textAnnotations = {}
        entityAnnotations = {}
        entities = {}

        # support functions:

        # Get the known type given the specified types. Current supported types are:
        #  * person
        #  * organization
        #  * place
        getKnownTypes = (types) ->

          # Ensure the entity (this is now left to the caller).
          # types = if angular.isArray types then types else [ types ]

          # An array with known types according to the specified types.
          returnTypes = []
          defaultType = undefined
          for kt in KNOWN_TYPES
            # Set the default type, identified by an asterisk (*) in the sameAs values.
            defaultType = [ kt ] if '*' in kt.sameAs
            # Get all the URIs associated to this known type.
            uris = kt.sameAs.concat kt.uri
            # If there is 1+ uri in common between the known types and the provided types, then add the known type.
            returnTypes.push kt if 0 < (uri for uri in uris when containsOrEquals( uri, types )).length


          # Return the defaul type if not known types have been found.
          return defaultType if 0 is returnTypes.length

          # Return the match types.
          returnTypes


        # create an entity.
        createEntity = (item, language) ->
          id = get('@id', item)
          # Get the types associated with the entity.
          types = get('@type', item)
          types = if angular.isArray types then types else [ types ]
          sameAs = get('http://www.w3.org/2002/07/owl#sameAs', item)
          sameAs = if angular.isArray sameAs then sameAs else [ sameAs ]

          #        console.log "createEntity [ id :: #{id} ][ language :: #{language} ][ types :: #{types} ][ sameAs :: #{sameAs} ]"

          # Get all the thumbnails; for each thumbnail execute the provided function.
          thumbnails = get(
            [
              'http://xmlns.com/foaf/0.1/depiction'
              "#{FREEBASE_NS}common.topic.image"
              "#{SCHEMA_ORG}image"
            ],
            item,
          (values) ->
            values = if angular.isArray values then values else [ values ]
            for value in values
              match = /m\.(.*)$/i.exec value
              if null is match
                value
              else
                # If it's a Freebase URL normalize the link to the image.
                "https://usercontent.googleapis.com/#{FREEBASE}/v1/image/m/#{match[1]}?maxwidth=4096&maxheight=4096"
          )

          # Get the known types.
          knownTypes = getKnownTypes(types)
          # Get the stylesheet classes.
          css = (kt.css for kt in knownTypes).join ' '

          # create the entity model.
          entity =
            id: id
            thumbnail: if 0 < thumbnails.length then thumbnails[0] else null
            thumbnails: thumbnails
            css: css
            types: types
            label: getLanguage(RDFS_LABEL, item, language)
            labels: get(RDFS_LABEL, item)
            sameAs: sameAs
            source: if id.match("^#{FREEBASE_COM}.*$")
              FREEBASE
            else if id.match("^#{DBPEDIA_ORG}.*$")
              DBPEDIA
            else
              'wordlift'
            _item: item

          entity.description = getLanguage(
            [
              RDFS_COMMENT
              FREEBASE_NS_DESCRIPTION
              SCHEMA_ORG_DESCRIPTION
            ], item, language
          )
          entity.descriptions = get(
            [
              RDFS_COMMENT
              FREEBASE_NS_DESCRIPTION
              SCHEMA_ORG_DESCRIPTION
            ],
            item
          )

          # Avoid null in entity description.
          entity.description = '' if not entity.description?

          entity.latitude = get "#{WGS84_POS}lat", item
          entity.longitude = get "#{WGS84_POS}long", item
          if 0 is entity.latitude.length or 0 is entity.longitude.length
            entity.latitude = ''
            entity.longitude = ''

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
          reference = get "#{FISE_ONT}entity-reference", item
          entity = entities[reference]

          #        console.log "[ reference :: #{reference} ][ entity :: #{entity} ]"
          # If the referenced entity is not found, return null
          return null if not entity?

          annotations = []

          # Get the text annotation id.
          id = get('@id', item)

          # get the related text annotation.
          relations = get "#{DCTERMS}relation", item
          # Ensure we're dealing with an array.
          relations = if angular.isArray relations then relations else [ relations ]

          # For each text annotation bound to this entity annotation, create an entity annotation and add it to the text annotation.
          for relation in relations
            textAnnotation = textAnnotations[relation]

            # Create an entity annotation.
            entityAnnotation = {
              id: id
              label: get "#{FISE_ONT}entity-label", item
              confidence: get FISE_ONT_CONFIDENCE, item
              entity: entity
              relation: textAnnotation
              _item: item
              selected: false
            }

            #          console.log "[ id :: #{id} ][ relation :: #{relation} ][ entity id :: #{entity.id} ][ text annotation :: #{textAnnotation} ]"

            # Create a binding from the textannotation to the entity annotation.
            textAnnotation.entityAnnotations[entityAnnotation.id] = entityAnnotation if textAnnotation?

            annotations.push entityAnnotation

          # Return the annotations.
          annotations[0]


        createTextAnnotation = (item) ->
          textAnnotation = {
            id: get('@id', item)
            selectedText: get("#{FISE_ONT}selected-text", item)[VALUE]
            selectionPrefix: get("#{FISE_ONT}selection-prefix", item)[VALUE]
            selectionSuffix: get("#{FISE_ONT}selection-suffix", item)[VALUE]
            start: get "#{FISE_ONT}start", item
            end: get "#{FISE_ONT}end", item
            confidence: get FISE_ONT_CONFIDENCE, item
            entityAnnotations: {}
            _item: item
          }
          #          console.log "createTextAnnotation [ start :: #{textAnnotation.start} ][ end :: #{textAnnotation.end} ][ text :: #{textAnnotation.selectedText} ]"
          textAnnotation

        createLanguage = (item) ->
          {
          code: get "#{DCTERMS}language", item
          confidence: get FISE_ONT_CONFIDENCE, item
          _item: item
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
        getA = (what, container, filter = (a) ->
          a) ->
          # expand the what key.
          whatExp = expand(what)
          # return the value bound to the specified key.
          #        console.log "[ what exp :: #{whatExp} ][ key :: #{expand key} ][ value :: #{value} ][ match :: #{whatExp is expand(key)} ]" for key, value of container
          return filter(value) for key, value of container when whatExp is expand(key)
          []

        # get the value for specified property (what) in the provided container in the specified language.
        # items must conform to {'@language':..., '@value':...} format.
        getLanguage = (what, container, language) ->
          # if there's no item return null.
          return if null is items = get(what, container)
          # transform to an array if it's not already.
          items = if angular.isArray items then items else [ items ]
          # cycle through the array.
          return item[VALUE] for item in items when language is item['@language']
          # if not found return null.
          null

        containsOrEquals = (what, where) ->
          #        dump "containsOrEquals [ what :: #{what} ][ where :: #{where} ]"
          # if where is not defined return false.
          return false if not where?
          # ensure the where argument is an array.
          whereArray = if angular.isArray where then where else [ where ]
          # expand the what string.
          whatExp = expand(what)
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
              entity.description = existing.description if DBPEDIA is existing.source
              entity.longitude = existing.longitude if DBPEDIA is existing.source and existing.longitude?
              entity.latitude = existing.latitude if DBPEDIA is existing.source and existing.latitude?

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
            prefix = matches[1]
            path = matches[2]

          # if the prefix is unknown, leave it.
          if context[prefix]?
            prepend = if angular.isString context[prefix] then context[prefix] else context[prefix]['@id']
          else
            prepend = prefix + ':'

          # return the full path.
          prepend + path

        # Check that the response is valid.
        if not ( data[CONTEXT]? and data[GRAPH]? )
          $rootScope.$broadcast 'error', 'The analysis response is invalid. Please try again later.'
          return false

        # data is split in a context and a graph.
        context = data[CONTEXT]
        graph = data[GRAPH]

        for item in graph
          id = item['@id']
          #        console.log "[ id :: #{id} ]"

          types = item['@type']
          dctype = get "#{DCTERMS}type", item

          #        console.log "[ id :: #{id} ][ dc:type :: #{dctype} ]"

          # TextAnnotation/LinguisticSystem
          if containsOrEquals(FISE_ONT_TEXT_ANNOTATION,
            types) and containsOrEquals("#{DCTERMS}LinguisticSystem", dctype)
            #          dump "language [ id :: #{id} ][ dc:type :: #{dctype} ]"
            languages.push createLanguage(item)

            # TextAnnotation
          else if containsOrEquals(FISE_ONT_TEXT_ANNOTATION, types)
            #          $log.debug "TextAnnotation [ @id :: #{id} ][ types :: #{types} ]"
            textAnnotations[id] = item

            # EntityAnnotation
          else if containsOrEquals(FISE_ONT_ENTITY_ANNOTATION, types)
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
        language: language
        entities: entities
        entityAnnotations: entityAnnotations
        textAnnotations: textAnnotations
        languages: languages
        }

    # Return the service instance
    service
  ])
