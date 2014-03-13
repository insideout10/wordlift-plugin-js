'use strict';

# Test directives.
describe 'directives', ->
  beforeEach module('wordlift.tinymce.plugin.directives')
  beforeEach module('AnalysisService')

  # Test the wlEntity directive.
  describe 'wlEntity', ->
    scope = undefined
    element = undefined

    # Get the root scope and create a wl-entities element.
    beforeEach inject(($rootScope) ->

      scope = $rootScope.$new()

      # The wlEntities directive gets the annotation from the text-annotation attribute.
      element = angular.element '<wl-entity select="select(entityAnnotation)" entity-annotation="entityAnnotation"></wl-entities>'
    )

    it 'fires the select method with the entityAnnotation', inject(($compile) ->
      # Create a mock entity annotation
      scope.entityAnnotation = {}
      # Create a mock select method.
      scope.select = (item) -> # Do nothing
      spyOn scope, 'select'

      # Compile the directive.
      $compile(element)(scope)
      scope.$digest()

      # Simulate the click on the element.
      element.children()[0].click()

      # Check that the select event has been called.
      expect(scope.select).toHaveBeenCalledWith(scope.entityAnnotation)
    )


  # Test the wlEntities directive.
  describe 'wlEntities', ->
    scope = undefined
    element = undefined
    EntitiesController = undefined

    # Get the root scope and create a wl-entities element.
    beforeEach inject(($rootScope, $controller) ->

      # Create a new scope, the scope will be shared between the entities controller and the wlEntities directive,
      # as in the HTML the textAnnotation is passed using the 'textAnnotation' property of the EntitiesController
      # scope.
      scope = $rootScope.$new()

      # Create the EntitiesController with the new scope.
      EntitiesController = $controller 'EntitiesController', { $scope: scope }

      # The wlEntities directive gets the annotation from the text-annotation attribute.
      element = angular.element '<wl-entities text-annotation="textAnnotation"></wl-entities>'
    )

    # Test for the entity to empty.
    it 'should be empty', inject(($compile) ->

      # Compile the directive.
      $compile(element)(scope)
      scope.$digest()

      # Check that there's an empty list.
      expect(element.find('ul').length).toEqual 1
      expect(element.find('li').length).toEqual 0
    )

    # Test entity is not empty.
    it 'should not be empty', inject(($compile, $rootScope, AnalysisService, $httpBackend) ->

      # Compile the directive.
      $compile(element)(scope)
      scope.$digest()

      # Get the mock-up analysis.
      $.ajax('base/app/assets/english.json',
        async: false
      ).done (data) ->

        # Catch all the requests to Freebase.
        $httpBackend.when('HEAD', /rdf.freebase.com/).respond(200, '')

        # Simulate event broadcasted by AnalysisService
        $rootScope.$broadcast 'analysisReceived', AnalysisService.parse data

        # Create a fake textAnnotation element (the textAnnotation exists in the mockup data).
        textAnnotation = angular.element '<span id="urn:enhancement-2f293108-0ded-f45a-7945-e7a52640a500" class="textannotation">David Riccitelli</span>'

        # Simulate event broadcasted by EditorService on annotation click
        $rootScope.$broadcast 'textAnnotationClicked', textAnnotation.attr('id'), { target: textAnnotation }

        # Process changes.
        scope.$digest()

        # Check that there are 2 entity tiles.
        entitiesElems = element.find('wl-entity > div')
        expect(entitiesElems.length).toEqual 2

        # Set the ID of the entity annotations (from the mock file).
        id1 = 'urn:enhancement-bf74ebad-e1bf-88fb-e88e-edd0aebaf401'
        id2 = 'urn:enhancement-9fbb26dd-21f1-53d4-d9f0-d69b83867b03'

        # Click the first entity.
        entitiesElems[0].click()
        expect(scope.textAnnotation.entityAnnotations[id1].selected).toBe true
        expect(scope.textAnnotation.entityAnnotations[id2].selected).toBe false

        # Click on the second entity.
        entitiesElems[1].click()
        expect(scope.textAnnotation.entityAnnotations[id1].selected).toBe false
        expect(scope.textAnnotation.entityAnnotations[id2].selected).toBe true

        # Click again on the second entity.
        entitiesElems[1].click()
        expect(scope.textAnnotation.entityAnnotations[id1].selected).toBe false
        expect(scope.textAnnotation.entityAnnotations[id2].selected).toBe false

    ) 
