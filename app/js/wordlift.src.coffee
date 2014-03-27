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

    #    dump "[ fragment :: #{fragment} ][ pos text :: #{pos.text} ]"
    htmlPos = @text2html pos.text

    @_html = @_html.substring(0, htmlPos) + fragment + @_html.substring(htmlPos)

    # Reparse
    @parse()

    # Increment the position values for those position after the current.
#    @_htmlPositions[i] += fragment.length for i in [0...@_htmlPositions.length] when @_htmlPositions[i] > htmlPos


  # Return the html.
  getHtml: ->
    @_html

  # Return the text.
  getText: ->
    @_text

window.Traslator = Traslator
angular.module('wordlift.tinymce.plugin.config', [])
	.constant 'Configuration', 
		supportedTypes: [
			'schema:Place'
			'schema:Event'
			'schema:CreativeWork'
			'schema:Product'
			'schema:Person'
			'schema:Organization'
		]
		entityLabels:
			'entityLabel': 'enhancer:entity-label'
			'entityType': 'enhancer:entity-type'
			'entityReference': 'enhancer:entity-reference'
			'textAnnotation': 'enhancer:TextAnnotation'
			'entityAnnotation': 'enhancer:EntityAnnotation'
			'selectionPrefix': 'enhancer:selection-prefix'
			'selectionSuffix': 'enhancer:selection-suffix'
			'selectedText': 'enhancer:selected-text'
			'confidence': 'enhancer:confidence'
			'relation':	'dc:relation'
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
      <div class="entity {{entityAnnotation.entity.type}}" ng-class="{selected: true==entityAnnotation.selected}" ng-click="onSelect()" ng-show="entityAnnotation.entity.label">
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
          <input type='text' name='wl_entities[{{entityAnnotation.entity.id}}][type]' value='{{entityAnnotation.entity.type}}'>

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
.service('AnalysisService', [ '$http', '$q', '$rootScope', '$log', ($http, $q, $rootScope, $log) ->
    # Constants
    CONTEXT = '@context'
    GRAPH = '@graph'

    service =
    # Holds the analysis promise, used to abort the analysis.
      promise: undefined

    # If true, an analysis is running.
      isRunning: false

    # Abort a running analysis.
      abort: ->
        # Abort the analysis if an analysis is running and there's a reference to its promise.
        @promise.resolve() if @isRunning and @promise?

    # <a name="analyze"></a>
    # Analyze the provided content. Only one analysis at a time is run.
    # The merge parameter is passed to the parse call and merges together entities related via sameAs.
      analyze: (content, merge = false) ->
        # Exit if an analysis is already running.
        return if @isRunning
        # Set that an analysis is running.
        @isRunning = true

        #      ajaxurl = '/wp-content/plugins/wordlift/tests/english.json'
        # Alternatively you can fix the URL to a local test json, e.g.:
        #
        #     '/wp-content/plugins/wordlift/tests/english.json'
        @promise = $q.defer()

        that = @
        $http(
          method: 'post'
          url: ajaxurl + '?action=wordlift_analyze'
          data: content
          timeout: @promise.promise
        )
        # If successful, broadcast an *analysisReceived* event.
        .success (data, status, headers, config) ->
            $rootScope.$broadcast 'analysisReceived', that.parse(data, merge)
            # Set that the analysis is complete.
            that.isRunning = false

        # In case of error, we don't do anything (for now).
        .error (data, status, headers, config) ->
            # Set that the analysis is complete.
            that.isRunning = false

            $rootScope.$broadcast 'analysisReceived', null
            return if 0 is status # analysis aborted.
            $rootScope.$broadcast 'error', 'An error occurred while requesting an analysis.'


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
          id = get('@id', item)
          types = get('@type', item)
          sameAs = get('http://www.w3.org/2002/07/owl#sameAs', item)
          sameAs = if angular.isArray sameAs then sameAs else [ sameAs ]

          #        console.log "createEntity [ id :: #{id} ][ language :: #{language} ][ types :: #{types} ][ sameAs :: #{sameAs} ]"

          # Get all the thumbnails; for each thumbnail execute the provided function.
          thumbnails = get(
            ['http://xmlns.com/foaf/0.1/depiction', 'http://rdf.freebase.com/ns/common.topic.image',
             'http://schema.org/image'],
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
            id: id
            thumbnail: if 0 < thumbnails.length then thumbnails[0] else null
            thumbnails: thumbnails
            type: getKnownType(types)
            types: types
            label: getLanguage('http://www.w3.org/2000/01/rdf-schema#label', item, language)
            labels: get('http://www.w3.org/2000/01/rdf-schema#label', item)
            sameAs: sameAs
            source: if id.match('^http://rdf.freebase.com/.*$')
              'freebase'
            else if id.match('^http://dbpedia.org/.*$')
              'dbpedia'
            else
              'wordlift'
            _item: item

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

          entity.latitude = get('http://www.w3.org/2003/01/geo/wgs84_pos#lat', item)
          entity.longitude = get('http://www.w3.org/2003/01/geo/wgs84_pos#long', item)

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

          annotations = []

          # Get the text annotation id.
          id = get('@id', item)

          # get the related text annotation.
          relations = get('http://purl.org/dc/terms/relation', item)
          # Ensure we're dealing with an array.
          relations = if angular.isArray relations then relations else [ relations ]

          # For each text annotation bound to this entity annotation, create an entity annotation and add it to the text annotation.
          for relation in relations
            textAnnotation = textAnnotations[relation]

            # Create an entity annotation.
            entityAnnotation = {
              id: id
              label: get('http://fise.iks-project.eu/ontology/entity-label', item)
              confidence: get('http://fise.iks-project.eu/ontology/confidence', item)
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
            selectedText: get('http://fise.iks-project.eu/ontology/selected-text', item)['@value']
            selectionPrefix: get('http://fise.iks-project.eu/ontology/selection-prefix', item)['@value']
            selectionSuffix: get('http://fise.iks-project.eu/ontology/selection-suffix', item)['@value']
            start: get('http://fise.iks-project.eu/ontology/start', item)
            end: get('http://fise.iks-project.eu/ontology/end', item)
            confidence: get('http://fise.iks-project.eu/ontology/confidence', item)
            entityAnnotations: {}
            _item: item
          }
          #          console.log "createTextAnnotation [ start :: #{textAnnotation.start} ][ end :: #{textAnnotation.end} ][ text :: #{textAnnotation.selectedText} ]"
          textAnnotation

        createLanguage = (item) ->
          {
          code: get('http://purl.org/dc/terms/language', item),
          confidence: get('http://fise.iks-project.eu/ontology/confidence', item)
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
              entity.description = existing.description if 'dbpedia' is existing.source
              entity.longitude = existing.longitude if 'dbpedia' is existing.source and existing.longitude?
              entity.latitude = existing.latitude if 'dbpedia' is existing.source and existing.latitude?

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
          dctype = get('http://purl.org/dc/terms/type', item)

          #        console.log "[ id :: #{id} ][ dc:type :: #{dctype} ]"

          # TextAnnotation/LinguisticSystem
          if containsOrEquals('http://fise.iks-project.eu/ontology/TextAnnotation',
            types) and containsOrEquals('http://purl.org/dc/terms/LinguisticSystem', dctype)
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
    ['AnalysisService', '$rootScope', '$log', 'Configuration', (AnalysisService, $rootScope, $log, Configuration) ->

      # Define the EditorService.
      service =
      # Embed the provided analysis in the editor.
        embedAnalysis: (analysis) ->
          # Clean up the selection prefix/suffix text.
#          cleanUp = (text) ->
#            text
#            .replace('\\', '\\\\').replace('\(', '\\(').replace('\)', '\\)').replace('\n', '\\n?')
#            .replace('-', '\\-').replace('\x20', '\\s').replace('\xa0', '&nbsp;')
#            .replace('\[', '\\[').replace('\]', '\\]')

          # Get the TinyMCE editor content.
          content = tinyMCE.get('content').getContent({format: 'raw'})

          # Prepare a traslator instance that will traslate Html and Text positions.
          t = Traslator.create(content)

          # TODO: this should be done before running the analysis. Remove the existing text annotation spans.
#          spanre = new RegExp("<span[^>]+class=\"textannotation\"[^>]*>([^<]*)</span>", "gi")
#          while spanre.test content
#            content = content.replace spanre, '$1'

          for id, textAnnotation of analysis.textAnnotations

            # Don't add the text annotation if there are no entity annotations.
            continue if 0 is Object.keys(textAnnotation.entityAnnotations).length

#            console.log "[ start :: #{textAnnotation.start} ][ end :: #{textAnnotation.end} ][ text :: #{textAnnotation.selectedText} ]"

            # Insert the Html fragments before and after the selected text.
            t.insertHtml "<span class=\"textAnnotation\" id=\"#{id}\">", {text: textAnnotation.start}
            t.insertHtml '</span>', {text: textAnnotation.end}

            #console.log textAnnotation.id
            # get the selection prefix and suffix for the regexp.
#            selPrefix = cleanUp(textAnnotation.selectionPrefix.substr(-1))
#            selPrefix = '^|\\W' if '' is selPrefix
#            selSuffix = cleanUp(textAnnotation.selectionSuffix.substr(0, 1))
#            selSuffix = '$|\\W' if '' is selSuffix
#
#            selText = textAnnotation.selectedText.replace('(', '\\(').replace(')', '\\)')
#
#            # the new regular expression, may not match everything.
#            # TODO: enhance the matching.
#            r = new RegExp("(#{selPrefix}(?:<[^>]+>){0,})(#{selText})((?:<[^>]+>){0,}#{selSuffix})(?![^<]*\"[^<]*>)")
#            r2 = new RegExp("id=\"(urn:enhancement.[a-z,0-9,-]+)\"")
#
            # If there are disambiguated entities
            # the span is not added while the existing span id is replaced
#            if matchResult = content.match r
#              # Skip typeof attribute
#              replace = "#{matchResult[1]}<span class=\"textannotation\" id=\"#{id}\" >#{matchResult[2]}</span>#{matchResult[3]}"
#              if r2.test matchResult[1]
#                m = matchResult[1].replace r2, "id=\"#{id}\""
#                replace = "#{m}#{matchResult[2]}#{matchResult[3]}"
#
#              content = content.replace(r, replace)

          # Loops over disambiguated textAnnotations
          # and notifies selected EntityAnnotations to EntitiesController
#          disambiguatedTextAnnotations = tinyMCE.get('content').dom.select('span.disambiguated')
#          for textAnnotation in disambiguatedTextAnnotations
#            $rootScope.$broadcast 'disambiguatedTextAnnotationDetected', textAnnotation.id, textAnnotation.getAttribute('itemid')

#          console.log "===== getHtml ====="
#          console.log t.getHtml()
#          console.log "===== /getHtml ====="

          isDirty = tinyMCE.get('content').isDirty()
          tinyMCE.get('content').setContent t.getHtml()
          tinyMCE.get('content').isNotDirty = 1 if not isDirty

          # TODO: move this outside of this method.
          # this event is raised when a textannotation is selected in the TinyMCE editor.
          tinyMCE.get('content').onClick.add (editor, e) ->
            # execute the following commands in the angular js context.
            $rootScope.$apply(
              $log.debug "Going to notify click on annotation with id #{e.target.id}"
              # send a message about the currently clicked annotation.
              $rootScope.$broadcast 'textAnnotationClicked', e.target.id, e
            )

      # <a name="analyze"></a>
      # Send the provided content for analysis using the [AnalysisService.analyze](app.services.AnalysisService.html#analyze) method.
        analyze: (content) ->
          if AnalysisService.isRunning
            # If the service is running abort the current request.
            AnalysisService.abort()
          else
            # Disable the button and set the spinner while analysis is running.
            $('.mce_wordlift').addClass 'running'

            # Make the editor read-obly.
            tinyMCE.get('content').getBody().setAttribute 'contenteditable', false

            # Call the [AnalysisService](AnalysisService.html) to analyze the provided content, asking to merge sameAs related entities.
            AnalysisService.analyze content, true

      # set some predefined variables.
        getEditor: ->
          tinyMCE.get('content')
        getBody: ->
          @getEditor().getBody()
        getDOM: ->
          @getEditor().dom

      # get the window position of an element inside the editor.
      # @param element elem The element.
        getWinPos: (elem) ->
          # get a reference to the editor and its body
          ed = @getEditor()
          el = elem.target

          top = $('#content_ifr').offset().top - $('body').scrollTop() +
          el.offsetTop - $(ed.getBody()).scrollTop()

          left = $('#content_ifr').offset().left - $('body').scrollLeft() +
          el.offsetLeft - $(ed.getBody()).scrollLeft()

          # Return the coordinates.
          {top: top, left: left}


      # Hook the service to the events. This event is captured when an entity is selected in the disambiguation popover.
      $rootScope.$on 'DisambiguationWidget.entitySelected', (event, obj) ->
        cssClasses = "textannotation highlight #{obj.entity.type} disambiguated"

        # create a reference to the TinyMCE editor dom.
        dom = tinyMCE.get("content").dom
        # the element id containing the attributes for the text annotation.
        id = obj.relation.id
        elem = dom.get(id)

        dom.setAttrib(id, 'class', cssClasses);
        dom.setAttrib(id, 'itemscope', 'itemscope');
        dom.setAttrib(id, 'itemtype', obj.entity.type);
        dom.setAttrib(id, 'itemid', obj.entity.id);

      # Receive annotations from the analysis (there is a mirror method in PHP for testing purposes, please try to keep
      # the two aligned - tests/functions.php *wl_embed_analysis* )
      # When an analysis is completed, remove the *running* class from the WordLift toolbar button.
      # (The button is set to running when [an analysis is called](#analyze).
      $rootScope.$on 'analysisReceived', (event, analysis) ->
        service.embedAnalysis analysis if analysis?

        # Remove the *running* class.
        $('.mce_wordlift').removeClass 'running'
        # Make the editor read/write.
        tinyMCE.get('content').getBody().setAttribute 'contenteditable', true

      # Return the service definition.
      service
    ])

angular.module('wordlift.tinymce.plugin.services.EntityService', ['wordlift.tinymce.plugin.config'])
# The EntityService manipulates the entities selected, so that they can be sent using a POST to the back-end and
# persisted accordingly.
# The back-end expects an array of entities each containing the following:
# * *string* label
# * *string* type
# * *string* description
# * *array of strings* images
  .service('EntityService', ['$log', ($log) ->

    # Set a reference to the form container.
    container = $('#wordlift_selected_entitities_box')

    # Select the specified entity annotation.
    select : (entityAnnotation) ->
      $log.info 'select'
      $log.info entityAnnotation

      # Set a reference to...
      # ...the entity
      entity = entityAnnotation.entity
      # ...the ID
      id     = entity.id
      # ...the label
      label   = entity.label
      # ...the description
      description = if entity.description? then entity.description else ''
      # ...the images
      images  = entity.thumbnails
      # ...the type
      type    = entity.type

      # Create the entity div.
      entityDiv = $("<div itemid='#{id}'></div>")
        .append("<input type='text' name='wl_entities[#{id}][uri]' value='#{id}'>")
        .append("<input type='text' name='wl_entities[#{id}][label]' value='#{label}'>")
        .append("<input type='text' name='wl_entities[#{id}][description]' value='#{description}'>")
        .append("<input type='text' name='wl_entities[#{id}][type]' value='#{type}'>")

      # Append the images.
      if angular.isArray images
        entityDiv.append("<input type='text' name='wl_entities[#{id}][image]' value='#{image}'>") for image in images
      else
        entityDiv.append("<input type='text' name='wl_entities[#{id}][image]' value='#{images}'>")

      # Finally append the entity div to the container.
      container.append entityDiv

    # Deselect the specified entity annotation.
    deselect : (entityAnnotation) ->
      $log.info 'deselect'
      $log.info entityAnnotation

      # Set a reference to...
      # ...the entity
      entity = entityAnnotation.entity
      # ...the ID
      id     = entity.id

      # Remove the element for the provided entity.
      $("div[itemid='#{id}']").remove()
  ])

angular.module('wordlift.tinymce.plugin.services', [
    'wordlift.tinymce.plugin.config',
    'wordlift.tinymce.plugin.services.EditorService',
    'AnalysisService',
    'wordlift.tinymce.plugin.services.EntityService'
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
.controller('EntitiesController', ['EditorService', 'EntityService', '$log', '$scope', 'Configuration',
    (EditorService, EntityService, $log, $scope, Configuration) ->

      # holds a reference to the current analysis results.
      $scope.analysis = null

      # holds a reference to the selected text annotation.
      $scope.textAnnotation = null
      # holds a reference to the selected text annotation span.
      $scope.textAnnotationSpan = null

      $scope.sortByConfidence = (entity) ->
        entity[Configuration.entityLabels.confidence]

      $scope.getLabelFor = (label) ->
        Configuration.entityLabels[label]

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
        $scope.$emit 'DisambiguationWidget.entitySelected', entityAnnotation

      # Receives notifications about disambiguated textAnnotations
      # and flags selected entityAnnotations properly ... 
      $scope.$on 'disambiguatedTextAnnotationDetected', (event, textAnnotationId, entityId) -> 
        for id, entityAnnotation of $scope.analysis.textAnnotations[textAnnotationId].entityAnnotations
          if entityAnnotation.entity.id == entityId
            $scope.analysis.entityAnnotations[entityAnnotation.id].selected = true

      # Receive the analysis results and store them in the local scope.
      $scope.$on 'analysisReceived', (event, analysis) ->
        $scope.analysis = analysis

      # When a text annotation is clicked, open the disambiguation popover.
      $scope.$on 'textAnnotationClicked', (event, id, sourceElement) ->

        # Get the text annotation with the provided id.
        $scope.textAnnotationSpan = angular.element sourceElement.target

        # Set the current text annotation to the one specified.
        $scope.textAnnotation = $scope.analysis.textAnnotations[id]

        # hide the popover if there are no entities.
        if 0 is $scope.textAnnotation?.entityAnnotations?.length
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
      height: $('body').height() - $('#wpadminbar').height() + 32
      top: $('#wpadminbar').height() - 1
      right: 0
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
            html = tinyMCE.activeEditor.getContent({format: 'raw'})
            console.log html
            text = tinyMCE.activeEditor.getContent({format: 'text'})
            console.log text
            text = Traslator.create(html).getText()
            console.log text
            EditorService.analyze text
          )
        ])

)


