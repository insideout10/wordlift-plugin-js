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

      $httpBackend.expect('HEAD',
        'admin-ajax.php?action=wordlift_freebase_image&url=http%3A//rdf.freebase.com/ns/m.04js6kc')
      .respond 200, ''
      $httpBackend.expect('HEAD',
        'admin-ajax.php?action=wordlift_freebase_image&url=http%3A//rdf.freebase.com/ns/m.04js6kq')
      .respond 200, ''
      $httpBackend.expect('HEAD',
        'admin-ajax.php?action=wordlift_freebase_image&url=http%3A//rdf.freebase.com/ns/m.04mn0b4')
      .respond 200, ''
      $httpBackend.expect('HEAD',
        'admin-ajax.php?action=wordlift_freebase_image&url=http%3A//rdf.freebase.com/ns/m.04mn0bt')
      .respond 200, ''
      $httpBackend.expect('HEAD',
        'admin-ajax.php?action=wordlift_freebase_image&url=http%3A//rdf.freebase.com/ns/m.0djtw4k')
      .respond 200, ''
      $httpBackend.expect('HEAD',
        'admin-ajax.php?action=wordlift_freebase_image&url=http%3A//rdf.freebase.com/ns/m.0p7qbkp')
      .respond 200, ''
      $httpBackend.expect('HEAD',
        'admin-ajax.php?action=wordlift_freebase_image&url=http%3A//rdf.freebase.com/ns/m.0kybkyc')
      .respond 200, ''
      $httpBackend.expect('HEAD',
        'admin-ajax.php?action=wordlift_freebase_image&url=http%3A//rdf.freebase.com/ns/m.0kybl3w')
      .respond 200, ''
      $httpBackend.expect('HEAD',
        'admin-ajax.php?action=wordlift_freebase_image&url=http%3A//rdf.freebase.com/ns/m.0kyblb5')
      .respond 200, ''
      $httpBackend.expect('HEAD',
        'admin-ajax.php?action=wordlift_freebase_image&url=http%3A//rdf.freebase.com/ns/m.0kyblkj')
      .respond 200, ''

      AnalysisService.analyze ''

      $httpBackend.flush()

      # Check that the root scope broadcast method has been called.
      expect($rootScope.$broadcast).toHaveBeenCalledWith('analysisReceived', jasmine.any(Object))

      # Get a reference to the analysis structure.
      args = $rootScope.$broadcast.calls.argsFor 0
      analysis = args[1]

      expect(analysis).not.toBe undefined

      # Check that the scope has been called with analysisReceived.
      expect($scope.$on).toHaveBeenCalledWith('analysisReceived', jasmine.any(Function))

      # Check that the analysis saved in the scope equals the one sent by the AnalysisService.
      expect($scope.analysis).toEqual analysis

      # Send the textAnnotationClicked.
      $rootScope.$broadcast 'textAnnotationClicked', '123', {target: $('body')[0]}

      # Check that the textAnnotationClicked event has been received.
      expect($scope.$on).toHaveBeenCalledWith('textAnnotationClicked', jasmine.any(Function))

  )

#
#    expect(EntitiesController).not.toBe undefined
#    expect(EntitiesController.scope).not.toBe undefined
#    $scope.$on 'textAnnotationClicked', (event, id, sourceElement) ->