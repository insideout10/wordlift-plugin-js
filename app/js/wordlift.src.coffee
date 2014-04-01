class Traslator

  # Hold the html and textual positions.
  _htmlPositions: []
  _textPositions: []

  # Hold the html and text contents.
  _html: ''
  _text: ''

  # Create an instance of the traslator.
  @create: (html) ->
    traslator = new Traslator(html)
    traslator.parse()
    traslator

  constructor: (html) ->
    @_html = html

  parse: ->
    @_htmlPositions = []
    @_textPositions = []
    @_text = ''

    pattern = /([^<]*)(<[^>]*>)([^<]*)/gim

    textLength = 0
    htmlLength = 0

    while match = pattern.exec @_html

      # Get the text pre/post and the html element
      htmlPre = match[1]
      htmlElem = match[2]
      htmlPost = match[3]

      # Get the text pre/post w/o new lines.
      textPre = htmlPre + (if '</p>' is htmlElem.toLowerCase() then '\n\n' else '')
#      dump "[ htmlPre length :: #{htmlPre.length} ][ textPre length :: #{textPre.length} ]"
      textPost = htmlPost

      # Sum the lengths to the existing lengths.
      textLength += textPre.length
      # For html add the length of the html element.
      htmlLength += htmlPre.length + htmlElem.length

      # If there's a text after the elem, add the position, otherwise skip this one.
      if 0 < htmlPost.length
        @_htmlPositions.push htmlLength
        @_textPositions.push textLength

      textLength += textPost.length
      htmlLength += htmlPost.length

      # Add the textual parts to the text.
      @_text += textPre + textPost

    # Add text position 0 if it's not already set.
    if 0 is @_textPositions.length or 0 isnt @_textPositions[0]
      @_htmlPositions.unshift 0
      @_textPositions.unshift 0

  # Get the html position, given a text position.
  text2html: (pos) ->
    htmlPos = @_textPositions[0]
    textPos = @_textPositions[0]

    for i in [0...@_textPositions.length]
      break if pos < @_textPositions[i]
      htmlPos = @_htmlPositions[i]
      textPos = @_textPositions[i]

    #    dump "#{htmlPos} + #{pos} - #{textPos}"
    htmlPos + pos - textPos

  # Get the text position, given an html position.
  html2text: (pos) ->
    htmlPos = @_textPositions[0]
    textPos = @_textPositions[0]

    for i in [0...@_htmlPositions.length]
      break if pos < @_htmlPositions[i]
      htmlPos = @_htmlPositions[i]
      textPos = @_textPositions[i]

    textPos + pos - htmlPos

  # Insert an Html fragment at the specified location.
  insertHtml: (fragment, pos) ->

#    dump @_htmlPositions
#    dump @_textPositions
#    dump "[ fragment :: #{fragment} ][ pos text :: #{pos.text} ]"

    htmlPos = @text2html pos.text

    @_html = @_html.substring(0, htmlPos) + fragment + @_html.substring(htmlPos)

    # Reparse
    @parse()

  # Return the html.
  getHtml: ->
    @_html

  # Return the text.
  getText: ->
    @_text

window.Traslator = Traslator
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

# Define some constants for commonly used strings.
EDITOR_ID = 'content'
TEXT_ANNOTATION = 'textannotation'
CONTENT_IFRAME = '#content_ifr'
RUNNING_CLASS = 'running'
MCE_WORDLIFT = '.mce_wordlift'
CONTENT_EDITABLE = 'contenteditable'

angular.module('wordlift.tinymce.plugin.config', [])
#	.constant 'Configuration',
#		supportedTypes: [
#			'schema:Place'
#			'schema:Event'
#			'schema:CreativeWork'
#			'schema:Product'
#			'schema:Person'
#			'schema:Organization'
#		]
#		entityLabels:
#			'entityLabel': 'enhancer:entity-label'
#			'entityType': 'enhancer:entity-type'
#			'entityReference': 'enhancer:entity-reference'
#			'textAnnotation': 'enhancer:TextAnnotation'
#			'entityAnnotation': 'enhancer:EntityAnnotation'
#			'selectionPrefix': 'enhancer:selection-prefix'
#			'selectionSuffix': 'enhancer:selection-suffix'
#			'selectedText': 'enhancer:selected-text'
#			'confidence': 'enhancer:confidence'
#			'relation':	'dc:relation'
#      'entityLabel':      'entity-label'
#      'entityType':       'entity-type'
#      'entityReference':  'entity-reference'
#      'textAnnotation':   'TextAnnotation'
#      'entityAnnotation': 'EntityAnnotation'
#      'selectionPrefix':  'selection-prefix'
#      'selectionSuffix':  'selection-suffix'
#      'selectedText':     'selected-text'
#      'confidence':       'confidence'
#      'relation':	        'relation'
angular.module('wordlift.tinymce.plugin.directives', ['wordlift.tinymce.plugin.controllers'])
# The wlEntities directive provides a UI for disambiguating the entities for a provided text annotation.
.directive('wlEntities', ->
    # Restrict the directive to elements only (<wl-entities text-annotation="..."></wl-entities>)
    restrict: 'E'
    # Create a separate scope
    scope:
    # Get the text annotation from the text-annotation attribute.
      textAnnotation: '='
      onSelect: '&'
    # Create the link function in order to bind to children elements events.
    link: (scope, element, attrs) ->
      scope.select = (item) ->

        # Set the selected flag on each annotation.
        for id, entityAnnotation of scope.textAnnotation.entityAnnotations
          # The selected flag is set to false for each annotation which is not the selected one.
          # For the selected one is set to true only if the entity is not selected already, otherwise it is deselected.
          entityAnnotation.selected = item.id is entityAnnotation.id && !entityAnnotation.selected

        # Call the select function with the textAnnotation and the selected entityAnnotation or null.
        scope.onSelect
          textAnnotation: scope.textAnnotation
          entityAnnotation: if item.selected then item else null

    template: """
      <div>
        <ul>
          <li ng-repeat="entityAnnotation in textAnnotation.entityAnnotations | orderObjectBy:'confidence':true">
            <wl-entity on-select="select(entityAnnotation)" entity-annotation="entityAnnotation"></wl-entity>
          </li>
        </ul>
      </div>
    """
  )
# The wlEntity directive shows a tile for a provided entityAnnotation. When a tile is clicked the function provided
# in the select attribute is called.
.directive('wlEntity', ->
    restrict: 'E'
    scope:
      entityAnnotation: '='
      onSelect: '&'
    template: """
      <div class="entity {{entityAnnotation.entity.css}}" ng-class="{selected: true==entityAnnotation.selected}" ng-click="onSelect()" ng-show="entityAnnotation.entity.label">
        <div class="thumbnail" ng-show="entityAnnotation.entity.thumbnail" title="{{entityAnnotation.entity.id}}" ng-attr-style="background-image: url({{entityAnnotation.entity.thumbnail}})"></div>
        <div class="thumbnail empty" ng-hide="entityAnnotation.entity.thumbnail" title="{{entityAnnotation.entity.id}}"></div>
        <div class="confidence" ng-bind="entityAnnotation.confidence"></div>
        <div class="label" ng-bind="entityAnnotation.entity.label"></div>
        <div class="type"></div>
        <div class="source" ng-class="entityAnnotation.entity.source" ng-bind="entityAnnotation.entity.source"></div>
      </div>
    """
  )
# The wlEntityInputBoxes prints the inputs and textareas with entities data.
.directive('wlEntityInputBoxes', ->
    restrict: 'E'
    scope:
      textAnnotations: '='
    template: """
      <div class="wl-entity-input-boxes" ng-repeat="textAnnotation in textAnnotations">
        <div ng-repeat="entityAnnotation in textAnnotation.entityAnnotations | filterObjectBy:'selected':true">

          <input type='text' name='wl_entities[{{entityAnnotation.entity.id}}][uri]' value='{{entityAnnotation.entity.id}}'>
          <input type='text' name='wl_entities[{{entityAnnotation.entity.id}}][label]' value='{{entityAnnotation.entity.label}}'>
          <textarea name='wl_entities[{{entityAnnotation.entity.id}}][description]'>{{entityAnnotation.entity.description}}</textarea>

          <input type='text' name='wl_entities[{{entityAnnotation.entity.id}}][main_type]' value='{{entityAnnotation.entity.type}}'>

          <input ng-repeat="type in entityAnnotation.entity.types" type='text'
          	name='wl_entities[{{entityAnnotation.entity.id}}][type][]' value='{{type}}'>

          <input ng-repeat="image in entityAnnotation.entity.thumbnails" type='text'
            name='wl_entities[{{entityAnnotation.entity.id}}][image][]' value='{{image}}'>
          <input ng-repeat="sameAs in entityAnnotation.entity.sameAs" type='text'
            name='wl_entities[{{entityAnnotation.entity.id}}][sameas][]' value='{{sameAs}}'>

          <input type='text' name='wl_entities[{{entityAnnotation.entity.id}}][latitude]' value='{{entityAnnotation.entity.latitude}}'>
          <input type='text' name='wl_entities[{{entityAnnotation.entity.id}}][longitude]' value='{{entityAnnotation.entity.longitude}}'>

        </div>
      </div>
    """
  )


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
.service('AnalysisService',
    [ 'EntityAnnotationService', 'TextAnnotationService', '$filter', '$http', '$q', '$rootScope',
      (EntityAnnotationService, TextAnnotationService, $filter, $http, $q, $rootScope) ->

        # Set the known types as provided by the environment.
        KNOWN_TYPES = [] # if window.wordlift?.types? then window.wordlift.types else []

        # Find an entity in the analysis 
        # or within window.wordlift.entities storage if needed
        findEntityByUriWithScope = (scope, uri)->
          for entityId, entity of scope
            return entity if uri is entity?.id or uri in entity?.sameAs
 
        # Find a text annotation in the provided collection which matches the start and end values.
        # Otherwise a new text annotation is created
        findOrCreateTextAnnotation = (textAnnotations, textAnnotation) ->
          # Return the text annotation if existing.
          ta = TextAnnotationService.find textAnnotations, textAnnotation.start, textAnnotation.end
          return ta if ta?

          # Create a new text annotation.
          ta = TextAnnotationService.create
            text: textAnnotation.label
            start: textAnnotation.start
            end: textAnnotation.end
            confidence: 1.0

          textAnnotations[ta.id] = ta
          ta

        service =
          setKnownTypes: (types) => @_knownTypes = types

          _knownTypes: []

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
              textAnnotation = findOrCreateTextAnnotation analysis.textAnnotations, annotation
              entityAnnotations = EntityAnnotationService.find textAnnotation.entityAnnotations, uri: annotation.uri
              if 0 < entityAnnotations.length
                # We don't expect more than one entity annotation for an URI inside a text annotation.
                entityAnnotations[0].selected = true 
              else   
                # Retrieve entity from analysis or from the entity storage if needed
                entity = findEntityByUriWithScope(analysis.entities, annotation.uri)
                entity = findEntityByUriWithScope(window.wordlift.entities, annotation.uri) unless entity
                # If the entity is missing raise an excpetion!
                throw "Missing entity in window.wordlift.entities collection!" unless entity
          
                analysis.entities[annotation.uri] = entity
                # Create the new entityAssociation
                ea = EntityAnnotationService.create
                  label: annotation.label
                  confidence: 1
                  entity: analysis.entities[annotation.uri]
                  relation: analysis.textAnnotations[textAnnotation.id]
                  selected: true

                analysis.entityAnnotations[ea.id] = ea
                # Add a reference to the current textAssociation
                textAnnotation.entityAnnotations[ea.id] = analysis.entityAnnotations[ea.id]
        
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

        # Parse the response data from the analysis request (Redlink).
        # If *merge* is set to true, entity annotations and entities with matching sameAs will be merged.
          parse: (data, merge = false) =>
            languages = []
            textAnnotations = {}
            entityAnnotations = {}
            entities = {}

            # support functions:

            # Get the known type given the specified types. Current supported types are:
            #  * person
            #  * organization
            #  * place
            getKnownTypes = (types) =>

              # An array with known types according to the specified types.
              returnTypes = []
              defaultType = undefined
              for kt in @_knownTypes
                # Set the default type, identified by an asterisk (*) in the sameAs values.
                defaultType = [
                  { type: kt }
                ] if '*' in kt.sameAs
                # Get all the URIs associated to this known type.
                uris = kt.sameAs.concat kt.uri
                # If there is 1+ uri in common between the known types and the provided types, then add the known type.
                matches = (uri for uri in uris when containsOrEquals(uri, types))
                returnTypes.push { matches: matches, type: kt } if 0 < matches.length


              # Return the defaul type if not known types have been found.
              return defaultType if 0 is returnTypes.length

              # Sort and return the match types.
              $filter('orderBy') returnTypes, 'matches', true
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
              css = knownTypes[0].type.css

              # create the entity model.
              entity =
                id: id
                thumbnail: if 0 < thumbnails.length then thumbnails[0] else null
                thumbnails: thumbnails
                css: css
                type: knownTypes[0].type.uri # This is the main type for the entity.
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

            # Create an entity annotation. An entity annotation is created for each related text-annotation.
            createEntityAnnotations = (item) ->
              # Get the reference to the entity.
              reference = get "#{FISE_ONT}entity-reference", item
              # If the referenced entity is not found, return null
              return [] if not entities[reference]?

              # Prepare the return array.
              annotations = []

              # get the related text annotation.
              relations = get "#{DCTERMS}relation", item
              # Ensure we're dealing with an array.
              relations = if angular.isArray relations then relations else [ relations ]

              # For each text annotation bound to this entity annotation, create an entity annotation and add it to the text annotation.
              for relation in relations
                textAnnotation = textAnnotations[relation]

                # Create an entity annotation.
                entityAnnotation = EntityAnnotationService.create
                  id: get '@id', item
                  label: get "#{FISE_ONT}entity-label", item
                  confidence: get FISE_ONT_CONFIDENCE, item
                  entity: entities[reference]
                  relation: textAnnotation
                  _item: item

                # Create a binding from the textannotation to the entity annotation.
                textAnnotation.entityAnnotations[entityAnnotation.id] = entityAnnotation if textAnnotation?

                # Accumulate the annotations.
                annotations.push entityAnnotation

              # Return the  entity annotations.
              annotations


            createTextAnnotation = (item) ->
              TextAnnotationService.create
                id: get('@id', item)
                text: get("#{FISE_ONT}selected-text", item)[VALUE]
                start: get "#{FISE_ONT}start", item
                end: get "#{FISE_ONT}end", item
                confidence: get FISE_ONT_CONFIDENCE, item
                entityAnnotations: {}
                _item: item

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
                  mergeEntities entity, entities
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
              entityAnnotations[entityAnnotation.id] = entityAnnotation for entityAnnotation in createEntityAnnotations(item)

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

angular.module('wordlift.tinymce.plugin.services.EditorService', ['wordlift.tinymce.plugin.config', 'AnalysisService'])
.service('EditorService',
    ['AnalysisService', 'EntityAnnotationService', '$rootScope', (AnalysisService, EntityAnnotationService, $rootScope) ->

      editor = ->
        tinyMCE.get(EDITOR_ID)

      # Find existing entities selected in the html content (by looking for *itemid* attributes).
      findEntities = (html) ->

        # Prepare a traslator instance that will traslate Html and Text positions.
        traslator = Traslator.create html

        # Set the pattern to look for *itemid* attributes.
        pattern = /<(\w+)[^>]*\sitemid="([^"]+)"[^>]*>([^<]+)<\/\1>/gim

        # Get the matches and return them.
        (while match = pattern.exec html
          {
            start: traslator.html2text match.index
            end: traslator.html2text (match.index + match[0].length)
            uri: match[2]
            label: match[3]
          }
        )

      # Define the EditorService.
      service =
      # Embed the provided analysis in the editor.
        embedAnalysis: (analysis) ->

          # A reference to the editor.
          ed = editor()

          # Get the TinyMCE editor html content.
          html = ed.getContent format: 'raw'

          # Find existing entities.
          entities = findEntities html

          # Preselect entities found in html.
          AnalysisService.preselect analysis, entities

          # Remove existing text annotations.
          html = html.replace(/<(\w+)[^>]*\sclass="textannotation[^"]*"[^>]*>([^<]+)<\/\1>/gim, '$2')

          # Prepare a traslator instance that will traslate Html and Text positions.
          traslator = Traslator.create html

          # Add text annotations to the html (skip those text annotations that don't have entity annotations).
          for textAnnotationId, textAnnotation of analysis.textAnnotations when 0 < Object.keys(textAnnotation.entityAnnotations).length

            # Start the element.
            element = "<span id=\"#{textAnnotationId}\" class=\"#{TEXT_ANNOTATION}"

            # Insert the Html fragments before and after the selected text.
            entityAnnotations = EntityAnnotationService.find textAnnotation.entityAnnotations, selected: true
            if 0 < entityAnnotations.length and entityAnnotations[0].entity?
              # We deal only with the first entityAnnotation.
              console.log entityAnnotations[0] if not entityAnnotations[0].entity
              entity = entityAnnotations[0].entity
              element += " highlight #{entity.css}\" itemid=\"#{entity.id}"

            # Close the element.
            element += '">'

            # Finally insert the HTML code.
            traslator.insertHtml element, text: textAnnotation.start
            traslator.insertHtml '</span>', text: textAnnotation.end


          # Update the editor Html code.
          isDirty = ed.isDirty()
          ed.setContent traslator.getHtml()
          ed.isNotDirty = not isDirty

      # <a name="analyze"></a>
      # Send the provided content for analysis using the [AnalysisService.analyze](app.services.AnalysisService.html#analyze) method.
        analyze: (content) ->
          # If the service is running abort the current request.
          return AnalysisService.abort() if AnalysisService.isRunning

          # Disable the button and set the spinner while analysis is running.
          $(MCE_WORDLIFT).addClass RUNNING_CLASS

          # Make the editor read-obly.
          editor().getBody().setAttribute CONTENT_EDITABLE, false

          # Call the [AnalysisService](AnalysisService.html) to analyze the provided content, asking to merge sameAs related entities.
          AnalysisService.analyze content, true

      # get the window position of an element inside the editor.
      # @param element elem The element.
        getWinPos: (elem) ->
          # get a reference to the editor and its body
          ed = editor()
          el = elem.target

          # Return the coordinates.
          {
            top: $(CONTENT_IFRAME).offset().top - $('body').scrollTop() + el.offsetTop - $(ed.getBody()).scrollTop()
            left: $(CONTENT_IFRAME).offset().left - $('body').scrollLeft() + el.offsetLeft - $(ed.getBody()).scrollLeft()
          }


      # Hook the service to the events. This event is captured when an entity is selected in the disambiguation popover.
      $rootScope.$on 'selectEntity', (event, args) ->

        # create a reference to the TinyMCE editor dom.
        dom = editor().dom

        # the element id containing the attributes for the text annotation.
        id = args.ta.id

        # Preset the stylesheet class.
        cls = TEXT_ANNOTATION

        # If an entity annotation is selected then prepare the values, otherwise set them null (i.e. remove).
        if args.ea?
          # Set a reference to the entity.
          entity = args.ea.entity
          cls +=  " highlight #{entity.css}"
          itemscope = 'itemscope'
          itemid = entity.id
        else
          itemscope = null
          itemid = null

        # Apply changes to the dom.
        dom.setAttrib id, 'class', cls
        dom.setAttrib id, 'itemscope', itemscope
        dom.setAttrib id, 'itemid', itemid

      # Receive annotations from the analysis (there is a mirror method in PHP for testing purposes, please try to keep
      # the two aligned - tests/functions.php *wl_embed_analysis* )
      # When an analysis is completed, remove the *running* class from the WordLift toolbar button.
      # (The button is set to running when [an analysis is called](#analyze).
      $rootScope.$on 'analysisReceived', (event, analysis) ->
        service.embedAnalysis analysis if analysis? and analysis.textAnnotations?

        # Remove the *running* class.
        $(MCE_WORDLIFT).removeClass RUNNING_CLASS

        # Make the editor read/write.
        editor().getBody().setAttribute CONTENT_EDITABLE, true

      # Return the service definition.
      service
    ])

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

      # Merge the params with the default settings.
      Helpers.merge defaults, params


    # Find an entity annotation with the provided filters.
    find: (entityAnnotations, filter) ->
      if filter.uri?
        return (entityAnnotation for entityAnnotationId, entityAnnotation of entityAnnotations when filter.uri is entityAnnotation.entity.id or filter.uri in entityAnnotation.entity.sameAs)

      if filter.selected?
        return (entityAnnotation for entityAnnotationId, entityAnnotation of entityAnnotations when entityAnnotation.selected is filter.selected)

  ])
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


angular.module('wordlift.tinymce.plugin.services', [
    'wordlift.tinymce.plugin.config'
    'wordlift.tinymce.plugin.services.EditorService'
    'wordlift.tinymce.plugin.services.EntityAnnotationService'
    'wordlift.tinymce.plugin.services.TextAnnotationService'
    'wordlift.tinymce.plugin.services.Helpers'
    'AnalysisService'
  ])

angular.module('wordlift.tinymce.plugin.controllers',
  [ 'wordlift.tinymce.plugin.config', 'wordlift.tinymce.plugin.services' ])
.filter('orderObjectBy', ->
    (items, field, reverse) ->
      filtered = []

      angular.forEach items, (item) ->
        filtered.push(item)

      filtered.sort (a, b) ->
        a[field] > b[field]

      filtered.reverse() if reverse

      filtered
  )
.filter('filterObjectBy', ->
    (items, field, value) ->
      filtered = []

      angular.forEach items, (item) ->
        filtered.push(item) if item[field] is value

      filtered
  )
.controller('EntitiesController', ['EditorService', '$log', '$scope', (EditorService, $log, $scope) ->

    # holds a reference to the current analysis results.
    $scope.analysis = null

    # holds a reference to the selected text annotation.
    $scope.textAnnotation = null
    # holds a reference to the selected text annotation span.
    $scope.textAnnotationSpan = null

    #      $scope.sortByConfidence = (entity) ->
    #        entity[Configuration.entityLabels.confidence]

    #      $scope.getLabelFor = (label) ->
    #        Configuration.entityLabels[label]

    setArrowTop = (top) ->
      $('head').append('<style>#wordlift-disambiguation-popover .postbox:before,#wordlift-disambiguation-popover .postbox:after{top:' + top + 'px;}</style>');

    # a reference to the current text annotation span in the editor.
    el = undefined
    scroll = ->
      return if not el?
      # get the position of the clicked element.
      pos = EditorService.getWinPos(el)
      # set the popover arrow to the element position.
      setArrowTop(pos.top - 50)

    # TODO: move these hooks on the popover, in order to hook/unhook the events.
    $(window).scroll(scroll)
    $('#content_ifr').contents().scroll(scroll)

    $scope.onEntitySelected = (textAnnotation, entityAnnotation) ->
      $scope.$emit 'selectEntity', ta: textAnnotation, ea: entityAnnotation
      # Add the selected entity to the entity storage
      window.wordlift.entities[entityAnnotation.entity.id] = entityAnnotation.entity

    # Receive the analysis results and store them in the local scope.
    $scope.$on 'analysisReceived', (event, analysis) ->
      $scope.analysis = analysis

    # When a text annotation is clicked, open the disambiguation popover.
    $scope.$on 'textAnnotationClicked', (event, id, sourceElement) ->

      # Get the text annotation with the provided id.
#      $scope.textAnnotationSpan = angular.element sourceElement.target

      # Set the current text annotation to the one specified.
      $scope.textAnnotation = $scope.analysis.textAnnotations[id]

      # hide the popover if there are no entities.
      if not $scope.textAnnotation?.entityAnnotations? or 0 is Object.keys($scope.textAnnotation.entityAnnotations).length
        $('#wordlift-disambiguation-popover').hide()
        # show the popover.
      else

        # get the position of the clicked element.
        pos = EditorService.getWinPos(sourceElement)
        # set the popover arrow to the element position.
        setArrowTop(pos.top - 50)

        # show the popover.
        $('#wordlift-disambiguation-popover').show()

  ])
.controller('ErrorController', ['$element', '$scope', '$log', ($element, $scope, $log) ->

    # Set the element as a jQuery UI Dialog.
    element = $($element).dialog
      title: 'WordLift'
      dialogClass: 'wp-dialog'
      modal: true
      autoOpen: false
      closeOnEscape: true
      buttons:
        Ok: ->
          $(this).dialog 'close'

    # Show the dialog box when an error is raised.
    $scope.$on 'error', (event, message) ->
      $scope.message = message
      element.dialog 'open'

  ])

# Set the well-known $ reference to jQuery.
$ = jQuery

# Create the main AngularJS module, and set it dependent on controllers and directives.
angular.module('wordlift.tinymce.plugin', ['wordlift.tinymce.plugin.controllers', 'wordlift.tinymce.plugin.directives'])

# Create the HTML fragment for the disambiguation popover that shows when a user clicks on a text annotation.
$(
  container = $('''
    <div id="wl-app" class="wl-app">
      <div id="wl-error-controller" class="wl-error-controller" ng-controller="ErrorController">
        <p ng-bind="message"></p>
      </div>
      <div id="wordlift-disambiguation-popover" class="metabox-holder" ng-controller="EntitiesController">
        <div class="postbox">
          <div class="handlediv" title="Click to toggle"><br></div>
          <h3 class="hndle"><span>Semantic Web</span></h3>
          <div class="inside">
            <form role="form">
              <div class="form-group">
                <div class="ui-widget">
                  <input type="text" class="form-control" id="search" placeholder="search or create">
                </div>
              </div>

              <wl-entities on-select="onEntitySelected(textAnnotation, entityAnnotation)" text-annotation="textAnnotation"></wl-entities>

            </form>

            <wl-entity-input-boxes text-annotations="analysis.textAnnotations"></wl-entity-input-boxes>
          </div>
        </div>
      </div>
    </div>
    ''')
  .appendTo('form[name=post]')

  $('#wordlift-disambiguation-popover')
  .css(
      display: 'none'
      height: $('body').height() - $('#wpadminbar').height() + 12
      top: $('#wpadminbar').height() - 1
      right: 20
    )
  .draggable()

  $('#search').autocomplete
    source: ajaxurl + '?action=wordlift_search',
    minLength: 2,
    select: (event, ui) ->
      console.log event
      console.log ui
  .data("ui-autocomplete")._renderItem = (ul, item) ->
    console.log ul
    $("<li>")
    .append("""
        <li>
          <div class="entity #{item.types}">
            <!-- div class="thumbnail" style="background-image: url('')"></div -->
            <div class="thumbnail empty"></div>
            <div class="confidence"></div>
            <div class="label">#{item.label}</div>
            <div class="type"></div>
            <div class="source"></div>
          </div>
        </li>
    """)
    .appendTo(ul)

  # When the user clicks on the handle, hide the popover.
  $('#wordlift-disambiguation-popover .handlediv').click (e) ->
    $('#wordlift-disambiguation-popover').hide()

  # Declare the whole document as bootstrap scope.
  injector = angular.bootstrap $('#wl-app'), ['wordlift.tinymce.plugin']
  injector.invoke ['AnalysisService', (AnalysisService) ->
    AnalysisService.setKnownTypes window.wordlift.types
  ]

  # Add WordLift as a plugin of the TinyMCE editor.
  tinymce.PluginManager.add 'wordlift', (editor, url) ->

    # Add a WordLift button the TinyMCE editor.
    editor.addButton 'wordlift',
      text: 'WordLift'
      icon: false

    # When the editor is clicked, the [EditorService.analyze](app.services.EditorService.html#analyze) method is invoked.
      onclick: ->
        injector.invoke(['EditorService', '$rootScope', (EditorService, $rootScope) ->
          $rootScope.$apply( ->
            # Get the html content of the editor.
            html = tinyMCE.activeEditor.getContent({format: 'raw'})

            # Get the text content from the Html.
            text = Traslator.create(html).getText()

            # Send the text content for analysis.
            EditorService.analyze text
          )
        ])

    # TODO: move this outside of this method.
    # this event is raised when a textannotation is selected in the TinyMCE editor.
    editor.onClick.add (editor, e) ->
      injector.invoke(['$rootScope', ($rootScope) ->
        # execute the following commands in the angular js context.
        $rootScope.$apply(  ->
          # send a message about the currently clicked annotation.
          $rootScope.$broadcast 'textAnnotationClicked', e.target.id, e
        )
      ])
)


