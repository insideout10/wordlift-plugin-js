angular.module('wordlift.editpost.widget.services.AnalysisService', [])
# Manage redlink analysis responses
.service('AnalysisService', [ '$log', '$http', '$rootScope', ($log, $http, $rootScope)-> 
	
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

  service = 
    _currentAnalysis = {}

  service.createEntity = (params = {}) ->
    # Set the defalut values.
    defaults =
      id: 'local-entity-' + uniqueId 32
      label: ''
      description: ''
      mainType: ''
      types: []
      images: []
      occurrences: []
      annotations: {}
      isRelatedToAnnotation: (annotationId)->
        if @.annotations[ annotationId ]? then true else false
    
    merge defaults, params

  service.createAnnotation = (params = {}) ->
    # Set the defalut values.
    defaults =
      id: 'urn:local-text-annotation-' + uniqueId 32
      text: ''
      start: 0
      end: 0
      entityMatches: []
    
    merge defaults, params

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

    for id, annotation of data.annotations
      annotation.id = id

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