angular.module('wordlift.editpost.widget.directives.wlEntityForm', [])
.directive('wlEntityForm', ['$log', ($log)->
    restrict: 'E'
    scope:
      entity: '='
      onSubmit: '&'
    template: """
      <div name="wordlift" class="wl-entity-form">
      <div ng-show="entity.images.length > 0">
          <img ng-src="{{entity.images[0]}}" />
      </div>
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
      <div ng-show="checkEntityId(entity.id)">
          <label>Entity Id</label>
          <input type="text" ng-model="entity.id" disabled="true" />
      </div>
      <div>
          <label>Entity Same as (*)</label>
          <input type="text" ng-model="entity.sameAs" />
      </div>
      
      <div class="wl-submit-wrapper">
        <span class="button button-primary" ng-click="onSubmit()">Save</span>
      </div>

      </div>
    """
    link: ($scope, $element, $attrs, $ctrl) ->  

      $scope.checkEntityId = (uri)->
        /^(f|ht)tps?:\/\//i.test(uri)

      # TMP
      $scope.supportedTypes = [
        { id: 'person', name: 'http://schema.org/Person' },
        { id: 'place', name: 'http://schema.org/Place' },
        { id: 'organization', name: 'http://schema.org/Organization' },
        { id: 'event', name: 'http://schema.org/Event' },
        { id: 'creative-work', name: 'http://schema.org/CreativeWork' },
        { id: 'thing', name: 'http://schema.org/Thing' }
      ]
])
