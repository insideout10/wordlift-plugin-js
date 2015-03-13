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
.controller('FacetedSearchWidgetController', [ 'configuration', '$scope', '$log', (configuration, $scope, $log)-> 
  
])
# Retrieve post
.service('DataRetrieverService', [ 'configuration', '$log', '$http', '$rootScope', (configuration, $log, $http, $rootScope)-> 
  
  service = {}
  service.load = ( type, conditions = {} )->
    uri = "#{configuration.ajax_url}?action=#{configuration.action}&entity_id=#{configuration.entity_id}&type=#{type}"
    $log.debug "Going to ask posts at uri #{uri}"

    $http(
      method: 'get'
      url: uri
    )
    # If successful, broadcast an *analysisReceived* event.
    .success (data) ->
      $rootScope.$broadcast "postsLoaded", data
    .error (data, status) ->
       $log.warn "Error loading #{type}s, statut #{status}"

  service

  service

])
.config((configurationProvider)->
  configurationProvider.setConfiguration window.wl_faceted_search_params
)

$(
  container = $("""
  	<div ng-controller="FacetedSearchWidgetController">
      <div><h3>Facets</h3></div>
      <div><h3>Related posts</h3></div>
    </div>
  """)
  .appendTo('#wordlift-faceted-entity-search-widget')

injector = angular.bootstrap $('#wordlift-faceted-entity-search-widget'), ['wordlift.facetedsearch.widget'] )
injector.invoke(['DataRetrieverService', '$rootScope', '$log', (DataRetrieverService, $rootScope, $log) ->
  # execute the following commands in the angular js context.
  $rootScope.$apply(->    
    DataRetrieverService.load('posts') 
  )
])


