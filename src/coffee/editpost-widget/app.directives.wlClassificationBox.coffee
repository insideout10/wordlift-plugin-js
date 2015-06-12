angular.module('wordlift.editpost.widget.directives.wlClassificationBox', [])
.directive('wlClassificationBox', ['$log', ($log)->
    restrict: 'E'
    scope: true
    transclude: true      
    template: """
    	<div class="classification-box">
    		<div class="box-header">
          <h5 class="label">{{box.label}}</h5>
          <div class="selected-entities">
            <span ng-class="'wl-' + entity.mainType" ng-repeat="(id, entity) in selectedEntities[box.id]" class="wl-selected-item">
              {{ entity.label}}
              <i class="wl-deselect-item" ng-click="onSelectedEntityTile(entity, box)"></i>
            </span>
            <div class="clear" /> 
          </div>
        </div>
  			<div class="box-tiles">
          <div ng-transclude></div>
  		  </div>
      </div>	
    """
    link: ($scope, $element, $attrs, $ctrl) ->  	  
  	  
      $scope.currentWidget = undefined
      $scope.isWidgetOpened = false

      $scope.closeWidgets = ()->
        $scope.currentWidget = undefined
        $scope.isWidgetOpened = false

      $scope.hasSelectedEntities = ()->
        Object.keys( $scope.selectedEntities[ $scope.box.id ] ).length > 0

      $scope.embedImageInEditor = (image)->
        $scope.$emit "embedImageInEditor", image

      $scope.toggleWidget = (widget)->
        if $scope.currentWidget is widget
          $scope.currentWidget = undefined
          $scope.isWidgetOpened = false
        else 
          $scope.currentWidget = widget
          $scope.isWidgetOpened = true   
          $scope.updateWidget widget, $scope.box.id 
          
    controller: ($scope, $element, $attrs) ->
      
      # Mantain a reference to nested entity tiles $scope
      # TODO manage on scope distruction event
      $scope.tiles = []

      $scope.boxes[ $scope.box.id ] = $scope

      $scope.$watch "annotation", (annotationId) ->
        
        $scope.currentWidget = undefined
        $scope.isWidgetOpened = false
            
      ctrl = @
      ctrl.addTile = (tile)->
        $scope.tiles.push tile
      ctrl.closeTiles = ()->
        for tile in $scope.tiles
          tile.close()
      
  ])