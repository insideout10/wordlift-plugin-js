'use strict';

# Test directives.
describe 'directives', ->

  beforeEach module('wordlift.tinymce.plugin.directives')
  beforeEach module('AnalysisService')
  
  # Test the wlEntities directive.
  describe 'wlEntities', ->

    scope = undefined
    element = undefined
    EntitiesController = undefined

    # Get the root scope and create a wl-entities element.
    beforeEach inject( ($rootScope, $controller) ->
      scope = $rootScope.$new()
      element = angular.element '<wl-entities></wl-entities>'
      EntitiesController = $controller 'EntitiesController', { $scope: scope }
  
    )

    # Test for the entity to empty.
    it 'should be empty', inject( ($compile) ->
      $compile(element)(scope)
      scope.$digest()
      expect(element.find('ul').length).toEqual 1
      expect(element.find('li').length).toEqual 0
    )
    # Test entity is not empty.
    it 'should not be empty', inject( ($compile, $rootScope, AnalysisService, $httpBackend) ->
      
      $compile(element)(scope)
      scope.$digest()
      
      expect(element.find('li').length).toEqual 0

      $.ajax('base/app/assets/english.json',
        async: false
      ).done (data) ->
        
        $httpBackend.when('HEAD', /rdf.freebase.com/)
        .respond(200,'');
        
        # Simulate event broadcasted by AnalysisService
        $rootScope.$broadcast 'analysisReceived', AnalysisService.parse data
        sampleTextAnnotation = angular.element '<span id="urn:enhancement-2f293108-0ded-f45a-7945-e7a52640a500" class="textannotation">David Riccitelli</span>'
        # Simulate event broadcasted by EditorService on annotation click
        $rootScope.$broadcast 'textAnnotationClicked', sampleTextAnnotation.attr('id'), { target: sampleTextAnnotation }
        
        scope.$digest()
        
        expect(element.find('li').length).toEqual 2

    ) 
