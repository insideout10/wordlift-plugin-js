angular.module('wordlift.tinymce.plugin.directives', ['wordlift.tinymce.plugin.controllers'])
.directive('wlMetaBoxSelectedEntity', ->
    restrict: 'AE'
    scope:
      index: '='
      entity: '='
    template: """
      <span>{{entity.label}} (<small>{{entity.type}}</span>)\n
      <br /><small>{{entity.thumbnail}}</small>
      <input type="hidden" name="entities[{{index}}]['id']" value="{{entity.id}}" />\n
      <input type="hidden" name="entities[{{index}}]['label']" value="{{entity.label}}" />\n
      <input type="hidden" name="entities[{{index}}]['description']" value="{{entity.description}}" />\n
      <input type="hidden" name="entities[{{index}}]['type']" value="{{entity.type}}" />\n
      <input type="hidden" name="entities[{{index}}]['thumbnail']" value="{{entity.thumbnail}}" />\n
    """
  )
# The wlEntities directive provides a UI for disambiguating the entities for a provided text annotation.
.directive('wlEntities', ->
    restrict: 'E'
    link: (scope, element, attrs)->
    template: """
      <div>
        <ul>
          <li ng-repeat="(id, entityAnnotation) in textAnnotation.entityAnnotations | orderObjectBy:'confidence':true">
            <div class="entity {{entityAnnotation.entity.type}}" ng-class="{selected: true==entityAnnotation.selected}" ng-click="onEntityClicked(id, entityAnnotation)" ng-show="entityAnnotation.entity.label">
              <div class="thumbnail" ng-show="entityAnnotation.entity.thumbnail" title="{{entityAnnotation.entity.id}}" ng-attr-style="background-image: url({{entityAnnotation.entity.thumbnail}})"></div>
              <div class="thumbnail empty" ng-hide="entityAnnotation.entity.thumbnail" title="{{entityAnnotation.entity.id}}"></div>
              <div class="confidence" ng-bind="entityAnnotation.confidence"></div>
              <div class="label" ng-bind="entityAnnotation.entity.label"></div>
              <div class="type"></div>
              <div class="source" ng-class="entityAnnotation.entity.source" ng-bind="entityAnnotation.entity.source"></div>
            </div>
          </li>
        </ul>
      </div>
    """
  )

