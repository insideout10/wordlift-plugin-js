angular.module('wordlift.editpost.widget.controllers.EditPostWidgetController', [
  'wordlift.editpost.widget.services.AnalysisService'
  'wordlift.editpost.widget.services.EditorService'
  'wordlift.editpost.widget.providers.ConfigurationProvider'
])
.filter('entityTypeIn', [ '$log', ($log)->
  return (items, types)->
    
    filtered = []

    for id, entity of items
      if entity.mainType in types
        filtered.push entity
    
    filtered
])
.controller('EditPostWidgetController', [ 'EditorService', 'AnalysisService', 'configuration', '$log', '$scope', '$rootScope', '$injector', (EditorService, AnalysisService, configuration, $log, $scope, $rootScope, $injector)-> 

  $scope.configuration = []
  $scope.analysis = {}
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

  $scope.createTextAnnotationFromCurrentSelection = ()->
    EditorService.createTextAnnotationFromCurrentSelection()

  $scope.addNewEntityToAnalysis = ()->
    # Add new entity to the analysis
    $scope.analysis.entities[ $scope.newEntity.id ] = $scope.newEntity
    annotation = $scope.analysis.annotations[ $scope.annotation ]
    annotation.entityMatches.push { entityId: $scope.newEntity.id, confidence: 1 }
    $scope.analysis.entities[ $scope.newEntity.id ].annotations[ annotation.id ] = annotation
    
    # TODO Check entity tiles status

    # Create new entity object
    $scope.newEntity = AnalysisService.createEntity()
    
  $scope.$on "isSelectionCollapsed", (event, status) ->
    $log.debug "Going to se isSelectionAvailable to #{status}"
    $scope.isSelectionCollapsed = status

  $scope.$on "updateOccurencesForEntity", (event, entityId, occurrences) ->
    $log.debug "Occurrences #{occurrences.length} for #{entityId}"
    $scope.analysis.entities[ entityId ].occurrences = occurrences

    if $scope.annotation?
      for box, entities of $scope.selectedEntities
        $scope.boxes[ box ].relink $scope.analysis.entities[ entityId ], $scope.annotation
        
    if occurrences.length is 0
      for box, entities of $scope.selectedEntities
        delete $scope.selectedEntities[ box ][ entityId ]
        $scope.boxes[ box ].deselect $scope.analysis.entities[ entityId ]
        
  $scope.$on "textAnnotationClicked", (event, annotationId) ->
    $log.debug "click on #{annotationId}"
    $scope.annotation = annotationId

  $scope.$on "textAnnotationAdded", (event, annotation) ->
    $log.debug "added a new annotation with Id #{annotation.id}"
    # Add the new annotation to the current analysis
    $scope.analysis.annotations[ annotation.id ] = annotation
    # Set the annotation scope
    $scope.annotation = annotation.id
    # Set the annotation text as label for the new entity
    $scope.newEntity.label = annotation.text
  
  $scope.$on "analysisPerformed", (event, analysis) -> 
    $scope.analysis = analysis

  $scope.$on "updateWidget", (event, widget, scope)->
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