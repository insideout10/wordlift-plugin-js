'use strict';

# Test services.
describe 'services', ->
  beforeEach module('wordlift.tinymce.plugin.services')
  beforeEach module('AnalysisService')

  # Test the wlEntity directive.
  describe 'AnalysisService', ->

    it 'parses analysis data', inject((AnalysisService, $httpBackend, $rootScope) ->

      # Get the mock-up analysis.
      $.ajax('base/app/assets/english.json',
        async: false
      ).done (data) ->

        # Catch all the requests to Freebase.
        $httpBackend.when('HEAD', /.*/).respond(200, '')

        # Simulate event broadcasted by AnalysisService
        analysis = AnalysisService.parse data

        # Check that the analysis results conform.
        expect(analysis).toEqual jasmine.any(Object)
        expect(analysis.language).not.toBe undefined
        expect(analysis.entities).not.toBe undefined
        expect(analysis.entityAnnotations).not.toBe undefined
        expect(analysis.textAnnotations).not.toBe undefined
        expect(analysis.languages).not.toBe undefined
        expect(analysis.language).toEqual 'en'
        expect(Object.keys(analysis.entities).length).toEqual 28
        expect(Object.keys(analysis.entityAnnotations).length).toEqual 30
        expect(Object.keys(analysis.textAnnotations).length).toEqual 10
        expect(Object.keys(analysis.languages).length).toEqual 1

        # Get a Text Annotation and three entities that related to that Text Annotation.
        textAnnotationId = 'urn:enhancement-1a452dcd-b97f-6d9c-8de5-b4cec57ec020'
        entityAnnotation1Id = 'urn:enhancement-509b6609-e7d6-4c08-e627-afcfd637c42f'
        entityAnnotation2Id = 'urn:enhancement-ec266952-de23-ef06-896f-02f9434e99b0'
        entityAnnotation3Id = 'urn:enhancement-3366ede4-c449-f43b-e3cf-297fb41a619d'

        textAnnotation = analysis.textAnnotations[textAnnotationId]
        expect(textAnnotation).not.toBe undefined

        entityAnnotation1 = textAnnotation.entityAnnotations[entityAnnotation1Id]
        expect(entityAnnotation1).not.toBe undefined
        expect(entityAnnotation1.entity.sameAs).not.toBe undefined

        entityAnnotation2 = textAnnotation.entityAnnotations[entityAnnotation2Id]
        expect(entityAnnotation2).not.toBe undefined
        expect(entityAnnotation2.entity.sameAs).not.toBe undefined

        entityAnnotation3 = textAnnotation.entityAnnotations[entityAnnotation3Id]
        expect(entityAnnotation3).not.toBe undefined
        expect(angular.isArray(entityAnnotation3.entity.sameAs)).toBe true
    )

    it 'parses and merges analysis data', inject((AnalysisService, $httpBackend, $rootScope) ->

      # Get the mock-up analysis.
      $.ajax('base/app/assets/english.json',
        async: false
      ).done (data) ->

        # Catch all the requests to Freebase.
        $httpBackend.when('HEAD', /.*/).respond(200, '')

        # Simulate event broadcasted by AnalysisService
        analysis = AnalysisService.parse data, true

        # Check that the analysis results conform.
        expect(analysis).toEqual jasmine.any(Object)
        expect(analysis.language).not.toBe undefined
        expect(analysis.entities).not.toBe undefined
        expect(analysis.entityAnnotations).not.toBe undefined
        expect(analysis.textAnnotations).not.toBe undefined
        expect(analysis.languages).not.toBe undefined
        expect(analysis.language).toEqual 'en'
        expect(Object.keys(analysis.entities).length).toEqual 28
        expect(Object.keys(analysis.entityAnnotations).length).toEqual 30
        expect(Object.keys(analysis.textAnnotations).length).toEqual 10
        expect(Object.keys(analysis.languages).length).toEqual 1

        # Get a Text Annotation and three entities that related to that Text Annotation.
        textAnnotationId = 'urn:enhancement-1a452dcd-b97f-6d9c-8de5-b4cec57ec020'
        entityAnnotationId = 'urn:enhancement-3366ede4-c449-f43b-e3cf-297fb41a619d'

        # Set a reference to the text annotation.
        textAnnotation = analysis.textAnnotations[textAnnotationId]
        expect(textAnnotation).not.toBe undefined

        # Set a reference to the entity annotation.
        entityAnnotation = textAnnotation.entityAnnotations[entityAnnotationId]
        expect(entityAnnotation).not.toBe undefined
        expect(entityAnnotation.entity).not.toBe undefined
        expect(entityAnnotation.entity.sameAs).not.toBe undefined

        # Set a reference to the entity.
        entity = entityAnnotation.entity
        expect(entity.thumbnails.length).toEqual 5
        expect(entity.thumbnails[0]).toEqual 'http://upload.wikimedia.org/wikipedia/commons/a/a6/Flag_of_Rome.svg'
        expect(entity.thumbnails[1]).toEqual 'https://usercontent.googleapis.com/freebase/v1/image/m/04js6kc?maxwidth=4096&maxheight=4096'
        expect(entity.thumbnails[2]).toEqual 'https://usercontent.googleapis.com/freebase/v1/image/m/04js6kq?maxwidth=4096&maxheight=4096'
        expect(entity.thumbnails[3]).toEqual 'https://usercontent.googleapis.com/freebase/v1/image/m/04mn0b4?maxwidth=4096&maxheight=4096'
        expect(entity.thumbnails[4]).toEqual 'https://usercontent.googleapis.com/freebase/v1/image/m/04mn0bt?maxwidth=4096&maxheight=4096'

        expect(entityAnnotation.entity).not.toBe undefined for id, entityAnnotation of analysis.entityAnnotations

        for id, textAnnotation of analysis.textAnnotations
          for id, entityAnnotation of textAnnotation.entityAnnotations
            expect(entityAnnotation.entity).not.toBe undefined

    )

    it 'merges data while keeping sameAs', inject((AnalysisService, $httpBackend, $rootScope) ->

      # Get the mock-up analysis.
      $.ajax('base/app/assets/english.002.json',
        async: false
      ).done (data) ->

        # Catch all the requests to Freebase.
        $httpBackend.when('HEAD', /.*/).respond(200, '')

        # Simulate event broadcasted by AnalysisService
        analysis = AnalysisService.parse data, true

        # Check that the analysis results conform.
        expect(analysis).toEqual jasmine.any(Object)
        expect(analysis.language).not.toBe undefined
        expect(analysis.entities).not.toBe undefined
        expect(analysis.entityAnnotations).not.toBe undefined
        expect(analysis.textAnnotations).not.toBe undefined
        expect(analysis.languages).not.toBe undefined
        expect(analysis.language).toEqual 'en'
        expect(Object.keys(analysis.entities).length).toEqual 18
        expect(Object.keys(analysis.entityAnnotations).length).toEqual 19
        expect(Object.keys(analysis.textAnnotations).length).toEqual 10
        expect(Object.keys(analysis.languages).length).toEqual 1

        # Get a Text Annotation and three entities that related to that Text Annotation.
        textAnnotationId = 'urn:enhancement-a6bb446e-6e95-d6be-e91c-32833aa58b32'
        entityAnnotationId = 'urn:enhancement-663e0cfd-c482-f695-674e-cae98e42dd18'

        # Set a reference to the text annotation.
        textAnnotation = analysis.textAnnotations[textAnnotationId]
        expect(textAnnotation).not.toBe undefined

#        dump "[ #{id} ][ entity id :: #{entityAnnotation.entity.id} ][ #{entityAnnotation.entity.sameAs.length} ]" for id, entityAnnotation of textAnnotation.entityAnnotations

        # Set a reference to the entity annotation.
        entityAnnotation = textAnnotation.entityAnnotations[entityAnnotationId]

        expect(entityAnnotation).not.toBe undefined
        expect(entityAnnotation.entity).not.toBe undefined
        expect(entityAnnotation.entity.sameAs).not.toBe undefined

        # Set a reference to the entity.
        entity = entityAnnotation.entity
        expect(entity.thumbnails.length).toEqual 9
        for i in [0...entity.thumbnails.length]
          expect(entity.thumbnails[i]).toEqual entity.thumbnails[i]

        expect(entityAnnotation.entity).not.toBe undefined for id, entityAnnotation of analysis.entityAnnotations

        for id, textAnnotation of analysis.textAnnotations
          for id, entityAnnotation of textAnnotation.entityAnnotations
            expect(entityAnnotation.entity).not.toBe undefined

    )

    it 'parses correctly analysis result without prefixes', inject((AnalysisService, $httpBackend, $rootScope) ->

      # Get the mock-up analysis.
      $.ajax('base/app/assets/tim_berners-lee.json',
        async: false
      ).done (data) ->

        # Catch all the requests to Freebase.
        $httpBackend.when('HEAD', /.*/).respond(200, '')

        # Simulate event broadcasted by AnalysisService
        analysis = AnalysisService.parse data, true

        # Check that the analysis results conform.
        expect(analysis).toEqual jasmine.any(Object)
        expect(analysis.language).not.toBe undefined
        expect(analysis.entities).not.toBe undefined
        expect(analysis.entityAnnotations).not.toBe undefined
        expect(analysis.textAnnotations).not.toBe undefined
        expect(analysis.languages).not.toBe undefined
        expect(analysis.language).toEqual 'en'
        expect(Object.keys(analysis.entities).length).toEqual 9
        expect(Object.keys(analysis.entityAnnotations).length).toEqual 9
        expect(Object.keys(analysis.textAnnotations).length).toEqual 3
        expect(Object.keys(analysis.languages).length).toEqual 1
    )

    it 'finds entities for all the text annotations', inject((AnalysisService, $httpBackend, $rootScope) ->

      # Get the mock-up analysis.
      $.ajax('base/app/assets/eight_players_joined.json',
        async: false
      ).done (data) ->

        # Catch all the requests to Freebase.
        $httpBackend.when('HEAD', /.*/).respond(200, '')

        # Simulate event broadcasted by AnalysisService
        analysis = AnalysisService.parse data, true

        # Check that the analysis results conform.
        expect(analysis).toEqual jasmine.any(Object)
        expect(analysis.language).not.toBe undefined
        expect(analysis.entities).not.toBe undefined
        expect(analysis.entityAnnotations).not.toBe undefined
        expect(analysis.textAnnotations).not.toBe undefined
        expect(analysis.languages).not.toBe undefined
        expect(analysis.language).toEqual 'en'
        expect(Object.keys(analysis.entities).length).toEqual 44
        expect(Object.keys(analysis.entityAnnotations).length).toEqual 46
        expect(Object.keys(analysis.textAnnotations).length).toEqual 18
        expect(Object.keys(analysis.languages).length).toEqual 1

        for id, textAnnotation of analysis.textAnnotations
          expect(Object.keys(textAnnotation.entityAnnotations).length).toBeGreaterThan 0
    )

    it 'parses correctly entity annotations that are related to more than one text annotation', inject((AnalysisService, $httpBackend, $rootScope) ->

      # Get the mock-up analysis.
      $.ajax('base/app/assets/sparql.json',
        async: false
      ).done (data) ->

        # Catch all the requests to Freebase.
        $httpBackend.when('HEAD', /.*/).respond(200, '')

        # Simulate event broadcasted by AnalysisService
        analysis = AnalysisService.parse data, true

        # Check that the analysis results conform.
        expect(analysis).toEqual jasmine.any(Object)
        expect(analysis.language).not.toBe undefined
        expect(analysis.entities).not.toBe undefined
        expect(analysis.entityAnnotations).not.toBe undefined
        expect(analysis.textAnnotations).not.toBe undefined
        expect(analysis.languages).not.toBe undefined
        expect(analysis.language).toEqual 'en'
#        expect(Object.keys(analysis.entities).length).toEqual 44
        expect(Object.keys(analysis.entityAnnotations).length).toEqual 21
        expect(Object.keys(analysis.textAnnotations).length).toEqual 12
#        expect(Object.keys(analysis.languages).length).toEqual 1

        for textAnnotationId, textAnnotation of analysis.textAnnotations
          dump "[ text-annotation id :: #{textAnnotationId} ][ selected text :: #{textAnnotation.selectedText} ][ entity annotations count :: #{Object.keys(textAnnotation.entityAnnotations).length} ]"
          expect(Object.keys(textAnnotation.entityAnnotations).length).toBeGreaterThan 0
          for entityAnnotationId, entityAnnotation of textAnnotation.entityAnnotations
            dump "[ entity-annotation id :: #{entityAnnotationId} ][ entity id :: #{entityAnnotation.entity.id} ][ confidence :: #{entityAnnotation.confidence} ]"

        entityAnnotation1 = analysis.textAnnotations['urn:enhancement-9de365a0-3312-4927-0cbd-8735d460901d']
          .entityAnnotations['urn:enhancement-1c03bb72-6cfe-3dfc-ad7f-3082a5ce086b']
        entityAnnotation2 = analysis.textAnnotations['urn:enhancement-d791d926-23e9-61f9-7b67-6414586bc49e']
          .entityAnnotations['urn:enhancement-1c03bb72-6cfe-3dfc-ad7f-3082a5ce086b']

        expect(entityAnnotation1).not.toBe undefined
        expect(entityAnnotation2).not.toBe undefined

        expect(entityAnnotation1).not.toBe entityAnnotation2
        expect(entityAnnotation1.selected).toBe false
        expect(entityAnnotation2.selected).toBe false

        entityAnnotation1.selected = true
        expect(entityAnnotation1.selected).toBe true
        expect(entityAnnotation2.selected).toBe false
    )

  describe 'EditorService', ->

    it "embeds analysis results also when there are parentheses in the selected text", inject( (AnalysisService, EditorService, $httpBackend) ->

      # Get the mock-up analysis.
      $.ajax('base/app/assets/tim_berners-lee_2.json',
        async: false
      ).done (data) ->

        # Catch all the requests to Freebase.
        $httpBackend.when('HEAD', /.*/).respond(200, '')

        # Simulate event broadcasted by AnalysisService
        analysis = AnalysisService.parse data, true
        # Check that the analysis results conform.
        expect(analysis).toEqual jasmine.any(Object)

        EditorService.embedAnalysis analysis

    )