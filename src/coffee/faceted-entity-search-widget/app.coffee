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
.filter('filterEntitiesByType', [ '$log', ($log)->
  return (items, type)->
    
    filtered = []
    $log.debug "andiamo"
    for id, entity of items
      if  entity.mainType is type
        filtered.push entity
    filtered

])
.controller('FacetedSearchWidgetController', [ 'DataRetrieverService', 'configuration', '$scope', '$log', (DataRetrieverService, configuration, $scope, $log)-> 

    $scope.posts = []
    $scope.facets = []
    $scope.conditions = []
    $scope.supportedTypes = ['thing', 'person', 'organization', 'place', 'event']

    $scope.isInConditions = (entity)->
      return (entity.id in $scope.conditions)

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

])
.config((configurationProvider)->
  configurationProvider.setConfiguration window.wl_faceted_search_params
)

$(
  container = $("""
  	<div ng-controller="FacetedSearchWidgetController">
      <div class="facets">
        <fieldset ng-repeat="type in supportedTypes">
          <legend>{{type}}</legend>
          <ul>
            <li ng-class="'wl-fs-' + entity.mainType" class="entity" ng-repeat="entity in facets | filterEntitiesByType:type" ng-click="addCondition(entity)">
              <i class="checkbox" ng-class=" { 'selected' : isInConditions(entity) }" /><i class="type" /><span class="label">{{entity.label}}</span>
            
            </li>
          </ul>
        </fieldset>
      </div>
      <div class="posts">
        <div class="post" ng-repeat="post in posts">{{post.post_title}}</div>   
      
      <div class="conditions">
        <h5>Filtri</h5>
        <span ng-repeat="condition in conditions"><small>{{condition}}</small></span>
      </div>
      </div>
      <br class="clear" />
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


