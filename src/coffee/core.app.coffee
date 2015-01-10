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
.controller('coreController', [ '$log', '$scope', '$rootScope', ($log, $scope, $rootScope)-> 

  $scope.configuration = []
  $scope.analysis = {}
  $scope.entitySelection = {}
  $scope.occurences = {}
  $scope.annotation = undefined
  $scope.boxes = []

  $scope.$on "configurationLoaded", (event, configuration) ->
    for box in configuration.classificationBoxes
      $scope.entitySelection[ box.id ] = {}
    $scope.configuration = configuration

  $scope.$on "analysisPerformed", (event, analysis) ->
    $log.debug analysis
    $scope.analysis = analysis

  $scope.onSelectedEntityTile = (entity, scope)->
  	$log.debug "Entity tile selected for entity #{entity.id} within '#{scope}' scope"
  	if not $scope.entitySelection[ scope ][ entity.id ]?

  	  $scope.entitySelection[ scope ][ entity.id ] = entity
  	  $log.debug $scope.entitySelection
  	  # TODO All related annotations has to be disambiguated accordingly
  	else
  	  $scope.entitySelection[ scope ][ entity.id ] = undefined
  	  # TODO Any related annotation has to be reset just if this is the last related instance 
  	
])
.directive('wlClassificationBox', ['$log', ($log)->
    restrict: 'E'
    scope: true
    template: """
    	<div class="classification-box">
    		<div class="box-header">
          <span class="label">{{box.label}}</span>
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

      $scope.$watch "annotation", (annotationId) ->
        $log.debug "annotation #{annotationId}"
        return if not annotationId?
        for tile in $scope.tiles
          tile.isVisible = tile.entity.isRelatedToAnnotation( annotationId )

      ctrl =
      	onSelectedTile: (tile)->
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
  	<div id="wordlift-edit-post-wrapper" ng-controller="coreController">
  		<wl-classification-box ng-repeat="box in configuration.classificationBoxes"></wl-classification-box>
    <hr />
    <div ng-repeat="(box, e) in entitySelection">
      <span>{{ box }}</span> - <span>{{ e }}</span> 
    </div>
    <button ng-click="annotation = 'urn:enhancement-1f83847a-95c2-c81b-cba9-f958aed45b34'"></button>
    </div>

  """)
  .appendTo('#dx')
)

injector = angular.bootstrap $('body'), ['wordlift.core']
injector.invoke(['ConfigurationService', 'AnalysisService','$rootScope', (ConfigurationService, AnalysisService, $rootScope) ->
	# execute the following commands in the angular js context.
    $rootScope.$apply(->
    	AnalysisService.perform()
    	ConfigurationService.loadConfiguration()
    )
])