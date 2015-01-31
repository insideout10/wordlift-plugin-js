angular.module('wordlift.editpost.widget.directives.wlClassificationBox', [])
.directive('wlClassificationBox', ['$log', ($log)->
    restrict: 'E'
    scope: true
    transclude: true      
    template: """
    	<div class="classification-box">
    		<div class="box-header">
          <h5 class="label">{{box.label}}
            <span class="wl-suggestion-tools" ng-show="hasSelectedEntities()">
              <i ng-class="'wl-' + widget" title="{{widget}}" ng-click="toggleWidget(widget)" ng-repeat="widget in box.registeredWidgets" class="wl-widget-icon"></i>
            </span>
            <span ng-show="isWidgetOpened" class="wl-widget-label">{{currentWidget}}
              <i ng-click="toggleWidget(currentWidget)" class="wl-deselect-widget"></i>
            </span>  
          </h5>
          <div ng-show="isWidgetOpened" class="box-widgets">
            <div ng-show="currentWidget == widget" ng-repeat="widget in box.registeredWidgets">
              <img ng-click="embedImageInEditor(item.uri)"ng-src="{{ item.uri }}" ng-repeat="item in widgets[ box.id ][ widget ]" />
            </div>
          </div>
          <div class="selected-entities">
            <span ng-class="'wl-' + entity.mainType" ng-repeat="(id, entity) in selectedEntities[box.id]" class="wl-selected-item">
              {{ entity.label}}
              <i class="wl-deselect-item" ng-click="onSelectedEntityTile(entity, box)"></i>
            </span>
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
          $scope.$emit "updateWidget", widget, $scope.box.id 
          
    controller: ($scope, $element, $attrs) ->
      
      # Mantain a reference to nested entity tiles $scope
      # TODO manage on scope distruction event
      $scope.tiles = []

      # TODO don't use $parent
      $scope.$parent.boxes[ $scope.box.id ] = $scope

      $scope.deselect = (entity)->
        for tile in $scope.tiles
          tile.isSelected = false if tile.entity.id is entity.id
      
      $scope.relink = (entity, annotationId)->
        for tile in $scope.tiles
          tile.isLinked = (annotationId in tile.entity.occurrences) if tile.entity.id is entity.id
           
      $scope.$watch "annotation", (annotationId) ->
        
        $log.debug "Watching annotation ... New value #{annotationId}"
        $scope.currentWidget = undefined
        $scope.isWidgetOpened = false

        for tile in $scope.tiles
          if annotationId?
            tile.isVisible = (tile.entity.annotations[ annotationId ]?)
            tile.annotationModeOn = true
            tile.isLinked = (annotationId in tile.entity.occurrences)
          else
            tile.isVisible = true
            tile.isLinked = false
            tile.annotationModeOn = false
            
      ctrl =
        onSelectedTile: (tile)->
          tile.isSelected = !tile.isSelected
          $scope.onSelectedEntityTile tile.entity, $scope.box
        addTile: (tile)->
          $scope.tiles.push tile
        closeTiles: ()->
          for tile in $scope.tiles
          	tile.close()
      ctrl
  ])