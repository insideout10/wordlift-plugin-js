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