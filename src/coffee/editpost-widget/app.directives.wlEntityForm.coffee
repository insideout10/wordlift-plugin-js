angular.module('wordlift.editpost.widget.directives.wlEntityForm', [])
.directive('wlEntityForm', ['configuration', '$log', (configuration, $log)->
    restrict: 'E'
    scope:
      entity: '='
      onSubmit: '&'
    template: """
      <div name="wordlift" class="wl-entity-form">
      <div ng-show="entity.images.length > 0">
          <img ng-src="{{entity.images[0]}}" wl-src="{{configuration.defaultThumbnailPath}}" />
      </div>
      <div>
          <label>Entity label</label>
          <input type="text" ng-model="entity.label" ng-disabled="checkEntityId(entity.id)" />
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
      <div class="wl-suggested-sameas-wrapper">
          <label>Entity Same as (*)</label>
          <input type="text" ng-model="entity.sameAs" />
          <h5 ng-show="entity.suggestedSameAs.length > 0">same as suggestions</h5>
          <div ng-click="setSameAs(sameAs)" ng-class="{ 'active': entity.sameAs == sameAs }" class="wl-sameas" ng-repeat="sameAs in entity.suggestedSameAs">
            {{sameAs}}
          </div>
      </div>
      
      <div class="wl-submit-wrapper">
        <span class="button button-primary" ng-click="onSubmit()">Save</span>
      </div>

      </div>
    """
    link: ($scope, $element, $attrs, $ctrl) ->  

      $scope.configuration = configuration

      $scope.setSameAs = (uri)->
        $scope.entity.sameAs = uri
      
      $scope.checkEntityId = (uri)->
        /^(f|ht)tps?:\/\//i.test(uri)

      $scope.supportedTypes = ({ id: type.css.replace('wl-',''), name: type.uri } for type in configuration.types)

])
