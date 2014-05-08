angular.module('wordlift.tinymce.plugin.directives', ['wordlift.directives.wlEntityProps','wordlift.tinymce.plugin.controllers'])
# The wlEntities directive provides a UI for disambiguating the entities for a provided text annotation.
.directive('wlEntities', ->
    # Restrict the directive to elements only (<wl-entities text-annotation="..."></wl-entities>)
    restrict: 'E'
    # Create a separate scope
    scope:
    # Get the text annotation from the text-annotation attribute.
      textAnnotation: '='
      entityTypes: '='
      onSelect: '&'
    # Create the link function in order to bind to children elements events.
    link: (scope, element, attrs) ->

      # Filter the type definition accordingly with current entity main known type
      # It's used to set the type definition on wl-entity directive
      scope.getCurrentTypeDefinition = (entityAnnotation) ->
        scope.entityTypes.filter (entityType) ->
          entityType.uri is entityAnnotation.entity?.type
        .pop()

      scope.select = (item) ->

        # Set the selected flag on each annotation.
        for id, entityAnnotation of scope.textAnnotation.entityAnnotations
          # The selected flag is set to false for each annotation which is not the selected one.
          # For the selected one is set to true only if the entity is not selected already, otherwise it is deselected.
          entityAnnotation.selected = item.id is entityAnnotation.id && !entityAnnotation.selected

        # Call the select function with the textAnnotation and the selected entityAnnotation or null.
        scope.onSelect
          textAnnotation: scope.textAnnotation
          entityAnnotation: if item.selected then item else null

    template: """
      <div>
        <ul>
          <li ng-repeat="entityAnnotation in textAnnotation.entityAnnotations | orderObjectBy:'confidence':true">
            <wl-entity type-definition="getCurrentTypeDefinition(entityAnnotation)" on-select="select(entityAnnotation)" entity-annotation="entityAnnotation"></wl-entity>
          </li>
        </ul>
      </div>
    """
  )
# The wlEntity directive shows a tile for a provided entityAnnotation. When a tile is clicked the function provided
# in the select attribute is called.
.directive('wlEntity', ['$interpolate','$log', ($interpolate, $log)->
    restrict: 'E'
    scope:
      typeDefinition: '='
      entityAnnotation: '='
      onSelect: '&'
    # Create the link function in order to bind to children elements events.
    link: (scope, element, attrs) ->
      # Holds a reference to the current entity 
      scope.entity = scope.entityAnnotation?.entity

      # Render an entity property
      # If the property is missing, look for the proper template in the typeDefinition
      # and interpolate it using entity object as context
      # If the template is missing log a warning message and returns a blank string
      scope.renderEntityProperty = (propertyName) ->
        return scope.entity[propertyName] if scope.entity?.hasOwnProperty(propertyName)
        return $interpolate(scope.typeDefinition.templates[propertyName])(scope.entity) if scope.typeDefinition.templates.hasOwnProperty(propertyName)
        # $log.warn "Cannot find template #{propertyName} for typeDefinition #{scope.typeDefinition.uri}"  
        ""

    template: """
      <div class="entity {{entityAnnotation.entity.css}}" ng-class="{selected: true==entityAnnotation.selected}" ng-click="onSelect()" ng-show="entity.label">
        <div class="thumbnail" ng-show="entity.thumbnail" title="{{entity.id}}" ng-attr-style="background-image: url({{entity.thumbnail}})"></div>
        <div class="thumbnail empty" ng-hide="entity.thumbnail" title="{{entity.id}}"></div>
        <div class="confidence" ng-bind="entityAnnotation.confidence"></div>
        <div class="label" ng-bind="renderEntityProperty('label')"></div>
        <div class="url" ng-bind="renderEntityProperty('subtitle')"></div>
        <div class="type"></div>
        <div class="source" ng-class="entity.source" ng-bind="entity.source"></div>
      </div>
    """
  ])
# The wlEntityInputBoxes prints the inputs and textareas with entities data.
.directive('wlEntityInputBoxes', ->
    restrict: 'E'
    scope:
      textAnnotations: '='
    template: """
      <div class="wl-entity-input-boxes" ng-repeat="textAnnotation in textAnnotations">
        <div ng-repeat="entityAnnotation in textAnnotation.entityAnnotations | filterObjectBy:'selected':true">

          <input type='text' name='wl_entities[{{entityAnnotation.entity.id}}][uri]' value='{{entityAnnotation.entity.id}}'>
          <input type='text' name='wl_entities[{{entityAnnotation.entity.id}}][label]' value='{{entityAnnotation.entity.label}}'>
          <textarea name='wl_entities[{{entityAnnotation.entity.id}}][description]'>{{entityAnnotation.entity.description}}</textarea>

          <input type='text' name='wl_entities[{{entityAnnotation.entity.id}}][main_type]' value='{{entityAnnotation.entity.type}}'>

          <input ng-repeat="type in entityAnnotation.entity.types" type='text'
          	name='wl_entities[{{entityAnnotation.entity.id}}][type][]' value='{{type}}'>

          <input ng-repeat="image in entityAnnotation.entity.thumbnails" type='text'
            name='wl_entities[{{entityAnnotation.entity.id}}][image][]' value='{{image}}'>
          <input ng-repeat="sameAs in entityAnnotation.entity.sameAs" type='text'
            name='wl_entities[{{entityAnnotation.entity.id}}][sameas][]' value='{{sameAs}}'>

          <input type='text' name='wl_entities[{{entityAnnotation.entity.id}}][latitude]' value='{{entityAnnotation.entity.latitude}}'>
          <input type='text' name='wl_entities[{{entityAnnotation.entity.id}}][longitude]' value='{{entityAnnotation.entity.longitude}}'>

        </div>
      </div>
    """
  )
.directive('autocomplete', ['$compile', '$q', '$log', ($compile, $q, $log) ->
    restrict: "A",
    scope:
      source: '&'
      onSelect: '&'
    link: (originalScope, elem, attrs, ctrl) ->
      templateHtml = '<wl-entity on-select="select(entityAnnotation)" entity-annotation="entityAnnotation"></wl-entity>'

      elem.autocomplete
        source: (request, response) ->
          locals = { $viewValue: request.term }
          $q.when(originalScope.source(locals)).then (matches) ->
            response matches
        minLength: 3
        open: () ->
          originalScope.$emit('autocompleteOpened')
        close: () ->
          originalScope.$emit('autocompleteClosed')
      
      .data("ui-autocomplete")._renderItem = (ul, ea) ->
        
        scope = originalScope.$new();
        scope.entityAnnotation = ea
        
        scope.select = (entityAnnotation) ->
          # Set the higher priority for this item
          entityAnnotation.confidence = 1.0
          # Reset autocomplete field & hide results
          angular.element(elem).val('')
          angular.element(ul).hide()
          originalScope.$emit('autocompleteClosed')
      
          # Call the onSelect callback
          originalScope.onSelect
            entityAnnotation: entityAnnotation
         
        originalScope.$on '$destroy', ()->
          scope.$destroy();
        el = angular.element(templateHtml)
        compiled = $compile(el)

        $("<li>").append(el).appendTo(ul)
        compiled(scope)
      
  ])

