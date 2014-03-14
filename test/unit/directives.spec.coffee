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
      element = angular.element '<wl-entity on-select="select(entityAnnotation)" entity-annotation="entityAnnotation"></wl-entities>'
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
      element = angular.element '<wl-entities on-select="select(textAnnotation, entityAnnotation)" text-annotation="textAnnotation"></wl-entities>'
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
      # Create a mock select method.
      scope.select = (ta, ea) -> # Do nothing
      spyOn scope, 'select'

      # Compile the directive.
      $compile(element)(scope)
      scope.$digest()

      # Get the mock-up analysis.
      $.ajax('base/app/assets/english.json',
        async: false
      ).done (data) ->

        # Catch all the requests to Freebase.
        $httpBackend.when('HEAD', /.*/).respond(200, '')

        # Simulate event broadcasted by AnalysisService
        $rootScope.$broadcast 'analysisReceived', AnalysisService.parse data

        # Create a fake textAnnotation element (the textAnnotation exists in the mockup data).
        textAnnotation = angular.element '<span id="urn:enhancement-233fd158-870d-6ca4-b7ce-30313e4a7015" class="textannotation">David Riccitelli</span>'

        # Simulate event broadcasted by EditorService on annotation click
        $rootScope.$broadcast 'textAnnotationClicked', textAnnotation.attr('id'), { target: textAnnotation }

        # Process changes.
        scope.$digest()

        # Check that there are 2 entity tiles.
        entitiesElems = element.find('wl-entity > div')
        expect(entitiesElems.length).toEqual 3

        # Set the ID of the entity annotations (from the mock file).
        id1 = 'urn:enhancement-3a64853f-2f48-c749-0073-c5787acf3b0e'
        id2 = 'urn:enhancement-26a923a4-fbb8-b39d-53ad-e2922474b7fc'

        # Click the first entity.
        entitiesElems[1].click()
        expect(scope.textAnnotation.entityAnnotations[id1].selected).toBe true
        expect(scope.textAnnotation.entityAnnotations[id2].selected).toBe false
        # Check that the select event has been called.
        expect(scope.select).toHaveBeenCalledWith(scope.textAnnotation, scope.textAnnotation.entityAnnotations[id1])

        # Click on the second entity.
        entitiesElems[2].click()
        expect(scope.textAnnotation.entityAnnotations[id1].selected).toBe false
        expect(scope.textAnnotation.entityAnnotations[id2].selected).toBe true
        # Check that the select event has been called.
        expect(scope.select).toHaveBeenCalledWith(scope.textAnnotation, scope.textAnnotation.entityAnnotations[id2])

        # Click again on the second entity.
        entitiesElems[2].click()
        expect(scope.textAnnotation.entityAnnotations[id1].selected).toBe false
        expect(scope.textAnnotation.entityAnnotations[id2].selected).toBe false
        # Check that the select event has been called.
        expect(scope.select).toHaveBeenCalledWith(scope.textAnnotation, null)

    ) 

  describe 'wlEntityInputBoxes', ->
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
      element = angular.element '<wl-entity-input-boxes text-annotations="analysis.textAnnotations"></wl-entity-input-boxes>'
    )

    # Test for the entity to empty.
    it 'creates input boxes and textareas with entity data', inject((AnalysisService, $compile, $httpBackend, $rootScope) ->

      # Compile the directive.
      $compile(element)(scope)
      scope.$digest()

      # Get the mock-up analysis.
      $.ajax('base/app/assets/english.json',
        async: false
      ).done (data) ->

        # Catch all the requests to Freebase.
        $httpBackend.when('HEAD', /.*/).respond(200, '')

        # Simulate event broadcasted by AnalysisService
        $rootScope.$broadcast 'analysisReceived', AnalysisService.parse data

        # Check that the analysis is set.
        expect(scope.analysis).not.toBe undefined
        expect(scope.analysis.textAnnotations).not.toBe undefined

        # Check that there are no input boxes (no entities selected).
        expect(element.find('input').length).toEqual 0
        expect(element.find('textarea').length).toEqual 0

        # Select a text annotation.
        textAnnotation1 = scope.analysis.textAnnotations['urn:enhancement-1a452dcd-b97f-6d9c-8de5-b4cec57ec020']
        expect(textAnnotation1).not.toBe undefined

        # Select an entity annotation in the first text annotation.
        entityAnnotation1 = textAnnotation1.entityAnnotations['urn:enhancement-ec266952-de23-ef06-896f-02f9434e99b0']
        expect(entityAnnotation1).not.toBe undefined

        # Select one entity.
        entityAnnotation1.selected = true
        scope.$digest()

        # Check that there are no input boxes (no entities selected).
        fieldName1 = "wl_entities\\[#{entityAnnotation1.entity.id}\\]"
        expect(element.find('input').length).toEqual 7
        expect(element.find('textarea').length).toEqual 1

        expect(element.find("input[name='#{fieldName1}\\[uri\\]']")[0].value).toEqual entityAnnotation1.entity.id
        expect(element.find("input[name='#{fieldName1}\\[label\\]']")[0].value).toEqual entityAnnotation1.entity.label
        expect(element.find("input[name='#{fieldName1}\\[type\\]']")[0].value).toEqual entityAnnotation1.entity.type
        expect(element.find("input[name='#{fieldName1}\\[image\\]']")[0].value).toEqual entityAnnotation1.entity.thumbnails[0]
        expect(element.find("input[name='#{fieldName1}\\[image\\]']")[1].value).toEqual entityAnnotation1.entity.thumbnails[1]
        expect(element.find("input[name='#{fieldName1}\\[image\\]']")[2].value).toEqual entityAnnotation1.entity.thumbnails[2]
        expect(element.find("input[name='#{fieldName1}\\[image\\]']")[3].value).toEqual entityAnnotation1.entity.thumbnails[3]

        # Get the decoded description and check it against the entity.
        description = $(element.find("textarea[name='#{fieldName1}\\[description\\]']")[0]).text()
        expect(description).toEqual entityAnnotation1.entity.description

        # Deselect the entity.
        entityAnnotation1.selected = false
        scope.$digest()

        # Check that no inputs are selected.
        expect(element.find('input').length).toEqual 0
        expect(element.find('textarea').length).toEqual 0

        # Reselect the entity.
        entityAnnotation1.selected = true
        scope.$digest()

        # Select a text annotation.
        textAnnotation2 = scope.analysis.textAnnotations['urn:enhancement-233fd158-870d-6ca4-b7ce-30313e4a7015']
        expect(textAnnotation2).not.toBe undefined

        # Select an entity annotation in the first text annotation.
        entityAnnotation2 = textAnnotation2.entityAnnotations['urn:enhancement-26a923a4-fbb8-b39d-53ad-e2922474b7fc']
        expect(entityAnnotation2).not.toBe undefined

        # Select another entity in the same text annotation.
        entityAnnotation2.selected = true
        scope.$digest()

        # Check that the number of inputs matches.
        expect(element.find('input').length).toEqual 11
        expect(element.find('textarea').length).toEqual 2

        # Check that there are no input boxes (no entities selected).
        fieldName2 = "wl_entities\\[#{entityAnnotation2.entity.id}\\]"

        expect(element.find("input[name='#{fieldName2}\\[uri\\]']")[0].value).toEqual entityAnnotation2.entity.id
        expect(element.find("input[name='#{fieldName2}\\[label\\]']")[0].value).toEqual entityAnnotation2.entity.label
        expect(element.find("textarea[name='#{fieldName2}\\[description\\]']")[0].innerHTML).toEqual entityAnnotation2.entity.description
        expect(element.find("input[name='#{fieldName2}\\[type\\]']")[0].value).toEqual entityAnnotation2.entity.type
        expect(element.find("input[name='#{fieldName2}\\[image\\]']")[0].value).toEqual entityAnnotation2.entity.thumbnails[0]

    )
