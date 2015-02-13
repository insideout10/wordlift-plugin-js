angular.module('wordlift.editpost.widget.controllers.EditPostWidgetController', [
  'wordlift.editpost.widget.services.AnalysisService'
  'wordlift.editpost.widget.services.EditorService'
  'wordlift.editpost.widget.providers.ConfigurationProvider'
])
.filter('filterEntitiesByTypesAndRelevance', [ '$log', ($log)->
  return (items, types)->
    
    filtered = []
    
    if not items? 
      return filtered

    treshold = Math.floor ( 1/120 * Object.keys(items).length ) + 0.75 
    
    for id, entity of items
      if  entity.mainType in types
        
        annotations_count = Object.keys( entity.annotations ).length
        if annotations_count > treshold and entity.confidence is 1
           filtered.push entity
           continue
        if entity.occurrences.length > 0
          filtered.push entity
        
        # TODO se è una entità di wordlift la mostro

    filtered

])

.filter('filterEntitiesByTypes', [ '$log', ($log)->
  return (items, types)->
    
    filtered = []
    
    for id, entity of items
      if  entity.mainType in types
        filtered.push entity
    filtered

])

.filter('isEntitySelected', [ '$log', ($log)->
  return (items)->
    
    filtered = []

    for id, entity of items
      if entity.occurrences.length > 0
        filtered.push entity
    
    filtered
])
.controller('EditPostWidgetController', [ 'EditorService', 'AnalysisService', 'configuration', '$log', '$scope', '$rootScope', '$injector', (EditorService, AnalysisService, configuration, $log, $scope, $rootScope, $injector)-> 

  $scope.configuration = []
  $scope.analysis = undefined
  $scope.newEntity = AnalysisService.createEntity()
  $scope.selectedEntities = {}
  $scope.widgets = {}
  $scope.annotation = undefined
  $scope.boxes = []
  $scope.isSelectionCollapsed = true
  
  for box in configuration.boxes

    $scope.selectedEntities[ box.id ] = {}

    $scope.widgets[ box.id ] = {}
    for widget in box.registeredWidgets
      $scope.widgets[ box.id ][ widget ] = []
              
  $scope.configuration = configuration

  # Delegate to EditorService
  $scope.createTextAnnotationFromCurrentSelection = ()->
    EditorService.createTextAnnotationFromCurrentSelection()
  # Delegate to EditorService
  $scope.selectAnnotation = (annotationId)->
    EditorService.selectAnnotation annotationId
  $scope.isEntitySelected = (entity, box)->
    return $scope.selectedEntities[ box.id ][ entity.id ]?
  $scope.isLinkedToCurrentAnnotation = (entity)->
    return ($scope.annotation in entity.occurrences)

  $scope.addNewEntityToAnalysis = ()->
    $log.debug "Going to add new entity"
    $log.debug $scope.newEntity
    # Add new entity to the analysis
    $scope.analysis.entities[ $scope.newEntity.id ] = $scope.newEntity
    annotation = $scope.analysis.annotations[ $scope.annotation ]
    annotation.entityMatches.push { entityId: $scope.newEntity.id, confidence: 1 }
    $scope.analysis.entities[ $scope.newEntity.id ].annotations[ annotation.id ] = annotation
    $scope.analysis.annotations[ $scope.annotation ].entities[ $scope.newEntity.id ] = $scope.newEntity
    
    # Create new entity object
    $scope.newEntity = AnalysisService.createEntity()

  $scope.$on "isSelectionCollapsed", (event, status) ->
    $scope.isSelectionCollapsed = status

  $scope.$on "updateOccurencesForEntity", (event, entityId, occurrences) ->
    
    $log.debug "Occurrences #{occurrences.length} for #{entityId}"
    $scope.analysis.entities[ entityId ].occurrences = occurrences
    
    if occurrences.length is 0
      for box, entities of $scope.selectedEntities
        delete $scope.selectedEntities[ box ][ entityId ]

  $scope.$on "textAnnotationClicked", (event, annotationId) ->
    $scope.annotation = annotationId

  $scope.$on "textAnnotationAdded", (event, annotation) ->
    $log.debug "added a new annotation with Id #{annotation.id}"
    # Add the new annotation to the current analysis
    $scope.analysis.annotations[ annotation.id ] = annotation
    # Set the annotation scope
    $scope.annotation = annotation.id
    # Set the annotation text as label for the new entity
    $scope.newEntity.label = annotation.text
    # Set the annotation id as id for the new entity
    $scope.newEntity.id = annotation.id

  $scope.$on "analysisPerformed", (event, analysis) -> 
    $scope.analysis = analysis
    # Preselect 
    for box in configuration.boxes
      for entityId in box.selectedEntities
        $scope.selectedEntities[ box.id ][ entityId ] = analysis.entities[ entityId ]

  $scope.updateWidget = (widget, scope)->
    $log.debug "Going to updated widget #{widget} for box #{scope}"
    # Retrieve the proper DatarRetriever
    retriever = $injector.get "#{widget}DataRetrieverService"
    # Load widget items
    items = retriever.loadData $scope.selectedEntities[ scope ]
    # Assign items to the widget scope
    $scope.widgets[ scope ][ widget ] = items
    
  $scope.onSelectedEntityTile = (entity, scope)->
    $log.debug "Entity tile selected for entity #{entity.id} within '#{scope.id}' scope"
    
    # Close all opened widgets ...
    for id, box of $scope.boxes
      box.closeWidgets()
    
    if not $scope.selectedEntities[ scope.id ][ entity.id ]?
      $scope.selectedEntities[ scope.id ][ entity.id ] = entity
      $scope.$emit "entitySelected", entity, $scope.annotation
    else
      $scope.$emit "entityDeselected", entity, $scope.annotation  
      
])