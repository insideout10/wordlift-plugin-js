angular.module('wordlift.editpost.widget.directives.wlEntityForm', [])
.directive('wlEntityForm', ['$log', ($log)->
    restrict: 'E'
    scope:
      entity: '='
      onSubmit: '&'
    template: """
      <form class="wl-entity-form" ng-submit="onSubmit()">
      <div>
          <label>Entity label</label>
          <input type="text" ng-model="entity.label" />
      </div>
      <div>
          <label>Entity type</label>
          <select ng-model="entity.mainType" ng-options="type.id as type.name for type in supportedTypes" ></select>
      </div>
      <div>
          <label>Entity Description</label>
          <textarea ng-model="entity.description" rows="6"></textarea>
      </div>
      <div>
          <label>Entity id</label>
          <input type="text" ng-model="entity.id" />
      </div>
      <div>
          <label>Entity Same as</label>
          <input type="text" ng-model="entity.sameAs" />
      </div>
      <input type="submit" value="save" />
      </form>
    """
    link: ($scope, $element, $attrs, $ctrl) ->  
      $scope.supportedTypes = [
        { id: 'person', name: 'http://schema.org/Person' },
        { id: 'place', name: 'http://schema.org/Place' },
        { id: 'organization', name: 'http://schema.org/Organization' },
        { id: 'event', name: 'http://schema.org/Event' },
        { id: 'creative-work', name: 'http://schema.org/CreativeWork' },
        { id: 'thing', name: 'http://schema.org/Thing' }
      ]
])
