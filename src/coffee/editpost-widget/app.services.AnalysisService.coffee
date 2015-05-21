angular.module('wordlift.editpost.widget.services.AnalysisService', [])
# Manage redlink analysis responses
.service('AnalysisService', [ 'configuration', '$log', '$http', '$rootScope', (configuration, $log, $http, $rootScope)-> 
	
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

  service._supportedTypes = []
  service._defaultType = "thing"
  service._brokenEntities = []
  
  # Retrieve supported type from current classification boxes configuration
  for box in configuration.classificationBoxes
    for type in box.registeredTypes
      if type not in service._supportedTypes
        service._supportedTypes.push type

  service.createEntity = (params = {}) ->
    # Set the defalut values.
    defaults =
      id: 'local-entity-' + uniqueId 32
      label: ''
      description: ''
      mainType: 'thing' # DefaultType
      types: []
      images: []
      confidence: 1
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
      entities: []
      entityMatches: []
    
    merge defaults, params
  
  service.parse = (data) ->
    
    # Add local entities
    # Add id to entity obj
    # Add id to annotation obj
    # Add occurences as a blank array
    # Add annotation references to each entity
    for id, localEntity of configuration.entities
      if data.entities[ id ]?
        $log.debug "LocalEntity #{id} found into the analysis"
      else
        $log.debug "Going to add localEntity #{id} to the analysis"
        data.entities[ id ] = localEntity

    for id, entity of data.entities
      
      if not entity.label
        $log.warn "Label missing for entity #{id}"
        @._brokenEntities.push id

      if entity.mainType not in @._supportedTypes
        $log.warn "Schema.org type #{entity.mainType} for entity #{id} is not supported from current classification boxes configuration"
        entity.mainType = @._defaultType
        $log.debug "Schema.org type overridden for entity #{id}"
        
      entity.id = id
      entity.occurrences = []
      entity.annotations = {}
      entity.confidence = 1 

    for id, annotation of data.annotations
      annotation.id = id
      annotation.entities = {}
      
      for ea, index in annotation.entityMatches
        
        data.entities[ ea.entityId ].annotations[ id ] = annotation
        data.annotations[ id ].entities[ ea.entityId ] = data.entities[ ea.entityId ]

    # TODO move this calculation on the server
    for id, entity of data.entities
      for annotationId, annotation of data.annotations
        local_confidence = 1
        for em in annotation.entityMatches  
          if em.entityId? and em.entityId is id
            local_confidence = em.confidence
        entity.confidence = entity.confidence * local_confidence
    

    # Clean broken entities
    for entityId in @._brokenEntities
      $log.warn "Going to remove #{entityId}"
      
      brokenMatches = []

      for id, annotation of data.entities[ entityId ].annotations
        for ea, index in annotation.entityMatches

          if ea.entityId is entityId
            brokenMatches.push index
        
          delete data.annotations[ id ].entities[ entityId ]

      for bmIndex in brokenMatches
          data.annotations[ id ].entityMatches.splice(bmIndex, 1)
        
      delete data.entities[ entityId ]

    $log.debug data
    data

  service.perform = (content)->
    
    $log.info "Start to performing analysis"

    if not content?
      $log.warn "content missing: nothing to do"
      return

    $http(
      method: 'post'
      url: ajaxurl + '?action=wordlift_analyze'
      data: content      
    )
    # If successful, broadcast an *analysisReceived* event.
    .success (data) ->
      
       if typeof data is 'string'
         $log.warn "Invalid data returned"
         $log.debug data
         return

       $rootScope.$broadcast "analysisPerformed", service.parse( data )
    .error (data, status) ->
       $log.warn "Error on analysis, statut #{status}"

  # Preselect entity annotations in the provided analysis using the provided collection of annotations.
  service.preselect = (analysis, annotations) ->

    # Find the existing entities in the html
    for annotation in annotations
      # Find the proper annotation  
      textAnnotation = findAnnotation analysis.annotations, annotation.start, annotation.end
      
      # If there is no textAnnotation then create it and add to the current analysis
      if not textAnnotation?
        $log.debug "There is no annotation with start #{annotation.start} and end #{annotation.end}"
        textAnnotation = @createAnnotation({
          start: annotation.start
          end: annotation.end
          text: annotation.label
          })
        analysis.annotations[ textAnnotation.id ] = textAnnotation
        
      # Look for the entity in the current analysis result
      # Local entities are merged previously during the analysis parsing
      # Local entities have higher priority
      entity = analysis.entities[ annotation.uri ]
      for id, e of configuration.entities
        entity = analysis.entities[ e.id ] if annotation.uri in e.sameAs

      # If no entity is found we have a problem
      if not entity?
         $log.warn "Entity with uri #{annotation.uri} is missing both in analysis results and in local storage"
         continue
      # Enhance analysis accordingly
      analysis.entities[ entity.id ].occurrences.push  textAnnotation.id
      if not analysis.entities[ entity.id ].annotations[ textAnnotation.id ]?
        analysis.entities[ entity.id ].annotations[ textAnnotation.id ] = textAnnotation 
        analysis.annotations[ textAnnotation.id ].entityMatches.push { entityId: entity.id, confidence: 1 } 
        analysis.annotations[ textAnnotation.id ].entities[ entity.id ] = analysis.entities[ entity.id ]            
        
  service

])