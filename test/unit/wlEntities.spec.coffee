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
      element.children('div')[0].click()

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

        # Check that there are 2 entities.
        expect(element.find('li').length).toEqual 2

    ) 
