'use strict';

# Test directives.
describe 'directives', ->

  beforeEach module('wordlift.tinymce.plugin.directives')
  beforeEach module('AnalysisService')
  
  # Test the wlEntities directive.
  describe 'wlEntities', ->

    scope = undefined
    element = undefined
    
    # Get the root scope and create a wl-entities element.
    beforeEach inject( ($rootScope) ->
      scope = $rootScope.$new()
      element = angular.element '<wl-entities></wl-entities>'
    )

    # Test for the entity to empty.
    it 'should be empty', inject( ($compile) ->
      $compile(element)(scope)
      scope.$digest()
      expect(element.find('ul').length).toEqual 1
      expect(element.find('li').length).toEqual 0
    )
    # Test entity is not empty.
    it 'should not be empty', inject( ($compile, AnalysisService, $httpBackend) ->
 
      $.ajax('base/app/assets/english.json',
        async: false
      ).done (data) ->
        
        $httpBackend.when('HEAD', /rdf.freebase.com/).respond(200,'');
        analysis = AnalysisService.parse data
        $httpBackend.flush()

        sampleTextAnnotationId = "urn:enhancement-2f293108-0ded-f45a-7945-e7a52640a500"
        scope.analysis = analysis
        scope.textAnnotation = analysis.textAnnotations[sampleTextAnnotationId]
        
        $compile(element)(scope)
        scope.$digest()
        
        expect(element.find('ul').length).toEqual 1
        expect(element.find('li').length).toEqual 2

    )
