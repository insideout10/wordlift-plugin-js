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
angular.module('wordlift.ui.carousel', [])
.directive('wlCarousel', ['$window', '$log', ($window, $log)->
  restrict: 'A'
  scope: true
  transclude: true      
  template: """
      <div class="wl-carousel">
        <div class="wl-panes" style="width:{{panesWidth}}px; left:{{position}}px;" ng-transclude ng-swipe-right="next()"></div>
        <div class="wl-carousel-arrow wl-prev" ng-click="prev()" ng-show="currentPaneIndex > 0">
          <i class="wl-angle-left" />
        </div>
        <div class="wl-carousel-arrow wl-next" ng-click="next()" ng-hide="(currentPaneIndex + visibleElements()) == panes.length">
          <i class="wl-angle-right" />
        </div>
      </div>      
  """
  controller: ($scope, $element, $attrs) ->
      
    w = angular.element $window

    $scope.visibleElements = ()->
      if $element.width() > 460
        return 3
      if $element.width() > 1024
        return 5
      return 1

    $scope.itemWidth =  $element.width() / $scope.visibleElements();
    $scope.panesWidth = undefined
    $scope.panes = []
    $scope.position = 0;
    $scope.currentPaneIndex = 0

    $scope.next = ()->
      $scope.position = $scope.position - $scope.itemWidth
      $scope.currentPaneIndex = $scope.currentPaneIndex + 1
    $scope.prev = ()->
      $scope.position = $scope.position + $scope.itemWidth
      $scope.currentPaneIndex = $scope.currentPaneIndex - 1

    $scope.setPanesWrapperWidth = ()->
      $scope.panesWidth = $scope.panes.length * $scope.itemWidth

    w.bind 'resize', ()->
        
      $scope.itemWidth =  $element.width() / $scope.visibleElements();
      $scope.setPanesWrapperWidth()
      for pane in $scope.panes
        pane.scope.setWidth $scope.itemWidth
      $scope.$apply()
      $scope.position = 0;
    
    ctrl = @
    ctrl.registerPane = (scope, element)->
      # Set the proper width for the element
      scope.setWidth $scope.itemWidth
        
      pane =
        'scope': scope
        'element': element

      $scope.panes.push pane
      $scope.setPanesWrapperWidth()

    ctrl.unregisterPane = (scope)->
        
      unregisterPaneIndex = undefined
      for pane, index in $scope.panes
        if pane.scope.$id is scope.$id
          unregisterPaneIndex = index

      if unregisterPaneIndex
        $scope.panes.splice unregisterPaneIndex, 1
      $scope.setPanesWrapperWidth()
])
.directive('wlCarouselPane', ['$log', ($log)->
  require: '^wlCarousel'
  restrict: 'EA'
  transclude: true 
  template: """
      <div ng-transclude></div>
  """
  link: ($scope, $element, $attrs, $ctrl) ->

    $log.debug "Going to add carousel pane with id #{$scope.$id} to carousel"
    $element.addClass "wl-carousel-item"
      
    $scope.setWidth = (size)->
      $element.css('width', "#{size}px")

    $scope.$on '$destroy', ()->
      $ctrl.unregisterPane $scope

    $ctrl.registerPane $scope, $element
])
angular.module('wordlift.editpost.widget.controllers.EditPostWidgetController', [
  'wordlift.editpost.widget.services.AnalysisService'
  'wordlift.editpost.widget.services.EditorService'
  'wordlift.editpost.widget.providers.ConfigurationProvider'
])
.filter('filterEntitiesByTypesAndRelevance', [ '$log', ($log)->
  return (items, types)->
    
    filtered = []
    
    if not items? 
      return filtered

    treshold = Math.floor ( (1/120) * Object.keys(items).length ) + 0.75 
    
    for id, entity of items
      if  entity.mainType in types
        
        annotations_count = Object.keys( entity.annotations ).length
        if annotations_count > treshold and entity.confidence is 1
          filtered.push entity
          continue
        if entity.occurrences.length > 0
          filtered.push entity
          continue
        if entity.id.match(/redlink/)
          filtered.push entity
        
        # TODO se è una entità di wordlift la mostro

    filtered

])

.filter('filterEntitiesByTypes', [ '$log', ($log)->
  return (items, types)->
    
    filtered = []
    
    for id, entity of items
      if  entity.mainType in types
        filtered.push entity
    filtered

])

.filter('isEntitySelected', [ '$log', ($log)->
  return (items)->
    
    filtered = []

    for id, entity of items
      if entity.occurrences.length > 0
        filtered.push entity
    
    filtered
])
.controller('EditPostWidgetController', [ 'EditorService', 'AnalysisService', 'configuration', '$log', '$scope', '$rootScope', '$injector', (EditorService, AnalysisService, configuration, $log, $scope, $rootScope, $injector)-> 

  $scope.analysis = undefined
  $scope.newEntity = AnalysisService.createEntity()
  $scope.selectedEntities = {}
  $scope.widgets = {}
  $scope.annotation = undefined
  $scope.boxes = []
  $scope.images = {}
  $scope.isSelectionCollapsed = true
  $scope.configuration = configuration

  for box in $scope.configuration.classificationBoxes
    $scope.selectedEntities[ box.id ] = {}
    $scope.widgets[ box.id ] = {}

    for widget in box.registeredWidgets
      $scope.widgets[ box.id ][ widget ] = []
              
  # Delegate to EditorService
  $scope.createTextAnnotationFromCurrentSelection = ()->
    EditorService.createTextAnnotationFromCurrentSelection()
  # Delegate to EditorService
  $scope.selectAnnotation = (annotationId)->
    EditorService.selectAnnotation annotationId
  $scope.isEntitySelected = (entity, box)->
    return $scope.selectedEntities[ box.id ][ entity.id ]?
  $scope.isLinkedToCurrentAnnotation = (entity)->
    return ($scope.annotation in entity.occurrences)

  $scope.addNewEntityToAnalysis = ()->
    
    # Keep the sameAs as Tmp id if available
    if $scope.newEntity.sameAs
      $scope.newEntity.sameAs = [ $scope.newEntity.sameAs ]
    
    delete $scope.newEntity.suggestedSameAs
    
    $log.debug $scope.newEntity
    # Add new entity to the analysis
    $scope.analysis.entities[ $scope.newEntity.id ] = $scope.newEntity
    annotation = $scope.analysis.annotations[ $scope.annotation ]
    annotation.entityMatches.push { entityId: $scope.newEntity.id, confidence: 1 }
    $scope.analysis.entities[ $scope.newEntity.id ].annotations[ annotation.id ] = annotation
    $scope.analysis.annotations[ $scope.annotation ].entities[ $scope.newEntity.id ] = $scope.newEntity
    
    # Create new entity object
    $scope.newEntity = AnalysisService.createEntity()

  $scope.$on "isSelectionCollapsed", (event, status) ->
    $scope.isSelectionCollapsed = status

  $scope.$on "updateOccurencesForEntity", (event, entityId, occurrences) ->
    
    $log.debug "Occurrences #{occurrences.length} for #{entityId}"
    $scope.analysis.entities[ entityId ].occurrences = occurrences
    
    if occurrences.length is 0
      for box, entities of $scope.selectedEntities
        delete $scope.selectedEntities[ box ][ entityId ]

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
    # Set the annotation id as id for the new entity
    # $scope.newEntity.id = annotation.id
    # Ask for SameAs suggestions
    AnalysisService.getSuggestedSameAs annotation.text

  $scope.$on "sameAsRetrieved", (event, sameAs) ->
    $log.debug "Retrieved sameAs #{sameAs}"
    $scope.newEntity.suggestedSameAs = sameAs
  
  $scope.$on "analysisPerformed", (event, analysis) -> 
    $scope.analysis = analysis
    # Preselect 
    for box in $scope.configuration.classificationBoxes
      for entityId in box.selectedEntities  
        if entity = analysis.entities[ entityId ]
          $scope.selectedEntities[ box.id ][ entityId ] = analysis.entities[ entityId ]
          for uri in entity.images
            $scope.images[ uri ] = entity.label
        else
          $log.warn "Entity with id #{entityId} should be linked to #{box.id} but is missing"

  $scope.onSelectedEntityTile = (entity, scope)->
    $log.debug "Entity tile selected for entity #{entity.id} within '#{scope.id}' scope"
    
    # Close all opened widgets ...
    for id, box of $scope.boxes
      box.closeWidgets()
    
    if not $scope.selectedEntities[ scope.id ][ entity.id ]?
      $scope.selectedEntities[ scope.id ][ entity.id ] = entity
      for uri in entity.images
        $scope.images[ uri ] = entity.label
      
      $scope.$emit "entitySelected", entity, $scope.annotation
    else
      for uri in entity.images
        delete $scope.images[ uri ]
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
          <h5 class="label">{{box.label}}</h5>
          <div class="selected-entities">
            <span ng-class="'wl-' + entity.mainType" ng-repeat="(id, entity) in selectedEntities[box.id]" class="wl-selected-item">
              {{ entity.label}}
              <i class="wl-deselect-item" ng-click="onSelectedEntityTile(entity, box)"></i>
            </span>
            <div class="clear" /> 
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
          $scope.updateWidget widget, $scope.box.id 
          
    controller: ($scope, $element, $attrs) ->
      
      # Mantain a reference to nested entity tiles $scope
      # TODO manage on scope distruction event
      $scope.tiles = []

      $scope.boxes[ $scope.box.id ] = $scope

      $scope.$watch "annotation", (annotationId) ->
        
        $scope.currentWidget = undefined
        $scope.isWidgetOpened = false
            
      ctrl = @
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
      <div name="wordlift" class="wl-entity-form">
      <div ng-show="entity.images.length > 0">
          <img ng-src="{{entity.images[0]}}" />
      </div>
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
      <div ng-show="checkEntityId(entity.id)">
          <label>Entity Id</label>
          <input type="text" ng-model="entity.id" disabled="true" />
      </div>
      <div class="wl-suggested-sameas-wrapper">
          <label>Entity Same as (*)</label>
          <input type="text" ng-model="entity.sameAs" />
          <h5 ng-show="entity.suggestedSameAs.length > 0">same as suggestions</h5>
          <div ng-click="setSameAs(sameAs)" ng-class="{ 'active': entity.sameAs == sameAs }" class="wl-sameas" ng-repeat="sameAs in entity.suggestedSameAs">
            {{sameAs}}
          </div>
      </div>
      
      <div class="wl-submit-wrapper">
        <span class="button button-primary" ng-click="onSubmit()">Save</span>
      </div>

      </div>
    """
    link: ($scope, $element, $attrs, $ctrl) ->  

      $scope.setSameAs = (uri)->
        $scope.entity.sameAs = uri
      
      $scope.checkEntityId = (uri)->
        /^(f|ht)tps?:\/\//i.test(uri)

      # TMP
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
      isSelected: '='
      onEntitySelect: '&'
    template: """
  	  <div ng-class="'wl-' + entity.mainType" class="entity">
        <div class="entity-header">
  	      
          <i ng-click="onEntitySelect()" ng-hide="annotation" ng-class="{ 'wl-selected' : isSelected, 'wl-unselected' : !isSelected }"></i>
          <i ng-click="onEntitySelect()" class="type"></i>
          <span class="label" ng-click="onEntitySelect()">{{entity.label}}</span>

          <small ng-show="entity.occurrences.length > 0">({{entity.occurrences.length}})</small>
          <span ng-show="isInternal()">*</span>  
          <i ng-class="{ 'wl-more': isOpened == false, 'wl-less': isOpened == true }" ng-click="toggle()"></i>
  	    </div>
        <div class="details" ng-show="isOpened">
          <wl-entity-form entity="entity" on-submit="toggle()"></wl-entity-form>
        </div>
  	  </div>
  	"""
    link: ($scope, $element, $attrs, $boxCtrl) ->				      
      
      # Add tile to related container scope
      $boxCtrl.addTile $scope

      $scope.isOpened = false
      
      $scope.isInternal = ()->
        if $scope.entity.id.match /redlink/
          return true
        return false 
      
      $scope.open = ()->
      	$scope.isOpened = true
      $scope.close = ()->
      	$scope.isOpened = false  	
      $scope.toggle = ()->
        if !$scope.isOpened 
          $boxCtrl.closeTiles()    
        $scope.isOpened = !$scope.isOpened
        
  ])

angular.module('wordlift.editpost.widget.directives.wlEntityInputBox', [])
# The wlEntityInputBoxes prints the inputs and textareas with entities data.
.directive('wlEntityInputBox', ->
    restrict: 'E'
    scope:
      entity: '='
    template: """
        <div>

          <input type='text' name='wl_entities[{{entity.id}}][uri]' value='{{entity.id}}'>
          <input type='text' name='wl_entities[{{entity.id}}][label]' value='{{entity.label}}'>
          <textarea name='wl_entities[{{entity.id}}][description]'>{{entity.description}}</textarea>
          <input type='text' name='wl_entities[{{entity.id}}][main_type]' value='wl-{{entity.mainType}}'>

          <input ng-repeat="type in entity.types" type='text'
          	name='wl_entities[{{entity.id}}][type][]' value='{{type}}' />
          <input ng-repeat="image in entity.images" type='text'
            name='wl_entities[{{entity.id}}][image][]' value='{{image}}' />
          <input ng-repeat="sameAs in entity.sameAs" type='text'
            name='wl_entities[{{entity.id}}][sameas][]' value='{{sameAs}}' />

      	</div>
    """
  )
angular.module('wordlift.editpost.widget.services.AnalysisService', [])
# Manage redlink analysis responses
.service('AnalysisService', [ 'configuration', '$log', '$http', '$rootScope', (configuration, $log, $http, $rootScope)-> 
	
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
 
  findAnnotation = (annotations, start, end) ->
    return annotation for id, annotation of annotations when annotation.start is start and annotation.end is end

  service = 
    _currentAnalysis = {}

  service._supportedTypes = []
  service._defaultType = "thing"
  
  # Retrieve supported type from current classification boxes configuration
  for box in configuration.classificationBoxes
    for type in box.registeredTypes
      if type not in service._supportedTypes
        service._supportedTypes.push type

  service.createEntity = (params = {}) ->
    # Set the defalut values.
    defaults =
      id: 'local-entity-' + uniqueId 32
      label: ''
      description: ''
      mainType: 'thing' # DefaultType
      types: []
      images: []
      confidence: 1
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
      entities: []
      entityMatches: []
    
    merge defaults, params
  
  service.parse = (data) ->
    
    # Add local entities
    # Add id to entity obj
    # Add id to annotation obj
    # Add occurences as a blank array
    # Add annotation references to each entity
    for id, localEntity of configuration.entities
      if data.entities[ id ]?
        $log.debug "LocalEntity #{id} found into the analysis"
      else
        $log.debug "Going to add localEntity #{id} to the analysis"
        data.entities[ id ] = localEntity

    for id, entity of data.entities
      
      if not entity.label
        $log.warn "Label missing for entity #{id}"
      if not entity.description
        $log.warn "Description missing for entity #{id}"
        
      if entity.mainType not in @._supportedTypes
        $log.warn "Schema.org type #{entity.mainType} for entity #{id} is not supported from current classification boxes configuration"
        entity.mainType = @._defaultType
        $log.debug "Schema.org type overridden for entity #{id}"
        
      entity.id = id
      entity.occurrences = []
      entity.annotations = {}
      entity.confidence = 1 

    for id, annotation of data.annotations
      annotation.id = id
      annotation.entities = {}
      
      for ea, index in annotation.entityMatches
        
        if not data.entities[ ea.entityId ].label 
          data.entities[ ea.entityId ].label = annotation.text
          $log.debug "Missing label retrived from related annotation for entity #{ea.entityId}"

        data.entities[ ea.entityId ].annotations[ id ] = annotation
        data.annotations[ id ].entities[ ea.entityId ] = data.entities[ ea.entityId ]

    # TODO move this calculation on the server
    for id, entity of data.entities
      for annotationId, annotation of data.annotations
        local_confidence = 1
        for em in annotation.entityMatches  
          if em.entityId? and em.entityId is id
            local_confidence = em.confidence
        entity.confidence = entity.confidence * local_confidence
    
    data

  service.getSuggestedSameAs = (content)->
  
    promise = @._innerPerform content
    # If successful, broadcast an *sameAsReceived* event.
    .success (data) ->
      
      suggestions = []

      for id, entity of data.entities
        if id.startsWith('http')
          suggestions.push id
      
      $rootScope.$broadcast "sameAsRetrieved", suggestions

    .error (data, status) ->
       $log.warn "Error on same as retrieving, statut #{status}"
       $rootScope.$broadcast "sameAsRetrieved", []

    
  service._innerPerform = (content)->

    $log.info "Start to performing analysis"
    $log.debug content

    if not content?
      $log.warn "content missing: nothing to do"
      return

    return $http(
      method: 'post'
      url: ajaxurl + '?action=wordlift_analyze'
      data: content      
    )
  
  service.perform = (content)->
    
    promise = @._innerPerform content
    # If successful, broadcast an *analysisReceived* event.
    .success (data) ->
      
      if typeof data is 'string'
        $log.warn "Invalid data returned"
        $log.debug data
        return

       $rootScope.$broadcast "analysisPerformed", service.parse( data )
    .error (data, status) ->
       $log.warn "Error on analysis, statut #{status}"

  # Preselect entity annotations in the provided analysis using the provided collection of annotations.
  service.preselect = (analysis, annotations) ->

    # Find the existing entities in the html
    for annotation in annotations
      # Find the proper annotation  
      textAnnotation = findAnnotation analysis.annotations, annotation.start, annotation.end
      
      # If there is no textAnnotation then create it and add to the current analysis
      if not textAnnotation?
        $log.debug "There is no annotation with start #{annotation.start} and end #{annotation.end}"
        textAnnotation = @createAnnotation({
          start: annotation.start
          end: annotation.end
          text: annotation.label
          })
        analysis.annotations[ textAnnotation.id ] = textAnnotation
        
      # Look for the entity in the current analysis result
      # Local entities are merged previously during the analysis parsing
      # Local entities have higher priority
      entity = analysis.entities[ annotation.uri ]
      for id, e of configuration.entities
        entity = analysis.entities[ e.id ] if annotation.uri in e.sameAs

      # If no entity is found we have a problem
      if not entity?
         $log.warn "Entity with uri #{annotation.uri} is missing both in analysis results and in local storage"
         continue
      # Enhance analysis accordingly
      analysis.entities[ entity.id ].occurrences.push  textAnnotation.id
      if not analysis.entities[ entity.id ].annotations[ textAnnotation.id ]?
        analysis.entities[ entity.id ].annotations[ textAnnotation.id ] = textAnnotation 
        analysis.annotations[ textAnnotation.id ].entityMatches.push { entityId: entity.id, confidence: 1 } 
        analysis.annotations[ textAnnotation.id ].entities[ entity.id ] = analysis.entities[ entity.id ]            
        
  service

])
# Create the main AngularJS module, and set it dependent on controllers and directives.
angular.module('wordlift.editpost.widget.services.EditorService', [
  'wordlift.editpost.widget.services.AnalysisService'
  ])
# Manage redlink analysis responses
.service('EditorService', [ 'AnalysisService', '$log', '$http', '$rootScope', (AnalysisService, $log, $http, $rootScope)-> 
  
  
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
        
    occurrences = currentOccurencesForEntity entity.id    
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
      entities = findEntities html

      # Preselect entities found in html.
      AnalysisService.preselect analysis, entities

      # Remove existing text annotations (the while-match is necessary to remove nested spans).
      while html.match(/<(\w+)[^>]*\sclass="textannotation[^"]*"[^>]*>([^<]+)<\/\1>/gim, '$2')
        html = html.replace(/<(\w+)[^>]*\sclass="textannotation[^"]*"[^>]*>([^<]+)<\/\1>/gim, '$2')

      # Prepare a traslator instance that will traslate Html and Text positions.
      traslator = Traslator.create html

      # Add text annotations to the html (skip those text annotations that don't have entity annotations).
      for annotationId, annotation of analysis.annotations when 0 < annotation.entityMatches.length
        
        element = "<span id=\"#{annotationId}\" class=\"textannotation"
        
        # Loop annotation to see which has to be preselected
        for em in annotation.entityMatches
          entity = analysis.entities[ em.entityId ] 
          
          if annotationId in entity.occurrences
            element += " disambiguated wl-#{entity.mainType}\" itemid=\"#{entity.id}"
        
        element += "\">"
        #$log.debug element
        #$log.debug annotation.entityMatches
        
            
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
  
  _configuration = undefined
  
  provider =
    setConfiguration: (configuration)->
      _configuration = configuration
    $get: ()->
      _configuration

  provider
)



# Set the well-known $ reference to jQuery.
$ = jQuery

# Create the main AngularJS module, and set it dependent on controllers and directives.
angular.module('wordlift.editpost.widget', [

	'wordlift.ui.carousel'
  'wordlift.editpost.widget.providers.ConfigurationProvider', 
	'wordlift.editpost.widget.controllers.EditPostWidgetController', 
	'wordlift.editpost.widget.directives.wlClassificationBox', 
	'wordlift.editpost.widget.directives.wlEntityForm', 
	'wordlift.editpost.widget.directives.wlEntityTile',
  'wordlift.editpost.widget.directives.wlEntityInputBox', 
	'wordlift.editpost.widget.services.AnalysisService', 
	'wordlift.editpost.widget.services.EditorService', 
	'wordlift.editpost.widget.services.ImageSuggestorDataRetrieverService' 		
	
	])

.config((configurationProvider)->
  configurationProvider.setConfiguration window.wordlift
)

$(
  container = $("""
  	<div ng-show="analysis" id="wordlift-edit-post-wrapper" ng-controller="EditPostWidgetController">
  		<div ng-click="createTextAnnotationFromCurrentSelection()" id="wl-add-entity-button-wrapper">
        <span class="preview button" ng-class="{ 'selected' : !isSelectionCollapsed }">Add entity</span>
        <div class="clear" />     
      </div>
      
      <div ng-show="annotation">
        <h4 class="wl-annotation-label">
          <i class="wl-annotation-label-icon"></i>
          {{ analysis.annotations[ annotation ].text }} 
          <small>[ {{ analysis.annotations[ annotation ].start }}, {{ analysis.annotations[ annotation ].end }} ]</small>
          <i class="wl-annotation-label-remove-icon" ng-click="selectAnnotation(undefined)"></i>
        </h4>
        <wl-entity-form entity="newEntity" on-submit="addNewEntityToAnalysis()" ng-show="analysis.annotations[annotation].entityMatches.length == 0"></wl-entity-form>
      </div>

      <wl-classification-box ng-repeat="box in configuration.classificationBoxes">
        <div ng-hide="annotation" class="wl-without-annotation">
          <wl-entity-tile is-selected="isEntitySelected(entity, box)" on-entity-select="onSelectedEntityTile(entity, box)" entity="entity" ng-repeat="entity in analysis.entities | filterEntitiesByTypesAndRelevance:box.registeredTypes"></wl-entity>
        </div>  
        <div ng-show="annotation" class="wl-with-annotation">
          <wl-entity-tile is-selected="isLinkedToCurrentAnnotation(entity)" on-entity-select="onSelectedEntityTile(entity, box)" entity="entity" ng-repeat="entity in analysis.annotations[annotation].entities | filterEntitiesByTypes:box.registeredTypes"" ></wl-entity>
        </div>  
      </wl-classification-box>
      <div wl-carousel>
        <div ng-repeat="(image, label) in images" class="wl-card" wl-carousel-pane>
          <img ng-src="{{image}}" />
        </div>
      </div>
      
      <div class="wl-entity-input-boxes">
        <wl-entity-input-box annotation="annotation" entity="entity" ng-repeat="entity in analysis.entities | isEntitySelected"></wl-entity-input-box>
        <div ng-repeat="(box, entities) in selectedEntities">
          <input type='text' name='wl_boxes[{{box}}][]' value='{{id}}' ng-repeat="(id, entity) in entities">
        </div> 
      </div>   
    </div>
  """)
  .appendTo('#wordlift-edit-post-outer-wrapper')

injector = angular.bootstrap $('#wordlift-edit-post-wrapper'), ['wordlift.editpost.widget']

# Add WordLift as a plugin of the TinyMCE editor.
  tinymce.PluginManager.add 'wordlift', (editor, url) ->
    # Perform analysis once tinymce is loaded
    editor.onLoadContent.add((ed, o) ->
      injector.invoke(['AnalysisService', '$rootScope',
       (AnalysisService, $rootScope) ->
        # execute the following commands in the angular js context.
        $rootScope.$apply(->    
          # Get the html content of the editor.
          html = editor.getContent format: 'raw'

          # Get the text content from the Html.
          text = Traslator.create(html).getText()
          AnalysisService.perform text
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
