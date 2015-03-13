# Set the well-known $ reference to jQuery.
$ = jQuery

# Create the main AngularJS module, and set it dependent on controllers and directives.
angular.module('wordlift.facetedsearch.widget', [])
.provider("configuration", ()->
  
  _configuration = undefined
  
  provider =
    setConfiguration: (configuration)->
      _configuration = configuration
    $get: ()->
      _configuration

  provider
)
.controller('FacetedSearchWidgetController', [ 'DataRetrieverService', 'configuration', '$scope', '$log', (DataRetrieverService, configuration, $scope, $log)-> 

    $scope.posts = []
    $scope.facets = []
    $scope.conditions = []
    
    $scope.addCondition = (entity)->
      $log.debug "Add entity #{entity.id} to conditions array"

      if entity.id in $scope.conditions
        $scope.conditions.splice $scope.conditions.indexOf( entity.id ), 1
      else
        $scope.conditions.push entity.id
      
      DataRetrieverService.load( 'posts', $scope.conditions )

        
    $scope.$on "postsLoaded", (event, posts) -> 
      $log.debug "Referencing posts for entity #{configuration.entity_id} ..."
      $log.debug posts
      $scope.posts = posts

    $scope.$on "facetsLoaded", (event, facets) -> 
      $log.debug "Referencing facets for entity #{configuration.entity_id} ..."
      $log.debug facets
      $scope.facets = facets

])
# Retrieve post
.service('DataRetrieverService', [ 'configuration', '$log', '$http', '$rootScope', (configuration, $log, $http, $rootScope)-> 
  
  service = {}
  service.load = ( type, conditions = [] )->
    uri = "#{configuration.ajax_url}?action=#{configuration.action}&entity_id=#{configuration.entity_id}&type=#{type}"
    
    $log.debug "Going to search #{type} with conditions"
    $log.debug conditions

    $http(
      method: 'post'
      url: uri
      data: conditions
    )
    # If successful, broadcast an *analysisReceived* event.
    .success (data) ->
      $rootScope.$broadcast "#{type}Loaded", data
    .error (data, status) ->
       $log.warn "Error loading #{type}, statut #{status}"

  service

  service

])
.config((configurationProvider)->
  configurationProvider.setConfiguration window.wl_faceted_search_params
)

$(
  container = $("""
  	<div ng-controller="FacetedSearchWidgetController">
      <div>
        <h3>Facets</h3>
        <ul>
          <li ng-repeat="entity in facets" ng-click="addCondition(entity)">{{entity.label}} {{entity.mainType}}</li>
        </ul>
      </div>
      <div>
        <h3>Related posts</h3>
        <div class="posts" ng-repeat="post in posts">{{post.post_title}}</div>   
      </div>
    </div>
  """)
  .appendTo('#wordlift-faceted-entity-search-widget')

injector = angular.bootstrap $('#wordlift-faceted-entity-search-widget'), ['wordlift.facetedsearch.widget'] )
injector.invoke(['DataRetrieverService', '$rootScope', '$log', (DataRetrieverService, $rootScope, $log) ->
  # execute the following commands in the angular js context.
  $rootScope.$apply(->    
    DataRetrieverService.load('posts') 
    DataRetrieverService.load('facets') 
  )
])


