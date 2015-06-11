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
.filter('filterEntitiesByType', [ '$log', 'configuration', ($log, configuration)->
  return (items, type)->
    
    filtered = []
    for id, entity of items
      if  entity.mainType is type and entity.id != configuration.entity_uri
        filtered.push entity
    filtered

])
.directive('wlTruncate', ['$log', ($log)->
    restrict: 'A'
    scope:
      text: '='
      charsThreshold: '='
    link: ($scope, $element, $attrs) ->  
      CHARS_THRESHOLD = parseInt( $scope.charsThreshold )
      $scope.label = $scope.text
      if $scope.text.length > CHARS_THRESHOLD
        $scope.label = $scope.text.substr( 0, CHARS_THRESHOLD ) + ' ...'
      $element.append $scope.label
])

.controller('FacetedSearchWidgetController', [ 'DataRetrieverService', 'configuration', '$scope', '$log', (DataRetrieverService, configuration, $scope, $log)-> 

    $scope.entity = undefined
    $scope.posts = []
    $scope.facets = []
    $scope.conditions = {}
    $scope.supportedTypes = ['thing', 'person', 'organization', 'place', 'event']

    $scope.isInConditions = (entity)->
      if $scope.conditions[ entity.id ]
        return true
      return false

    $scope.addCondition = (entity)->
      $log.debug "Add entity #{entity.id} to conditions array"

      if $scope.conditions[ entity.id ]
        delete $scope.conditions[ entity.id ]
      else
        $scope.conditions[ entity.id ] = entity
      
      DataRetrieverService.load( 'posts', Object.keys( $scope.conditions ) )

        
    $scope.$on "postsLoaded", (event, posts) -> 
      $log.debug "Referencing posts for entity #{configuration.entity_id} ..."
      $log.debug posts
      $scope.posts = posts
      $log.debug $scope.posts

    $scope.$on "facetsLoaded", (event, facets) -> 
      $log.debug "Referencing facets for entity #{configuration.entity_id} ..."
      for entity in facets
        if entity.id is configuration.entity_uri
          $scope.entity = entity

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
.directive('wlCarousel', ['$window', '$log', ($window, $log)->
    restrict: 'A'
    scope: true
    transclude: true      
    template: """
      <div class="wl-carousel">
        <div class="wl-panes" style="width:{{panesWidth}}px; left:{{position}}px;" ng-transclude ng-swipe-right="next()"></div>
        <span class="wl-next" ng-click="next()">&gt;</span>
        <span class="wl-prev" ng-click="prev()">&lt;</span>
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

      $scope.next = ()->
        $scope.position = $scope.position - $scope.itemWidth
      $scope.prev = ()->
        $scope.position = $scope.position + $scope.itemWidth

      $scope.setPanesWrapperWidth = ()->
        $scope.panesWidth = $scope.panes.length * $scope.itemWidth

      w.bind 'resize', ()->
        
        $scope.itemWidth =  $element.width() / $scope.visibleElements();
        $scope.setPanesWrapperWidth()
        for pane in $scope.panes
          pane.scope.setWidth $scope.itemWidth
        $scope.$apply()

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
    restrict: 'A'
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
.config((configurationProvider)->
  configurationProvider.setConfiguration window.wl_faceted_search_params
)

$(
  container = $("""
  	<div ng-controller="FacetedSearchWidgetController">
      <h5>Contenuti associati a <strong>{{entity.label}}</strong></h5>
      <div class="wl-facets" wl-carousel>
        <div class="wl-facets-container" ng-repeat="type in supportedTypes" wl-carousel-pane>
          <h6 ng-class="'wl-fs-' + type"><i class="type" />{{type}}</h6>
          <ul>
            <li class="entity" ng-repeat="entity in facets | filterEntitiesByType:type" ng-click="addCondition(entity)">     
                <span class="wl-label" ng-class=" { 'selected' : isInConditions(entity) }" wl-truncate text="entity.label" chars-threshold="100"></span>
                <span class="counter">({{entity.counter}})</span>
            </li>
          </ul>
        </div>
      </div>
      <div class="wl-posts">
        <div class="wl-conditions">
          <span>Filtri:</span>
          <strong class="wl-condition" ng-repeat="(condition, entity) in conditions">{{entity.label}}. </strong>
        </div>
        <div wl-carousel>
          <div class="wl-post" ng-repeat="post in posts" wl-carousel-pane>
            <img ng-src="{{post.thumbnail}}" />
            <div class="wl-post-title"> 
              <a ng-href="/?p={{post.ID}}">{{post.post_title}}</a>
            </div>
          </div>
        </div>
  
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


