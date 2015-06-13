angular.module('wordlift.ui.carousel', [])
.directive('wlCarousel', ['$window', '$log', ($window, $log)->
  restrict: 'A'
  scope: true
  transclude: true      
  template: """
      <div class="wl-carousel">
        <div class="wl-panes" style="width:{{panesWidth}}px; left:{{position}}px;" ng-transclude ng-swipe-right="next()"></div>
        <div class="wl-carousel-arrow wl-prev" ng-click="prev()" ng-show="currentPaneIndex > 0">
          <i class="wl-angle-left" />
        </div>
        <div class="wl-carousel-arrow wl-next" ng-click="next()" ng-hide="(currentPaneIndex + visibleElements()) == panes.length">
          <i class="wl-angle-right" />
        </div>
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
    $scope.currentPaneIndex = 0

    $scope.next = ()->
      $scope.position = $scope.position - $scope.itemWidth
      $scope.currentPaneIndex = $scope.currentPaneIndex + 1
    $scope.prev = ()->
      $scope.position = $scope.position + $scope.itemWidth
      $scope.currentPaneIndex = $scope.currentPaneIndex - 1

    $scope.setPanesWrapperWidth = ()->
      $scope.panesWidth = $scope.panes.length * $scope.itemWidth

    w.bind 'resize', ()->
        
      $scope.itemWidth =  $element.width() / $scope.visibleElements();
      $scope.setPanesWrapperWidth()
      for pane in $scope.panes
        pane.scope.setWidth $scope.itemWidth
      $scope.$apply()
      $scope.position = 0;
      $scope.currentPaneIndex = 0

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
  restrict: 'EA'
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