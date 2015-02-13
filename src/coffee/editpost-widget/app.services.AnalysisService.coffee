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
 
  findAnnotation = (annotations, start, end) ->
    return annotation for id, annotation of annotations when annotation.start is start and annotation.end is end


  service = 
    _currentAnalysis = {}

  service.createEntity = (params = {}) ->
    # Set the defalut values.
    defaults =
      id: 'local-entity-' + uniqueId 32
      label: ''
      description: ''
      mainType: 'thing' # DefaultType
      types: []
      images: []
      occurrences: []
      annotations: {}
    
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
    
    # Add id to entity obj
    # Add id to annotation obj
    # Add occurences as a blank array
    # Add annotation references to each entity

    $log.debug Object.keys(data.entities).length
    for id, entity of data.entities
      entity.id = id
      entity.occurrences = []
      entity.annotations = {}
      entity.annotation_count = 0

    for id, annotation of data.annotations
      annotation.id = id
      for ea in annotation.entityMatches
        data.entities[ ea.entityId ].annotations[ id ] = annotation
        data.entities[ ea.entityId ].annotation_count += 1
    
    for id, entity of data.entities
      entity.isRelevant = ( entity.annotation_count > 1 and entity.confidence is entity.annotation_count)
    

    data

  service.perform = (content)->
  	$http(
      method: 'get'
      url: ajaxurl #+ '?action=wordlift_analyze'
      data: content      
    )
    # If successful, broadcast an *analysisReceived* event.
    .success (data) ->
       $rootScope.$broadcast "analysisPerformed", service.parse( data )

  # Preselect entity annotations in the provided analysis using the provided collection of annotations.
  service.preselect = (analysis, annotations) ->

    # Find the existing entities in the html
    for annotation in annotations
      # Find the proper annotation            
      textAnnotation = findAnnotation analysis.annotations, annotation.start, annotation.end
      # TODO Look for same as
      # Enhance entity occurences
      analysis.entities[ annotation.uri ].occurrences.push  textAnnotation.id

  service

])