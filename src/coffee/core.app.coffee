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
    for id, annotation of data.annotations
      for match in annotation.entityMatches
      	data.entities[ match.entityId ][ 'occurrences' ] += 1
    
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

$(
  container = $('''
  	<div id="wordlift-edit-post-wrapper" ng-controller="coreController">
  		<ul ng-repeat="box in configuration.classificationBoxes" class="classification-box">
  			<li>{{box.label}}</li>
  			<ul ng-repeat="(entityId, entity) in analysis.entities">
  				<li ng-click="onSelectedEntityTile( entityId, box.id )" ng-class="'wl-' + entity.mainType">{{entity.label}} <small>({{entity.occurrences}})</small></li>
  			</ul>
  		</ul>
  		<hr />
  		<div ng-repeat="(box, ids) in entitySelection">
  			<span>{{ box }}</span> - <span>{{ ids }}</span> 
  		</div>
  	</div>
  ''')
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