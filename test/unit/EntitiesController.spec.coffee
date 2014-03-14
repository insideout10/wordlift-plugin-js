describe "EditorController tests", ->
  $scope = undefined
  EntitiesController = undefined
  analysis = undefined

  # Tests set-up.
  beforeEach module('wordlift.tinymce.plugin.controllers')
  beforeEach inject(($controller, $rootScope) ->
    # Spy on the scopes.
    spyOn($rootScope, '$broadcast').and.callThrough()

    # Create a scope and spy on it.
    $scope = $rootScope.$new()
    spyOn($scope, '$on').and.callThrough()

    # Set the EntitiesController.
    EntitiesController = $controller 'EntitiesController', {$scope: $scope}
  )

  it "loads an analysis", inject((AnalysisService, $httpBackend, $rootScope) ->
    $.ajax('base/app/assets/english.json',
      async: false

    ).done (data) ->
      $httpBackend.expectPOST('/base/app/assets/english.json?action=wordlift_analyze')
      .respond 200, data

      $httpBackend.when('HEAD', /.*/).respond(200, '')

      AnalysisService.analyze ''

      $httpBackend.flush()

      # Check that the root scope broadcast method has been called.
      expect($rootScope.$broadcast).toHaveBeenCalledWith('analysisReceived', jasmine.any(Object))

      # Get a reference to the analysis structure.
      args = $rootScope.$broadcast.calls.argsFor 0
      analysis = args[1]

      expect(analysis).not.toBe undefined

      # Check that the analysis results conform.
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

      # Check that the scope has been called with analysisReceived.
      expect($scope.$on).toHaveBeenCalledWith('analysisReceived', jasmine.any(Function))

      # Check that the analysis saved in the scope equals the one sent by the AnalysisService.
      expect($scope.analysis).toEqual analysis

      # Check that the disambiguation popover is not visible.
      expect($('#wordlift-disambiguation-popover')).not.toBeVisible()

      for id, textAnnotation of analysis.textAnnotations

        # Send the textAnnotationClicked.
        $rootScope.$broadcast 'textAnnotationClicked', id, {target: $('body')[0]}

        # Check that the textAnnotationClicked event has been received.
        expect($scope.$on).toHaveBeenCalledWith('textAnnotationClicked', jasmine.any(Function))

        # Check that information inside the scope are updated accordingly.
        expect($scope.selectedEntity).toEqual undefined
        expect($scope.textAnnotation.id).toEqual id
        expect($scope.textAnnotation).toEqual textAnnotation
        expect(Object.keys($scope.textAnnotation.entityAnnotations).length).toBeGreaterThan 0

        # Check that the disambiguation popover is visible.
        expect($('#wordlift-disambiguation-popover')).toBeVisible()

  )
