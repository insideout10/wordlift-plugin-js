angular.module('wordlift.editpost.widget.directives.wlEntityTile', [])
.directive('wlEntityTile', ['$log', ($log)->
    require: '^wlClassificationBox'
    restrict: 'E'
    scope:
      entity: '='
      annotation: '='
    template: """
  	  <div ng-class="'wl-' + entity.mainType" ng-show="isVisible" class="entity">
  	    <i ng-show="annotation" ng-class="{ 'wl-linked' : isLinked, 'wl-unlinked' : !isLinked }"></i>
        <i ng-hide="annotation" ng-class="{ 'wl-selected' : isSelected, 'wl-unselected' : !isSelected }"></i>
        <i class="type"></i>
        <span class="label" ng-click="select()">{{entity.label}}</span>
        <small ng-show="entity.occurrences.length > 0">({{entity.occurrences.length}})</small>
        <i ng-class="{ 'wl-more': isOpened == false, 'wl-less': isOpened == true }" ng-click="toggle()"></i>
  	    <span ng-class="{ 'active' : editingModeOn }" ng-click="toggleEditingMode()" ng-show="isOpened" class="wl-edit-button">Edit</span>
        <div class="details" ng-show="isOpened">
          <p ng-hide="editingModeOn"><img class="thumbnail" ng-src="{{ entity.images[0] }}" />{{entity.description}}</p>
          <wl-entity-form entity="entity" ng-show="editingModeOn" on-submit="toggleEditingMode()"></wl-entity-form>
        </div>
  	  </div>

  	"""
    link: ($scope, $element, $attrs, $boxCtrl) ->				      
      
      # Add tile to related container scope
      $boxCtrl.addTile $scope

      $scope.isOpened = false
      $scope.isSelected = false
      $scope.editingModeOn = false

      if $scope.annotation
        $scope.isVisible = ($scope.entity.annotations[ $scope.annotation ]?)
        $scope.isLinked = ($scope.annotation in $scope.entity.occurrences)
      else
        $scope.isVisible = $scope.entity.isRelevant
        $scope.isLinked = false
            
      $scope.toggleEditingMode = ()->
        $scope.editingModeOn = !$scope.editingModeOn

      $scope.open = ()->
      	$scope.isOpened = true
      $scope.close = ()->
      	$scope.isOpened = false  	
      $scope.toggle = ()->
        if !$scope.isOpened 
          $boxCtrl.closeTiles()    
        $scope.isOpened = !$scope.isOpened
        
      $scope.select = ()-> 
        $boxCtrl.onSelectedTile $scope
  ])
