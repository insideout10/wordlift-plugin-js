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
.directive('wlMetaBoxSelectedEntity', ->
    restrict: 'AE'
    scope:
      index: '='
      entity: '='
    template: """
      <span>{{entity.label}} (<small>{{entity.type}}</span>)\n
      <br /><small>{{entity.thumbnail}}</small>
      <input type="hidden" name="entities[{{index}}]['id']" value="{{entity.id}}" />\n
      <input type="hidden" name="entities[{{index}}]['label']" value="{{entity.label}}" />\n
      <input type="hidden" name="entities[{{index}}]['description']" value="{{entity.description}}" />\n
      <input type="hidden" name="entities[{{index}}]['type']" value="{{entity.type}}" />\n
      <input type="hidden" name="entities[{{index}}]['thumbnail']" value="{{entity.thumbnail}}" />\n
    """
  )
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
    analyze: (content) ->
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
        $rootScope.$broadcast 'analysisReceived', that.parse data
        # Set that the analysis is complete.
        that.isRunning = false
      # In case of error, we don't do anything (for now).
      .error  (data, status, headers, config) ->
        console.log 'error received'
        # TODO: implement error handling.
        # Set that the analysis is complete.
        that.isRunning = false

    # Parse the response data from the analysis request (Redlink).
    parse: (data) ->

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
        return null if not types?
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
        thumbnails = get('foaf:depiction', item)
        freebaseThumbnails = get('http://rdf.freebase.com/ns/common.topic.image', item)
        freebaseThumbnails = if angular.isArray freebaseThumbnails then freebaseThumbnails else [ freebaseThumbnails ]
        freebaseThumbnails = ("admin-ajax.php?action=wordlift_freebase_image&url=#{escape(thumbnail)}" for thumbnail in freebaseThumbnails)
        thumbnails = thumbnails.concat freebaseThumbnails

        # create the entity model.
        entity =
          id          : id
          thumbnail   : null
          thumbnails  : thumbnails
          type        : getKnownType(types)
          types       : types
          description : getLanguage('rdfs:comment', item, language)
          descriptions: get('rdfs:comment', item)
          label       : getLanguage('rdfs:label', item, language)
          labels      : get('rdfs:label', item)
          source      : if id.match('^http://rdf.freebase.com/.*$')
                          'freebase'
                        else if id.match('^http://dbpedia.org/.*$')
                          'dbpedia'
                        else
                          'wordlift'
          _item       : item

        # Check if thumbnails exists.
        if thumbnails? and angular.isArray thumbnails
          $q.all(($http.head thumbnail for thumbnail in thumbnails))
            .then (results) ->
              # Populate the thumbnails array only with existing images (those that return *status code* 200).
              entity.thumbnails = (result.config.url for result in results when 200 is result.status)
              # Set the main thumbnail as the first.
              # TODO: use the lightest image as first.
              entity.thumbnail  = entity.thumbnails[0] if 0 < entity.thumbnails.length


        # return the entity.
        entity

      createEntityAnnotation = (item) ->
        # get the related text annotation.
        textAnnotation = textAnnotations[get('dc:relation', item)]

        entity = {
          id        : get('@id', item),
          label     : get('enhancer:entity-label', item),
          confidence: get('enhancer:confidence', item),
          entity    : entities[get('enhancer:entity-reference', item)],
          relation  : textAnnotations[get('dc:relation', item)],
          _item     : item
        }

        # create a binding from the textannotation to the entity.
        textAnnotation.entityAnnotations[entity.id] = entity if textAnnotation?

        # return the entity.
        entity


      createTextAnnotation = (item) ->
        {
          id               : get('@id', item),
          selectedText     : get('enhancer:selected-text', item)['@value'],
          selectionPrefix  : get('enhancer:selection-prefix', item)['@value'],
          selectionSuffix  : get('enhancer:selection-suffix', item)['@value'],
          confidence       : get('enhancer:confidence', item),
          entityAnnotations: {},
          _item            : item
        }

      createLanguage = (item) ->
        {
          code      : get('dc:language', item),
          confidence: get('enhancer:confidence', item)
          _item     : item
        }

      # get the provided key from the container, expanding the keys when necessary.
      get = (what, container) ->
        # expand the what key.
        whatExp = expand(what)
        # return the value bound to the specified key.
        return value for key, value of container when whatExp is expand(key)
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
        # if where is not defined return false.
        return false if not where?
        # ensure the where argument is an array.
        whereArray = if angular.isArray where then where else [ where ]
        # expand the what string.
        whatExp    = expand(what)
        # return true if the string is found.
        return true for item in whereArray when whatExp is expand(item)
        # otherwise false.
        false

      # expand a string to a full path if it contains a prefix.
      expand = (content) ->
        # if there's no prefix, return the original string.
        if null is matches = content.match(/([\w|\d]+):(.*)/)
          return content

        # get the prefix and the path.
        prefix  = matches[1]
        path    = matches[2]

        # if the prefix is unknown, leave it.
        prepend = if prefixes[prefix]? then prefixes[prefix] else "#{prefix}:"

        # return the full path.
        prepend + path

      # data is split in a context and a graph.
      context  = if data['@context']? then data['@context'] else {}
      graph    = if data['@graph']? then data['@graph'] else {}

      # get the prefixes.
      prefixes = []

      # cycle in the context definitions and extract the prefixes.
      for key, value of context
        # consider a prefix only keys w/o ':' and the value is string.
        if -1 is key.indexOf(':') and angular.isString(value)
          # add the prefix.
          prefixes[key] = value

      for item in graph
        id     = item['@id']
        types  = item['@type']
        dctype = get('dc:type', item)

        # TextAnnotation/LinguisticSystem
        if containsOrEquals('enhancer:TextAnnotation', types) and containsOrEquals('dc:LinguisticSystem', dctype)
          languages.push createLanguage(item)

        # TextAnnotation
        else if containsOrEquals('enhancer:TextAnnotation', types)
#          $log.debug "TextAnnotation [ @id :: #{id} ][ types :: #{types} ]"
          textAnnotations[id] = item

        # EntityAnnotation
        else if containsOrEquals('enhancer:EntityAnnotation', types)
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

      # create entities instances in the entities array.
      for id, item of entities
        entity       = createEntity(item, language)
        entities[id] = entity

      # create entities instances in the entities array.
      textAnnotations[id] = createTextAnnotation(item) for id, item of textAnnotations

      # create entities instances in the entities array.
      entityAnnotations[id] = createEntityAnnotation(item) for id, item of entityAnnotations

      # return the analysis result.
      {
        language         : language,
        entities         : entities,
        entityAnnotations: entityAnnotations,
        textAnnotations  : textAnnotations,
        languages        : languages
      }

  ])

angular.module('wordlift.tinymce.plugin.services.EditorService', ['wordlift.tinymce.plugin.config', 'AnalysisService'])
  .service('EditorService', ['AnalysisService', '$rootScope', '$log', 'Configuration', (AnalysisService, $rootScope, $log, Configuration) ->

    # Define the EditorService.
    service =
      # Embed the provided analysis in the editor.
      embedAnalysis: (analysis) ->
        # Clean up the selection prefix/suffix text.
        cleanUp = (text) ->
          text
            .replace('\\', '\\\\').replace( '\(', '\\(' ).replace( '\)', '\\)').replace('\n', '\\n?')
            .replace('-', '\\-').replace('\x20', '\\s').replace('\xa0', '&nbsp;')


        currentHtmlContent = tinyMCE.get('content').getContent({format : 'raw'})

        # Remove the existing text annotation spans.
        spanre = /<span class="textannotation"[^>]*>([^<]*)<\/span>/gi
        while spanre.test currentHtmlContent
          currentHtmlContent = currentHtmlContent.replace spanre, '$1'

        for id, textAnnotation of analysis.textAnnotations
          # get the selection prefix and suffix for the regexp.
          selPrefix = cleanUp(textAnnotation.selectionPrefix.substr(-1))
          selPrefix = '^|\\W' if '' is selPrefix
          selSuffix = cleanUp(textAnnotation.selectionSuffix.substr(0, 1))
          selSuffix = '$|\\W' if '' is selSuffix

          selText   = textAnnotation.selectedText

          # the new regular expression, may not match everything.
          # TODO: enhance the matching.
          r = new RegExp("(#{selPrefix}(?:<[^>]+>){0,})(#{selText})((?:<[^>]+>){0,}#{selSuffix})(?![^<]*\"[^<]*>)")

          replace = "$1<span class=\"textannotation\" id=\"#{id}\" typeof=\"http://fise.iks-project.eu/ontology/TextAnnotation\">$2</span>$3"

          currentHtmlContent = currentHtmlContent.replace( r, replace )

        isDirty = tinyMCE.get('content').isDirty()
        tinyMCE.get('content').setContent currentHtmlContent
        tinyMCE.get('content').isNotDirty = 1 if not isDirty

        # this event is raised when a textannotation is selected in the TinyMCE editor.
        tinyMCE.get('content').onClick.add (editor, e) ->
          # execute the following commands in the angular js context.
          $rootScope.$apply(
            $log.debug "Going to notify click on annotation with id #{e.target.id}"
            # send a message about the currently clicked annotation.
            $rootScope.$broadcast 'textAnnotationClicked', e.target.id, e
          )

      ping: (message)    -> $log.debug message

      # <a name="analyze"></a>
      # Send the provided content for analysis using the [AnalysisService.analyze](app.services.AnalysisService.html#analyze) method.
      analyze: (content) ->
        return if AnalysisService.isRunning
        # Disable the button and set the spinner while analysis is running.
        $('.mce_wordlift').addClass 'running'
        # Make the editor read-obly.
        tinyMCE.get('content').getBody().setAttribute 'contenteditable', false
        # Call the [AnalysisService](AnalysisService.html) to analyze the provided content.
        AnalysisService.analyze content

      # set some predefined variables.
      getEditor : -> tinyMCE.get('content')
      getBody   : -> @getEditor().getBody()
      getDOM    : -> @getEditor().dom

      # get the window position of an element inside the editor.
      # @param element elem The element.
      getWinPos: (elem) ->
        # get a reference to the editor and its body
        ed   = @getEditor()
        el   = elem.target

        top  = $('#content_ifr').offset().top - $('body').scrollTop() +
               el.offsetTop - $(ed.getBody()).scrollTop()

        left = $('#content_ifr').offset().left - $('body').scrollLeft() +
               el.offsetLeft - $(ed.getBody()).scrollLeft()

        # Return the coordinates.
        {top: top, left: left}


    # Hook the service to the events. This event is captured when an entity is selected in the disambiguation popover.
    $rootScope.$on 'DisambiguationWidget.entitySelected', (event, obj) ->
      cssClasses = "textannotation highlight #{obj.entity.type} disambiguated"

      # create a reference to the TinyMCE editor dom.
      dom  = tinyMCE.get("content").dom
      # the element id containing the attributes for the text annotation.
      id   = obj.relation.id
      elem = dom.get(id)

      dom.setAttrib(id, 'class', cssClasses);
      dom.setAttrib(id, 'itemscope', 'itemscope');
      dom.setAttrib(id, 'itemtype',  obj.entity.type);
      dom.setAttrib(id, 'itemid', obj.entity.id);

    # Receive annotations from the analysis (there is a mirror method in PHP for testing purposes, please try to keep
    # the two aligned - tests/functions.php *wl_embed_analysis* )
    # When an analysis is completed, remove the *running* class from the WordLift toolbar button.
    # (The button is set to running when [an analysis is called](#analyze).
    $rootScope.$on 'analysisReceived', (event, analysis) ->

      $log.info 'analysisReceived [ analysis :: ' + analysis + ' ]'

      service.embedAnalysis analysis

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

angular.module('wordlift.tinymce.plugin.controllers', [ 'wordlift.tinymce.plugin.config', 'wordlift.tinymce.plugin.services' ])
  .filter('orderObjectBy', ->
    (items, field, reverse) ->
      filtered = []

      angular.forEach items, (item) -> filtered.push(item)

      filtered.sort (a, b) -> a[field] > b[field]

      filtered.reverse() if reverse

      filtered
  )
  .filter('filterObjectBy', ->
    (items, field, value) ->
      filtered = []

      angular.forEach items, (item) -> filtered.push(item) if item[field] is value

      filtered
  )
  .controller('EntitiesController', ['EditorService', 'EntityService', '$log', '$scope', 'Configuration', (EditorService, EntityService, $log, $scope, Configuration) ->

    # holds a reference to the current analysis results.
    $scope.analysis       = null

    # holds a reference to the selected text annotation.
    $scope.textAnnotation = null
    # holds a reference to the selected text annotation span.
    $scope.textAnnotationSpan = null

#    $scope.annotations = []
#    $scope.selectedEntity = undefined
#    $scope.selectedEntitiesMapping = {}

#    $scope.getSelectedEntities = () ->
#      entities = []
#      for key, value of $scope.selectedEntitiesMapping
#        entities.push value
#      entities

    $scope.sortByConfidence = (entity) ->
    	entity[Configuration.entityLabels.confidence]

    $scope.getLabelFor = (label) ->
      Configuration.entityLabels[label]

    setArrowTop = (top) ->
      $('head').append('<style>#wordlift-disambiguation-popover .postbox:before,#wordlift-disambiguation-popover .postbox:after{top:' + top + 'px;}</style>');

    # a reference to the current text annotation span in the editor.
    el     = undefined
    scroll = ->
      return if not el?
      # get the position of the clicked element.
      pos = EditorService.getWinPos(el)
      # set the popover arrow to the element position.
      setArrowTop(pos.top - 50)

    # TODO: move these hooks on the popover, in order to hook/unhook the events.
    $(window).scroll(scroll)
    $('#content_ifr').contents().scroll(scroll)

    # This event is raised when an entity is selected from the entities popover.
#    $scope.onEntityClicked = (entityIndex, entityAnnotation) ->
#      $scope.selectedEntity = entityIndex
#      $scope.selectedEntitiesMapping[entityAnnotation.relation.id] = entityAnnotation.entity

      # Set the annotation selected/unselected.
#      entityAnnotation.selected = !entityAnnotation.selected

    $scope.onEntitySelected = (textAnnotation, entityAnnotation) ->

      # Select (or unselect) the specified entity annotation.
#      if entityAnnotation.selected
#        EntityService.select entityAnnotation
#      else
#        EntityService.deselect entityAnnotation

      $scope.$emit 'DisambiguationWidget.entitySelected', entityAnnotation

    # Receive the analysis results and store them in the local scope.
    $scope.$on 'analysisReceived', (event, analysis) ->
      $scope.analysis = analysis

    # When a text annotation is clicked, open the disambiguation popover.
    $scope.$on 'textAnnotationClicked', (event, id, sourceElement) ->
      # Set or reset properly $scope.selectedEntity
#      $scope.selectedEntity = undefined

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

# Set the well-known $ reference to jQuery.
$ = jQuery

# Create the main AngularJS module, and set it dependent on controllers and directives.
angular.module('wordlift.tinymce.plugin', ['wordlift.tinymce.plugin.controllers', 'wordlift.tinymce.plugin.directives'])

# Create the HTML fragment for the disambiguation popover that shows when a user clicks on a text annotation.
$(
  container = $('''
    <div id="wordlift-disambiguation-popover" class="metabox-holder">
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

          <div ng-repeat="textAnnotation in analysis.textAnnotations">
            <div ng-repeat="entityAnnotation in textAnnotation.entityAnnotations | filterObjectBy:'selected':true">

              <input type='text' name='wl_entities[{{entityAnnotation.entity.id}}][uri]' value='{{entityAnnotation.entity.id}}'>
              <input type='text' name='wl_entities[{{entityAnnotation.entity.id}}][label]' value='{{entityAnnotation.entity.label}}'>
              <input type='text' name='wl_entities[{{entityAnnotation.entity.id}}][description]' value='{{entityAnnotation.entity.description}}'>
              <input type='text' name='wl_entities[{{entityAnnotation.entity.id}}][type]' value='{{entityAnnotation.entity.type}}'>

              <input ng-repeat="image in entityAnnotation.entity.thumbnails" type='text'
                name='wl_entities[{{entityAnnotation.entity.id}}][image]' value='{{image}}'>

            </div>
          </div>
        </div>
      </div>
    </div>
    ''')
  .appendTo('form[name=post]')
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
    container.hide()

  # Declare ng-controller as main app controller.
  $('body').attr 'ng-controller', 'EntitiesController'

  # Declare the whole document as bootstrap scope.
  injector = angular.bootstrap(document, ['wordlift.tinymce.plugin']);

  # Add WordLift as a plugin of the TinyMCE editor.
  tinymce.PluginManager.add 'wordlift', (editor, url) ->

    # Add a WordLift button the TinyMCE editor.
    editor.addButton 'wordlift',
      text: 'WordLift'
      icon: false
    # When the editor is clicked, the [EditorService.analyze](app.services.EditorService.html#analyze) method is invoked.
      onclick: ->
        injector.invoke(['EditorService', (EditorService) ->
          EditorService.analyze tinyMCE.activeEditor.getContent({format: 'text'})
        ])

  # <a name="editor.onChange.add"></a>
  # Map the editor onChange event to the [EditorService.onChange](app.services.EditorService.html#onChange) method.
#    editor.onChange.add (ed, l) ->
#      # The [EditorService](app.services.EditorService.html) is invoked via the AngularJS injector.
#      injector.invoke(['EditorService', (EditorService) ->
#        EditorService.onChange ed, l
#      ])

)


