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

  $scope.$on "configurationLoaded", (event, configuration) ->
    for box in configuration.classificationBoxes
      $scope.entitySelection[ box.id ] = []
    $scope.configuration = configuration

  $scope.$on "analysisPerformed", (event, analysis) ->
    $log.debug analysis
    $scope.analysis = analysis

  $scope.onSelectedEntityTile = (entityId, scope)->
  	$log.debug "Entity tile selected for entity #{entityId} within '#{scope}' scope"
  	if entityId not in $scope.entitySelection[ scope ]
  	  $scope.entitySelection[ scope ].push entityId
  	
])
.directive('wlClassificationBox', ['$log', ($log)->
    restrict: 'E'
    scope: true
    template: """
    	<div class="classification-box">
    		<h4 class="box-header">{{box.label}}</h4>
  			<wl-entity notify="onSelectedEntityTile(entity.id, box.id)" entity="entity" ng-repeat="entity in entities"></wl-entity>
  		</div>
  		<p>-- {{openedEntityTile}}</p>		
    """
    link: ($scope, $element, $attrs, $ctrl) ->  	  
  	  
  	  $scope.entities = {}
  	
  	  for id, entity of $scope.analysis.entities
  	    if entity.mainType in $scope.box.registeredTypes 
  	      $scope.entities[ id ] = entity 

    controller: ($scope, $element, $attrs) ->
      
      $scope.openedEntityTile = undefined
      $scope.tiles = []
      ctrl =
      	addTile: (tile)->
          $scope.tiles.push tile
        closeTiles: ()->
          for tile in $scope.tiles
          	tile.isOpened = false
      ctrl
  ])
.directive('wlEntity', ['$log', ($log)->
    require: '^wlClassificationBox'
    restrict: 'E'
    scope:
      entity: '='
    template: """
  	  <div ng-click="" ng-class="'wl-' + entity.mainType">
  	    {{entity.label}}<small ng-show="entity.occurrences > 0">({{entity.occurrences}})</small>
  	    <small class="toggle-button" ng-hide="isOpened" ng-click="toggle()">+</small>
  	  	<small class="toggle-button" ng-show="isOpened" ng-click="toggle()">+</small>
  	  </div>
  	  <div class="details" ng-show="isOpened">{{entity.description}}</div>
  	"""
    link: ($scope, $element, $attrs, $ctrl) ->				      
      
      $scope.isOpened = false
      
      $ctrl.addTile $scope

      $scope.toggle = ()->
      	$ctrl.closeTiles()
      	$scope.isOpened = !$scope.isOpened
  ])
$(
  container = $("""
  	<div id="wordlift-edit-post-wrapper" ng-controller="coreController">
  		<wl-classification-box ng-repeat="box in configuration.classificationBoxes"></wl-classification-box>
  		<hr />
  		<div ng-repeat="(box, ids) in entitySelection">
  			<span>{{ box }}</span> - <span>{{ ids }}</span> 
  		</div>
  	</div>
  """)
  .appendTo('#dx')
)

injector = angular.bootstrap $('#wordlift-edit-post-wrapper'), ['wordlift.core']
injector.invoke(['ConfigurationService', 'AnalysisService','$rootScope', (ConfigurationService, AnalysisService, $rootScope) ->
	# execute the following commands in the angular js context.
    $rootScope.$apply(->
    	AnalysisService.perform()
    	ConfigurationService.loadConfiguration()
    )
])