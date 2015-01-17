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
# Set the well-known $ reference to jQuery.
$ = jQuery

# Create the main AngularJS module, and set it dependent on controllers and directives.
angular.module('wordlift.core', [])
# Manage redlink analysis responses
.service('EditorService', [ '$log', '$http', '$rootScope', ($log, $http, $rootScope)-> 
  
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
# Manage redlink analysis responses
.service('AnalysisService', [ '$log', '$http', '$rootScope', ($log, $http, $rootScope)-> 
	
  service = 
    _currentAnalysis = {}

  service.parse = (data) ->
    
    for id, entity of data.entities
      entity.occurrences = 0
      entity.id = id
      entity.annotations = {}
      entity.isRelatedToAnnotation = (annotationId)->
        if @.annotations[ annotationId ]? then true else false

    for id, annotation of data.annotations
      for ea in annotation.entityMatches
      	data.entities[ ea.entityId ].annotations[ id ] = annotation

    for id, annotation of data.annotations
      annotation.id = id

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

# Manage redlink analysis responses
.service('ConfigurationService', [ '$log', '$http', '$rootScope', ($log, $http, $rootScope)-> 
	
  service = 
    _configuration = {}

  service.loadConfiguration = ()->
  	$http(
      method: 'get'
      url: 'assets/sample-widget-configuration.json'
    )
    .success (data) ->
      $rootScope.$broadcast "configurationLoaded", data
  service

])

# Manage redlink analysis responses
.service('ImageSuggestorDataRetriever', [ '$log', '$http', '$rootScope', ($log, $http, $rootScope)-> 
  
  service = {}
  service.loadData = (entities)->
    items = []
    for id, entity of entities
      for image in entity.images
        items.push { 'uri': image }
    items

  service

])
# Manage redlink analysis responses
.controller('EditPostWidgetController', [ '$log', '$scope', '$rootScope', '$injector', ($log, $scope, $rootScope, $injector)-> 

  $scope.configuration = []
  $scope.analysis = {}
  $scope.selectedEntities = {}
  $scope.widgets = {}
  $scope.annotation = undefined
  $scope.boxes = []

  $scope.addBox = (scope, id)->
    $scope.boxes[id] = scope
    
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
        

  $scope.$on "configurationLoaded", (event, configuration) ->
    for box in configuration.classificationBoxes
      $scope.selectedEntities[ box.id ] = {}
      $scope.widgets[ box.id ] = {}
      for widget in box.registeredWidgets
        $scope.widgets[ box.id ][ widget ] = []
              
    $scope.configuration = configuration

  $scope.$on "textAnnotationClicked", (event, annotationId) ->
    $log.debug "click on #{annotationId}"
    $scope.annotation = annotationId

  $scope.$on "analysisPerformed", (event, analysis) ->
    $scope.analysis = analysis

  $scope.updateWidget = (widget, scope)->
    # Retrieve the proper DatarRetriever
    retriever = $injector.get "#{widget}DataRetriever"
    # Load widget items
    items = retriever.loadData $scope.selectedEntities[ scope ]
    # Assign items to the widget scope
    $scope.widgets[ scope ][ widget ] = items
    
  $scope.onSelectedEntityTile = (entity, scope)->
  	$log.debug "Entity tile selected for entity #{entity.id} within '#{scope.id}' scope"
  	if not $scope.selectedEntities[ scope.id ][ entity.id ]?
      $scope.selectedEntities[ scope.id ][ entity.id ] = entity
      
      # Emit an event to communicate with the EditorService
      $scope.$emit "entitySelected", entity, $scope.annotation
  	else
      # TODO Any related annotation has to be reset just if this is the last related instance 
      $scope.$emit "entityDeselected", entity, $scope.annotation  
      delete $scope.selectedEntities[ scope.id ][ entity.id ]
      $scope.boxes[ scope.id ].deselect entity
      
])
.directive('wlClassificationBox', ['$log', ($log)->
    restrict: 'E'
    scope: true
    template: """
    	<div class="classification-box">
    		<div class="box-header">
          <h5 class="label">{{box.label}}
            <span class="wl-suggestion-tools">
            <i ng-class="'wl-' + widget" ng-click="toggleWidget(widget)" ng-repeat="widget in box.registeredWidgets" class="wl-widget-icon"></i>
            </span>  
          </h5>

          <span ng-class="'wl-' + entity.mainType" ng-repeat="(id, entity) in selectedEntities[box.id]" class="wl-selected-item">
            {{ entity.label}}
            <i class="wl-deselect-item" ng-click="onSelectedEntityTile(entity, box)"></i>
          </span>
        </div>
        <div ng-show="isWidgetOpened" class="box-widgets">
            <div ng-show="currentWidget == widget" ng-repeat="widget in box.registeredWidgets">
              <img ng-click="embedImageInEditor(item.uri)"ng-src="{{ item.uri }}" ng-repeat="item in widgets[ box.id ][ widget ]" />
            </div>
        </div>
  			<div ng-hide="isWidgetOpened" class="box-tiles">
        <wl-entity-tile notify="onSelectedEntityTile(entity.id, box)" entity="entity" ng-repeat="entity in entities"></wl-entity>
  		  </div>
      </div>	
    """
    link: ($scope, $element, $attrs, $ctrl) ->  	  
  	  
      $scope.entities = {}
      $scope.currentWidget = undefined
      $scope.isWidgetOpened = false

      $scope.embedImageInEditor = (image)->
        $scope.$emit "embedImageInEditor", image

      $scope.toggleWidget = (widget)->
        if $scope.currentWidget is widget
          $scope.currentWidget = undefined
          $scope.isWidgetOpened = false
        else 
          $scope.updateWidget widget, $scope.box.id 
          $scope.currentWidget = widget
          $scope.isWidgetOpened = true   

      for id, entity of $scope.analysis.entities
        if entity.mainType in $scope.box.registeredTypes
          $scope.entities[ id ] = entity

    controller: ($scope, $element, $attrs) ->
      
      # Mantain a reference to nested entity tiles $scope
      # TODO manage on scope distruction event
      $scope.tiles = []

      $scope.addBox $scope, $scope.box.id

      $scope.deselect = (entity)->
        for tile in $scope.tiles
          tile.isSelected = false if tile.entity.id is entity.id
      
      $scope.relink = (entity, annotationId)->
        for tile in $scope.tiles
          tile.isLinked = (annotationId in tile.entity.occurrences) if tile.entity.id is entity.id
           
      $scope.$watch "annotation", (annotationId) ->
        
        $scope.currentWidget = undefined
        $scope.isWidgetOpened = false
        
        for tile in $scope.tiles
          if analysis = annotationId?
            tile.isVisible = tile.entity.isRelatedToAnnotation( annotationId ) 
            tile.annotationModeOn = true
            tile.isLinked = (annotationId in tile.entity.occurrences)
          else
            tile.isVisible = true
            tile.isLinked = false
            tile.annotationModeOn = false
            
      ctrl =
        onSelectedTile: (tile)->
          tile.isSelected = !tile.isSelected
          $scope.onSelectedEntityTile tile.entity, $scope.box
        addTile: (tile)->
          $scope.tiles.push tile
        closeTiles: ()->
          for tile in $scope.tiles
          	tile.close()
      ctrl
  ])
.directive('wlEntityForm', ['$log', ($log)->
    restrict: 'E'
    scope:
      entity: '='
    template: """
      <form class="wl-entity-form">
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
      </form>
    """
    link: ($scope, $element, $attrs, $ctrl) ->  
      $scope.supportedTypes = [
        { id: 'person', name: 'http://schema.org/Person' },
        { id: 'place', name: 'http://schema.org/Place' },
        { id: 'organization', name: 'http://schema.org/Organization' },
        { id: 'event', name: 'http://schema.org/Event' },
        { id: 'creative-work', name: 'http://schema.org/CreativeWork' }

      ]
])
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
          <wl-entity-form entity="entity" ng-show="editingModeOn"></wl-entity-form>
        </div>

  	  </div>

  	"""
    link: ($scope, $element, $attrs, $ctrl) ->				      
      
      # Add tile to related container scope
      $ctrl.addTile $scope

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
          $ctrl.closeTiles()    
        $scope.isOpened = !$scope.isOpened
        
      $scope.select = ()-> 
        $ctrl.onSelectedTile $scope
  ])
$(
  container = $("""
  	<div id="wordlift-edit-post-wrapper" ng-controller="EditPostWidgetController">
  		<div ng-show="annotation">
        <h4 class="wl-annotation-label">
          <i class="wl-annotation-label-icon"></i>
          {{ analysis.annotations[ annotation ].text }}
          <small>[ {{ analysis.annotations[ annotation ].start }}, {{ analysis.annotations[ annotation ].end }} ]</small>
        </h4></div>
      <wl-classification-box ng-repeat="box in configuration.classificationBoxes"></wl-classification-box>
    </div>

  """)
  .appendTo('#dx')

injector = angular.bootstrap $('body'), ['wordlift.core']


# Add WordLift as a plugin of the TinyMCE editor.
  tinymce.PluginManager.add 'wordlift', (editor, url) ->
    # Perform analysis once tinymce is loaded
    editor.onLoadContent.add((ed, o) ->
      injector.invoke(['ConfigurationService', 'AnalysisService', 'EditorService', '$rootScope',
       (ConfigurationService, AnalysisService, EditorService, $rootScope) ->
        # execute the following commands in the angular js context.
        $rootScope.$apply(->
          
          AnalysisService.perform()
          ConfigurationService.loadConfiguration()
        )
      ])
    )
    # Add a WordLift button the TinyMCE editor.
    # TODO Disable the new button as default
    editor.addButton 'wordlift_add_entity',
      classes: 'widget btn wordlift_add_entity'
      text: ' ' # the space is necessary to avoid right spacing on TinyMCE 4
      tooltip: 'Insert entity'
      onclick: ->

        #injector.invoke(['EditorService','$rootScope', (EditorService, $rootScope) ->
          # execute the following commands in the angular js context.
        #  $rootScope.$apply(->
            #EditorService.createTextAnnotationFromCurrentSelection()
        #  )
        #])

    # Add a WordLift button the TinyMCE editor.
    editor.addButton 'wordlift',
      classes: 'widget btn wordlift'
      text: ' ' # the space is necessary to avoid right spacing on TinyMCE 4
      tooltip: 'Analyse'

    # When the editor is clicked, the [EditorService.analyze](app.services.EditorService.html#analyze) method is invoked.
      onclick: ->
        #injector.invoke(['EditorService', '$rootScope', '$log', (EditorService, $rootScope, $log) ->
        #  $rootScope.$apply(->
            # Get the html content of the editor.
            #html = editor.getContent format: 'raw'

            # Get the text content from the Html.
            #text = Traslator.create(html).getText()

            # $log.info "onclick [ html :: #{html} ][ text :: #{text} ]"
            # Send the text content for analysis.
            #EditorService.analyze text
        #  )
        #])

    # TODO: move this outside of this method.
    # this event is raised when a textannotation is selected in the TinyMCE editor.
    editor.onClick.add (editor, e) ->
      injector.invoke(['$rootScope', ($rootScope) ->
        # execute the following commands in the angular js context.
        $rootScope.$apply(->
          
          for annotation in editor.dom.select "span.textannotation"
            if annotation.id is e.target.id
              if editor.dom.hasClass annotation.id, "selected"
                editor.dom.removeClass annotation.id, "selected"
                # send a message to clear current text annotation scope
                $rootScope.$broadcast 'textAnnotationClicked', undefined
              else
                editor.dom.addClass annotation.id, "selected"
                # send a message about the currently clicked annotation.
                $rootScope.$broadcast 'textAnnotationClicked', e.target.id
            else 
             editor.dom.removeClass annotation.id, "selected"          
        )
      ])
)