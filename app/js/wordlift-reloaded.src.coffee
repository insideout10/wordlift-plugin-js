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

    # TODO: the pattern should consider that HTML has also HTML entities.
    # Remove non-breaking spaces.
    @_html = @_html.replace /&nbsp;/gim, ' '

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

      # Add the position.
      @_htmlPositions.push htmlLength
      @_textPositions.push textLength

      textLength += textPost.length
      htmlLength += htmlPost.length

      # Add the textual parts to the text.
      @_text += textPre + textPost


    # In case the regex didn't find any tag, copy the html over the text.
    @_text = new String(@_html) if '' is @_text and '' isnt @_html

    # Add text position 0 if it's not already set.
    if 0 is @_textPositions.length or 0 isnt @_textPositions[0]
      @_htmlPositions.unshift 0
      @_textPositions.unshift 0

#    console.log '=============================='
#    console.log @_html
#    console.log @_text
#    console.log @_htmlPositions
#    console.log @_textPositions
#    console.log '=============================='

  # Get the html position, given a text position.
  text2html: (pos) ->
    htmlPos = 0
    textPos = 0

    for i in [0...@_textPositions.length]
      break if pos < @_textPositions[i]
      htmlPos = @_htmlPositions[i]
      textPos = @_textPositions[i]

    #    dump "#{htmlPos} + #{pos} - #{textPos}"
    htmlPos + pos - textPos

  # Get the text position, given an html position.
  html2text: (pos) ->
#    dump @_htmlPositions
#    dump @_textPositions

    # Return 0 if the specified html position is less than the first HTML position.
    return 0 if pos < @_htmlPositions[0]

    htmlPos = 0
    textPos = 0

    for i in [0...@_htmlPositions.length]
      break if pos < @_htmlPositions[i]
      htmlPos = @_htmlPositions[i]
      textPos = @_textPositions[i]

#    console.log "#{textPos} + #{pos} - #{htmlPos}"
    textPos + pos - htmlPos

  # Insert an Html fragment at the specified location.
  insertHtml: (fragment, pos) ->

#    dump @_htmlPositions
#    dump @_textPositions
#    console.log "[ fragment :: #{fragment} ][ pos text :: #{pos.text} ]"

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
angular.module('wordlift.editpost.widget.controllers.EditPostWidgetController', [
  'wordlift.editpost.widget.services.AnalysisService'
  'wordlift.editpost.widget.services.EditorService'
  'wordlift.editpost.widget.providers.ConfigurationProvider'
])
.filter('entityTypeIn', [ '$log', ($log)->
  return (items, types)->
    
    filtered = []

    for id, entity of items
      if entity.mainType in types
        filtered.push entity
    
    filtered
])
.controller('EditPostWidgetController', [ 'EditorService', 'AnalysisService', 'configuration', '$log', '$scope', '$rootScope', '$injector', (EditorService, AnalysisService, configuration, $log, $scope, $rootScope, $injector)-> 

  $scope.configuration = []
  $scope.analysis = {}
  $scope.newEntity = AnalysisService.createEntity()
  $scope.selectedEntities = {}
  $scope.widgets = {}
  $scope.annotation = undefined
  $scope.boxes = []
  $scope.isSelectionCollapsed = true
  
  for box in configuration.boxes

    $scope.selectedEntities[ box.id ] = {}
    $scope.widgets[ box.id ] = {}
    for widget in box.registeredWidgets
      $scope.widgets[ box.id ][ widget ] = []
              
  $scope.configuration = configuration

  # Delegate to EditorService
  $scope.createTextAnnotationFromCurrentSelection = ()->
    EditorService.createTextAnnotationFromCurrentSelection()
  # Delegate to EditorService
  $scope.selectAnnotation = (annotationId)->
    EditorService.selectAnnotation annotationId

  $scope.addNewEntityToAnalysis = ()->
    # Add new entity to the analysis
    $scope.analysis.entities[ $scope.newEntity.id ] = $scope.newEntity
    annotation = $scope.analysis.annotations[ $scope.annotation ]
    annotation.entityMatches.push { entityId: $scope.newEntity.id, confidence: 1 }
    $scope.analysis.entities[ $scope.newEntity.id ].annotations[ annotation.id ] = annotation
    
    # TODO Check entity tiles status

    # Create new entity object
    $scope.newEntity = AnalysisService.createEntity()
    
  $scope.$on "isSelectionCollapsed", (event, status) ->
    $log.debug "Going to se isSelectionAvailable to #{status}"
    $scope.isSelectionCollapsed = status

  $scope.$on "updateOccurencesForEntity", (event, entityId, occurrences) ->
    $log.debug "Occurrences #{occurrences.length} for #{entityId}"
    $scope.analysis.entities[ entityId ].occurrences = occurrences

    if $scope.annotation?
      for box, entities of $scope.selectedEntities
        $scope.boxes[ box ].relink $scope.analysis.entities[ entityId ], $scope.annotation
        
    if occurrences.length is 0
      for box, entities of $scope.selectedEntities
        delete $scope.selectedEntities[ box ][ entityId ]
        $scope.boxes[ box ].deselect $scope.analysis.entities[ entityId ]
        
  $scope.$on "textAnnotationClicked", (event, annotationId) ->
    $scope.annotation = annotationId

  $scope.$on "textAnnotationAdded", (event, annotation) ->
    $log.debug "added a new annotation with Id #{annotation.id}"
    # Add the new annotation to the current analysis
    $scope.analysis.annotations[ annotation.id ] = annotation
    # Set the annotation scope
    $scope.annotation = annotation.id
    # Set the annotation text as label for the new entity
    $scope.newEntity.label = annotation.text
  
  $scope.$on "analysisPerformed", (event, analysis) -> 
    $scope.analysis = analysis

  $scope.$on "updateWidget", (event, widget, scope)->
    $log.debug "Going to updated widget #{widget} for box #{scope}"
    # Retrieve the proper DatarRetriever
    retriever = $injector.get "#{widget}DataRetrieverService"
    # Load widget items
    items = retriever.loadData $scope.selectedEntities[ scope ]
    # Assign items to the widget scope
    $scope.widgets[ scope ][ widget ] = items
    
  $scope.onSelectedEntityTile = (entity, scope)->
    $log.debug "Entity tile selected for entity #{entity.id} within '#{scope.id}' scope"
    
    # Close all opened widgets ...
    for id, box of $scope.boxes
      box.closeWidgets()
    
    if not $scope.selectedEntities[ scope.id ][ entity.id ]?
      $scope.selectedEntities[ scope.id ][ entity.id ] = entity
      $scope.$emit "entitySelected", entity, $scope.annotation
    else
      $scope.$emit "entityDeselected", entity, $scope.annotation  
      
])
angular.module('wordlift.editpost.widget.directives.wlClassificationBox', [])
.directive('wlClassificationBox', ['$log', ($log)->
    restrict: 'E'
    scope: true
    transclude: true      
    template: """
    	<div class="classification-box">
    		<div class="box-header">
          <h5 class="label">{{box.label}}
            <span class="wl-suggestion-tools" ng-show="hasSelectedEntities()">
              <i ng-class="'wl-' + widget" title="{{widget}}" ng-click="toggleWidget(widget)" ng-repeat="widget in box.registeredWidgets" class="wl-widget-icon"></i>
            </span>
            <span ng-show="isWidgetOpened" class="wl-widget-label">{{currentWidget}}
              <i ng-click="toggleWidget(currentWidget)" class="wl-deselect-widget"></i>
            </span>  
          </h5>
          <div ng-show="isWidgetOpened" class="box-widgets">
            <div ng-show="currentWidget == widget" ng-repeat="widget in box.registeredWidgets">
              <img ng-click="embedImageInEditor(item.uri)"ng-src="{{ item.uri }}" ng-repeat="item in widgets[ box.id ][ widget ]" />
            </div>
          </div>
          <div class="selected-entities">
            <span ng-class="'wl-' + entity.mainType" ng-repeat="(id, entity) in selectedEntities[box.id]" class="wl-selected-item">
              {{ entity.label}}
              <i class="wl-deselect-item" ng-click="onSelectedEntityTile(entity, box)"></i>
            </span>
          </div>
        </div>
  			<div class="box-tiles">
          <div ng-transclude></div>
  		  </div>
      </div>	
    """
    link: ($scope, $element, $attrs, $ctrl) ->  	  
  	  
      $scope.currentWidget = undefined
      $scope.isWidgetOpened = false

      $scope.closeWidgets = ()->
        $scope.currentWidget = undefined
        $scope.isWidgetOpened = false

      $scope.hasSelectedEntities = ()->
        Object.keys( $scope.selectedEntities[ $scope.box.id ] ).length > 0

      $scope.embedImageInEditor = (image)->
        $scope.$emit "embedImageInEditor", image

      $scope.toggleWidget = (widget)->
        if $scope.currentWidget is widget
          $scope.currentWidget = undefined
          $scope.isWidgetOpened = false
        else 
          $scope.currentWidget = widget
          $scope.isWidgetOpened = true   
          $scope.$emit "updateWidget", widget, $scope.box.id 
          
    controller: ($scope, $element, $attrs) ->
      
      # Mantain a reference to nested entity tiles $scope
      # TODO manage on scope distruction event
      $scope.tiles = []

      # TODO don't use $parent
      $scope.$parent.boxes[ $scope.box.id ] = $scope

      $scope.deselect = (entity)->
        for tile in $scope.tiles
          tile.isSelected = false if tile.entity.id is entity.id
      
      $scope.relink = (entity, annotationId)->
        for tile in $scope.tiles
          tile.isLinked = (annotationId in tile.entity.occurrences) if tile.entity.id is entity.id
           
      $scope.$watch "annotation", (annotationId) ->
        
        $log.debug "Watching annotation ... New value #{annotationId}"
        $scope.currentWidget = undefined
        $scope.isWidgetOpened = false

        for tile in $scope.tiles
          if annotationId?
            tile.isVisible = (tile.entity.annotations[ annotationId ]?)
            tile.annotationModeOn = true
            tile.isLinked = (annotationId in tile.entity.occurrences)
          else
            tile.isVisible = true
            tile.isLinked = false
            tile.annotationModeOn = false

      ctrl = @
      ctrl.onSelectedTile = (tile)->
        tile.isSelected = !tile.isSelected
        $scope.onSelectedEntityTile tile.entity, $scope.box
      ctrl.addTile = (tile)->
        $scope.tiles.push tile
      ctrl.closeTiles = ()->
        for tile in $scope.tiles
          tile.close()
      
  ])
angular.module('wordlift.editpost.widget.directives.wlEntityForm', [])
.directive('wlEntityForm', ['$log', ($log)->
    restrict: 'E'
    scope:
      entity: '='
      onSubmit: '&'
    template: """
      <form class="wl-entity-form" ng-submit="onSubmit()">
      <div>
          <label>Entity label</label>
          <input type="text" ng-model="entity.label" />
      </div>
      <div>
          <label>Entity type</label>
          <select ng-model="entity.mainType" ng-options="type.id as type.name for type in supportedTypes" ></select>
      </div>
      <div>
          <label>Entity Description</label>
          <textarea ng-model="entity.description" rows="6"></textarea>
      </div>
      <div>
          <label>Entity id</label>
          <input type="text" ng-model="entity.id" />
      </div>
      <div>
          <label>Entity Same as</label>
          <input type="text" ng-model="entity.sameAs" />
      </div>
      <input type="submit" value="save" />
      </form>
    """
    link: ($scope, $element, $attrs, $ctrl) ->  
      $scope.supportedTypes = [
        { id: 'person', name: 'http://schema.org/Person' },
        { id: 'place', name: 'http://schema.org/Place' },
        { id: 'organization', name: 'http://schema.org/Organization' },
        { id: 'event', name: 'http://schema.org/Event' },
        { id: 'creative-work', name: 'http://schema.org/CreativeWork' },
        { id: 'thing', name: 'http://schema.org/Thing' }
      ]
])

angular.module('wordlift.editpost.widget.directives.wlEntityTile', [])
.directive('wlEntityTile', ['$log', ($log)->
    require: '^wlClassificationBox'
    restrict: 'E'
    scope:
      entity: '='
    template: """
  	  <div ng-class="'wl-' + entity.mainType" ng-show="isVisible" class="entity">
  	    <i ng-show="annotationModeOn" ng-class="{ 'wl-linked' : isLinked, 'wl-unlinked' : !isLinked }"></i>
        <i ng-hide="annotationModeOn" ng-class="{ 'wl-selected' : isSelected, 'wl-unselected' : !isSelected }"></i>
        <i class="type"></i>
        <span class="label" ng-click="select()">{{entity.label}}</span>
        <small ng-show="entity.occurrences.length > 0">({{entity.occurrences.length}})</small>
        <i ng-class="{ 'wl-more': isOpened == false, 'wl-less': isOpened == true }" ng-click="toggle()"></i>
  	    <span ng-class="{ 'active' : editingModeOn }" ng-click="toggleEditingMode()" ng-show="isOpened" class="wl-edit-button">Edit</span>
        <div class="details" ng-show="isOpened">
          <p ng-hide="editingModeOn"><img class="thumbnail" ng-src="{{ entity.images[0] }}" />{{entity.description}}</p>
          <wl-entity-form entity="entity" ng-show="editingModeOn" on-submit="toggleEditingMode()"></wl-entity-form>
        </div>

  	  </div>

  	"""
    link: ($scope, $element, $attrs, $boxCtrl) ->				      
      
      # Add tile to related container scope
      $boxCtrl.addTile $scope

      $scope.isOpened = false
      $scope.isVisible = true
      $scope.isSelected = false
      $scope.isLinked = false

      $scope.annotationModeOn = false
      $scope.editingModeOn = false
      
      $scope.toggleEditingMode = ()->
        $scope.editingModeOn = !$scope.editingModeOn

      $scope.open = ()->
      	$scope.isOpened = true
      $scope.close = ()->
      	$scope.isOpened = false  	
      $scope.toggle = ()->
        if !$scope.isOpened 
          $boxCtrl.closeTiles()    
        $scope.isOpened = !$scope.isOpened
        
      $scope.select = ()-> 
        $boxCtrl.onSelectedTile $scope
  ])

angular.module('wordlift.editpost.widget.services.AnalysisService', [])
# Manage redlink analysis responses
.service('AnalysisService', [ '$log', '$http', '$rootScope', ($log, $http, $rootScope)-> 
	
  # Creates a unique ID of the specified length (default 8).
  uniqueId = (length = 8) ->
    id = ''
    id += Math.random().toString(36).substr(2) while id.length < length
    id.substr 0, length

  # Merges two objects by copying overrides param onto the options.
  merge = (options, overrides) ->
    extend (extend {}, options), overrides
  extend = (object, properties) ->
    for key, val of properties
      object[key] = val
    object

  service = 
    _currentAnalysis = {}

  service.createEntity = (params = {}) ->
    # Set the defalut values.
    defaults =
      id: 'local-entity-' + uniqueId 32
      label: ''
      description: ''
      mainType: 'thing' # DefaultType
      types: []
      images: []
      occurrences: []
      annotations: {}
    
    merge defaults, params

  service.createAnnotation = (params = {}) ->
    # Set the defalut values.
    defaults =
      id: 'urn:local-text-annotation-' + uniqueId 32
      text: ''
      start: 0
      end: 0
      entityMatches: []
    
    merge defaults, params
  
  service.parse = (data) ->
    
    # Add id to entity obj
    # Add id to annotation obj
    # Add occurences as a blank array
    # Add annotation references to each entity

    for id, entity of data.entities
      entity.id = id
      entity.occurrences = []
      entity.annotations = {}

    for id, annotation of data.annotations
      annotation.id = id
      for ea in annotation.entityMatches
        data.entities[ ea.entityId ].annotations[ id ] = annotation

    data

  service.perform = ()->
  	$http(
      method: 'get'
      url: 'assets/sample-response.json'
    )
    # If successful, broadcast an *analysisReceived* event.
    .success (data) ->
       $rootScope.$broadcast "analysisPerformed", service.parse( data )

  service

])
# Create the main AngularJS module, and set it dependent on controllers and directives.
angular.module('wordlift.editpost.widget.services.EditorService', [
  'wordlift.editpost.widget.services.AnalysisService'
  ])
# Manage redlink analysis responses
.service('EditorService', [ 'AnalysisService', '$log', '$http', '$rootScope', (AnalysisService, $log, $http, $rootScope)-> 
  
  editor = ->
    tinyMCE.get('content')
    
  disambiguate = ( annotation, entity )->
    ed = editor()
    ed.dom.addClass annotation.id, "disambiguated"
    ed.dom.addClass annotation.id, "wl-#{entity.mainType}"
    discardedItemId = ed.dom.getAttrib annotation.id, "itemid"
    ed.dom.setAttrib annotation.id, "itemid", entity.id
    discardedItemId

  dedisambiguate = ( annotation, entity )->
    ed = editor()
    ed.dom.removeClass annotation.id, "disambiguated"
    ed.dom.removeClass annotation.id, "wl-#{entity.mainType}"
    discardedItemId = ed.dom.getAttrib annotation.id, "itemid"
    ed.dom.setAttrib annotation.id, "itemid", ""
    discardedItemId

  # TODO refactoring with regex
  currentOccurencesForEntity = (entityId) ->
    ed = editor()
    occurrences = []    
    return occurrences if entityId is ""
    annotations = ed.dom.select "span.textannotation"
    for annotation in annotations
      itemId = ed.dom.getAttrib annotation.id, "itemid"
      occurrences.push annotation.id  if itemId is entityId
    occurrences

  $rootScope.$on "analysisPerformed", (event, analysis) ->
    service.embedAnalysis analysis if analysis? and analysis.annotations?
  
  $rootScope.$on "embedImageInEditor", (event, image) ->
    tinyMCE.execCommand 'mceInsertContent', false, "<img src=\"#{image}\" width=\"100%\" />"
  
  $rootScope.$on "entitySelected", (event, entity, annotationId) ->
    # per tutte le annotazioni o solo per quella corrente 
    # recupero dal testo una struttura del tipo entityId: [ annotationId ]
    # non considero solo la entity principale, ma anche le entity modificate
    # il numero di elementi dell'array corrisponde alle occurences
    # l'intero oggetto va salvato sulla proprietà likendAnnotations delle entity
    # o potrebbe sostituire occurences? Fatto questo posso gestire lo stato linked /
    discarded = []
    if annotationId?
      discarded.push disambiguate entity.annotations[ annotationId ], entity
    else    
      for id, annotation of entity.annotations
        $log.debug "Going to disambiguate annotation #{id}"
        discarded.push disambiguate annotation, entity
    
    for entityId in discarded
      if entityId
        occurrences = currentOccurencesForEntity entityId
        $rootScope.$broadcast "updateOccurencesForEntity", entityId, occurrences

    occurrences = currentOccurencesForEntity entity.id
    $rootScope.$broadcast "updateOccurencesForEntity", entity.id, occurrences
      
  $rootScope.$on "entityDeselected", (event, entity, annotationId) ->
    discarded = []
    if annotationId?
      dedisambiguate entity.annotations[ annotationId ], entity
    else   
      for id, annotation of entity.annotations
        dedisambiguate annotation, entity
    
    for entityId in discarded
      if entityId
        occurrences = currentOccurencesForEntity entityId
        $rootScope.$broadcast "updateOccurencesForEntity", entityId, occurrences
        
    occurrences = currentOccurencesForEntity entity
    $rootScope.$broadcast "updateOccurencesForEntity", entity.id, occurrences
        
  service =
    # Create a textAnnotation starting from the current selection
    createTextAnnotationFromCurrentSelection: ()->
      # A reference to the editor.
      ed = editor()
      # If the current selection is collapsed / blank, then nothing to do
      if ed.selection.isCollapsed()
        $log.warn "Invalid selection! The text annotation cannot be created"
        return 
      # Retrieve the selected text
      # Notice that toString() method of browser native selection obj is used
      text = "#{ed.selection.getSel()}"
      # Create the text annotation
      textAnnotation = AnalysisService.createAnnotation { 
        text: text
      }

      # Prepare span wrapper for the new text annotation
      textAnnotationSpan = "<span id=\"#{textAnnotation.id}\" class=\"textannotation selected\">#{ed.selection.getContent()}</span>"
      # Update the content within the editor
      ed.selection.setContent(textAnnotationSpan)
      # Retrieve the current heml content
      content = ed.getContent({format: "html"})
      # Create a Traslator instance
      traslator =  Traslator.create content
      # Retrieve the index position of the new span
      htmlPosition = content.indexOf(textAnnotationSpan);
      # Detect the coresponding text position
      textPosition = traslator.html2text(htmlPosition)
          
      # Set start & end text annotation properties
      textAnnotation.start = textPosition 
      textAnnotation.end = textAnnotation.start + text.length
          
      $log.debug "New text annotation created!"
      $log.debug textAnnotation
          
      # Send a message about the new textAnnotation.
      $rootScope.$broadcast 'textAnnotationAdded', textAnnotation

    # Select annotation with a id annotationId if available
    selectAnnotation: (annotationId)->
      # A reference to the editor.
      ed = editor()
      # Unselect all annotations 
      for annotation in ed.dom.select "span.textannotation"
        ed.dom.removeClass annotation.id, "selected"
      # Notify it
      $rootScope.$broadcast 'textAnnotationClicked', undefined
      # If current is a text annotation, then select it and notify
      if ed.dom.hasClass annotationId, "textannotation"
        ed.dom.addClass annotationId, "selected"
        $rootScope.$broadcast 'textAnnotationClicked', annotationId

    # Embed the provided analysis in the editor.
    embedAnalysis: (analysis) =>
      # A reference to the editor.
      ed = editor()
      # Get the TinyMCE editor html content.
      html = ed.getContent format: 'raw'
      # Find existing entities.
      # entities = findEntities html

      # Preselect entities found in html.
      # AnalysisService.preselect analysis, entities

      # Remove existing text annotations (the while-match is necessary to remove nested spans).
      while html.match(/<(\w+)[^>]*\sclass="textannotation[^"]*"[^>]*>([^<]+)<\/\1>/gim, '$2')
        html = html.replace(/<(\w+)[^>]*\sclass="textannotation[^"]*"[^>]*>([^<]+)<\/\1>/gim, '$2')

      # Prepare a traslator instance that will traslate Html and Text positions.
      traslator = Traslator.create html

      # Add text annotations to the html (skip those text annotations that don't have entity annotations).
      for annotationId, annotation of analysis.annotations # when 0 < Object.keys(textAnnotation.entityAnnotations).length
        
        entity = analysis.entities[ annotation.entityMatches[0].entityId ]
        element = "<span id=\"#{annotationId}\" class=\"textannotation\">"
        
        # Finally insert the HTML code.
        traslator.insertHtml element, text: annotation.start
        traslator.insertHtml '</span>', text: annotation.end

      # Update the editor Html code.
      isDirty = ed.isDirty()
      ed.setContent traslator.getHtml(), format: 'raw'
      ed.isNotDirty = not isDirty

  service
])
angular.module('wordlift.editpost.widget.services.ImageSuggestorDataRetrieverService', [])
# Manage redlink analysis responses
.service('ImageSuggestorDataRetrieverService', [ '$log', '$http', '$rootScope', ($log, $http, $rootScope)-> 
  
  service = {}
  service.loadData = (entities)->
    items = []
    for id, entity of entities
      for image in entity.images
        items.push { 'uri': image }
    items

  service

])
angular.module('wordlift.editpost.widget.providers.ConfigurationProvider', [])
.provider("configuration", ()->
  
  boxes = undefined
  
  provider =
    setBoxes: (items)->
      boxes = items
    $get: ()->
      { boxes: boxes }

  provider
)


# Set the well-known $ reference to jQuery.
$ = jQuery

# Create the main AngularJS module, and set it dependent on controllers and directives.
angular.module('wordlift.editpost.widget', [

	'wordlift.editpost.widget.providers.ConfigurationProvider', 
	'wordlift.editpost.widget.controllers.EditPostWidgetController', 
	'wordlift.editpost.widget.directives.wlClassificationBox', 
	'wordlift.editpost.widget.directives.wlEntityForm', 
	'wordlift.editpost.widget.directives.wlEntityTile', 
	'wordlift.editpost.widget.services.AnalysisService', 
	'wordlift.editpost.widget.services.EditorService', 
	'wordlift.editpost.widget.services.ImageSuggestorDataRetrieverService' 		
	
	])

.config((configurationProvider)->
  configurationProvider.setBoxes window.wordlift.classificationBoxes
)

$(
  container = $("""
  	<div id="wordlift-edit-post-wrapper" ng-controller="EditPostWidgetController">
  		<div ng-click="createTextAnnotationFromCurrentSelection()">
        <span class="wl-new-entity-button" ng-class="{ 'selected' : !isSelectionCollapsed }">
          <i class="wl-annotation-label-icon"></i> add entity 
        </span>
      </div>
      <div ng-show="annotation">
        <h4 class="wl-annotation-label">
          <i class="wl-annotation-label-icon"></i>
          {{ analysis.annotations[ annotation ].text }} 
          <small>[ {{ analysis.annotations[ annotation ].start }}, {{ analysis.annotations[ annotation ].end }} ]</small>
          <i class="wl-annotation-label-remove-icon" ng-click="selectAnnotation(undefined)"></i>
        </h4>
        <wl-entity-form entity="newEntity" on-submit="addNewEntityToAnalysis()"ng-show="analysis.annotations[annotation].entityMatches.length == 0"></wl-entity-form>
      </div>
      <wl-classification-box ng-repeat="box in configuration.boxes">
        <wl-entity-tile entity="entity" ng-repeat="entity in analysis.entities | entityTypeIn:box.registeredTypes"></wl-entity>
      </wl-classification-box>
    </div>
  """)
  .appendTo('#dx')

injector = angular.bootstrap $('#wordlift-edit-post-wrapper'), ['wordlift.editpost.widget']

# Add WordLift as a plugin of the TinyMCE editor.
  tinymce.PluginManager.add 'wordlift', (editor, url) ->
    # Perform analysis once tinymce is loaded
    editor.onLoadContent.add((ed, o) ->
      injector.invoke(['AnalysisService', '$rootScope',
       (AnalysisService, $rootScope) ->
        # execute the following commands in the angular js context.
        $rootScope.$apply(->    
          AnalysisService.perform()
        )
      ])
    )

    # Fires when the user changes node location using the mouse or keyboard in the TinyMCE editor.
    editor.onNodeChange.add (editor, e) ->        
      injector.invoke(['$rootScope', ($rootScope) ->
        # execute the following commands in the angular js context.      
        $rootScope.$apply(->
          $rootScope.$broadcast 'isSelectionCollapsed', editor.selection.isCollapsed()
        )
      ])
              
    # this event is raised when a textannotation is selected in the TinyMCE editor.
    editor.onClick.add (editor, e) ->
      injector.invoke(['EditorService','$rootScope', (EditorService, $rootScope) ->
        # execute the following commands in the angular js context.
        $rootScope.$apply(->          
          EditorService.selectAnnotation e.target.id 
        )
      ])
)
