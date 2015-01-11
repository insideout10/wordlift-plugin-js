# Set the well-known $ reference to jQuery.
$ = jQuery

# Create the main AngularJS module, and set it dependent on controllers and directives.
angular.module('wordlift.core', [])

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
.controller('EditPostWidgetController', [ '$log', '$scope', '$rootScope', ($log, $scope, $rootScope)-> 

  $scope.configuration = []
  $scope.analysis = {}
  $scope.selectedEntities = {}
  $scope.annotation = undefined
  $scope.boxes = []

  $scope.addBox = (scope, id)->
    $scope.boxes[id] = scope
  
  $scope.$on "configurationLoaded", (event, configuration) ->
    for box in configuration.classificationBoxes
      $scope.selectedEntities[ box.id ] = {}
    $scope.configuration = configuration

  $scope.$on "analysisPerformed", (event, analysis) ->
    $log.debug analysis
    $scope.analysis = analysis

  $scope.onSelectedEntityTile = (entity, scope)->
  	$log.debug "Entity tile selected for entity #{entity.id} within '#{scope}' scope"
  	if not $scope.selectedEntities[ scope ][ entity.id ]?

  	  $scope.selectedEntities[ scope ][ entity.id ] = entity
  	  $log.debug $scope.selectedEntities
  	  # TODO All related annotations has to be disambiguated accordingly
  	else
      # TODO Any related annotation has to be reset just if this is the last related instance 
      delete $scope.selectedEntities[ scope ][ entity.id ]
      $scope.boxes[ scope ].deselect entity
      
])
.directive('wlClassificationBox', ['$log', ($log)->
    restrict: 'E'
    scope: true
    template: """
    	<div class="classification-box">
    		<div class="box-header">
          <h5 class="label">{{box.label}}</h5>
          <span ng-class="'wl-' + entity.mainType" ng-repeat="(id, entity) in selectedEntities[box.id]" class="wl-selected-item">
            {{ entity.label}}
            <i class="wl-deselect-item" ng-click="onSelectedEntityTile(entity, box.id)"></i>
          </span>
        </div>
  			<wl-entity-tile notify="onSelectedEntityTile(entity.id, box.id)" entity="entity" ng-repeat="entity in entities"></wl-entity>
  		</div>	
    """
    link: ($scope, $element, $attrs, $ctrl) ->  	  
  	  
      $scope.entities = {}
      
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

      $scope.$watch "annotation", (annotationId) ->
        $log.debug "annotation #{annotationId}"
        return if not annotationId?
        for tile in $scope.tiles
          tile.isVisible = tile.entity.isRelatedToAnnotation( annotationId )

      ctrl =
        onSelectedTile: (tile)->
          tile.isSelected = !tile.isSelected
          $scope.onSelectedEntityTile tile.entity, $scope.box.id
        addTile: (tile)->
          $log.debug "Adding tile with id #{tile.$id}"
          $scope.tiles.push tile
        closeTiles: ()->
          for tile in $scope.tiles
          	tile.close()
      ctrl
  ])
.directive('wlEntityTile', ['$log', ($log)->
    require: '^wlClassificationBox'
    restrict: 'E'
    scope:
      entity: '='
    template: """
  	  <div ng-class="wrapperCssClasses" ng-show="isVisible">
  	    <i ng-class="{ 'wl-selected' : isSelected, 'wl-unselected' : !isSelected }"></i>
        <i class="type"></i>
        <span class="label" ng-click="select()">{{entity.label}}</span>
        <small ng-show="entity.occurrences > 0">({{entity.occurrences}})</small>
        <i ng-class="{ 'wl-more': isOpened == false, 'wl-less': isOpened == true }" ng-click="toggle()"></i>
  	    <div class="details" ng-show="isOpened">
          <p><img class="thumbnail" ng-src="{{ entity.images[0] }}" />{{entity.description}}</p>
        </div>
  	  </div>

  	"""
    link: ($scope, $element, $attrs, $ctrl) ->				      
      
      # Add tile to related container scope
      $ctrl.addTile $scope

      $scope.isOpened = false
      $scope.isVisible = true
      $scope.isSelected = false

      $scope.wrapperCssClasses = [ "entity", "wl-#{$scope.entity.mainType}" ]

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
  		<wl-classification-box ng-repeat="box in configuration.classificationBoxes"></wl-classification-box>
    </div>

  """)
  .appendTo('#dx')

injector = angular.bootstrap $('body'), ['wordlift.core']
injector.invoke(['ConfigurationService', 'AnalysisService','$rootScope', (ConfigurationService, AnalysisService, $rootScope) ->
	# execute the following commands in the angular js context.
    $rootScope.$apply(->
    	AnalysisService.perform()
    	ConfigurationService.loadConfiguration()
    )
])

# Add WordLift as a plugin of the TinyMCE editor.
  tinymce.PluginManager.add 'wordlift', (editor, url) ->
    editor.onLoadContent.add((ed, o) ->
      #injector.invoke(['EditorService', (EditorService) ->
        #EditorService.createDefaultAnalysis()
      #])
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
      #injector.invoke(['$rootScope', ($rootScope) ->
        # execute the following commands in the angular js context.
      #  $rootScope.$apply(->
          # send a message about the currently clicked annotation.
          #$rootScope.$broadcast 'textAnnotationClicked', e.target.id
      #  )
      #])
)