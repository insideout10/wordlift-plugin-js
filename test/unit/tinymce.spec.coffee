describe "TinyMCE tests", ->
  # Global references
  ed = undefined

  # Tests set-up.
  beforeEach ->
    # Set a reference to the editor.
    ed = tinyMCE.get('content')

    #
    module 'wordlift.tinymce.plugin.services'

  afterEach inject ($httpBackend) ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()


  it "loads the editor and the WordLift plugin", ->

    # Check that the editor is loaded and that the WordLift plugin is loaded too.
    expect(ed).not.toBe undefined
    expect(ed.plugins.wordlift).not.toBe undefined


  it "loads the content", ->

    # Check that the editor content is empty.
    expect(ed.getContent().length).toEqual 0

    # Load the sample text in the editor.
    $.ajax('base/app/assets/english.txt',
      async: false

    ).done (data) ->
      # Set the editor content
      ed.setContent data
      # Check for the editor content not to be empty.
      expect(ed.getContent().length).toBeGreaterThan 0


  it "doesn't run an analysis when an analysis is already running", inject (AnalysisService, EditorService) ->

    # Spy on the analyze method of the AnalysisService
    spyOn AnalysisService, 'analyze'

    # By default the analysis is running is false
    expect(AnalysisService.isRunning).toEqual false

    # Set the analysis as running
    AnalysisService.isRunning = true

    # Check that the flag is true
    expect(AnalysisService.isRunning).toEqual true

    # Call the analyze method of the editor.
    EditorService.analyze ed.getContent { format: 'text' }

    # The analysis service shouldn't have been called
    expect(AnalysisService.analyze).not.toHaveBeenCalled()


  it "runs an analysis when an analysis is not running", inject (AnalysisService, EditorService, $httpBackend, $rootScope) ->

    # Spy on the analyze method of the AnalysisService
    spyOn(AnalysisService, 'analyze').and.callThrough()

    # Spy on the root scope.
    spyOn($rootScope, '$broadcast')

    # By default the analysis is running is false
    expect(AnalysisService.isRunning).toEqual false

    # Load the sample response.
    $.ajax('base/app/assets/english.json',
      async: false

    ).done (data) ->

      $httpBackend.expectPOST('/base/app/assets/english.json?action=wordlift_analyze')
        .respond 200, data

      $httpBackend.expect('HEAD', 'admin-ajax.php?action=wordlift_freebase_image&url=http%3A//rdf.freebase.com/ns/m.04js6kc')
        .respond 200, ''
      $httpBackend.expect('HEAD', 'admin-ajax.php?action=wordlift_freebase_image&url=http%3A//rdf.freebase.com/ns/m.04js6kq')
        .respond 200, ''
      $httpBackend.expect('HEAD', 'admin-ajax.php?action=wordlift_freebase_image&url=http%3A//rdf.freebase.com/ns/m.04mn0b4')
        .respond 200, ''
      $httpBackend.expect('HEAD', 'admin-ajax.php?action=wordlift_freebase_image&url=http%3A//rdf.freebase.com/ns/m.04mn0bt')
        .respond 200, ''
      $httpBackend.expect('HEAD', 'admin-ajax.php?action=wordlift_freebase_image&url=http%3A//rdf.freebase.com/ns/m.0djtw4k')
        .respond 200, ''
      $httpBackend.expect('HEAD', 'admin-ajax.php?action=wordlift_freebase_image&url=http%3A//rdf.freebase.com/ns/m.0p7qbkp')
        .respond 200, ''
      $httpBackend.expect('HEAD', 'admin-ajax.php?action=wordlift_freebase_image&url=http%3A//rdf.freebase.com/ns/m.0kybkyc')
        .respond 200, ''
      $httpBackend.expect('HEAD', 'admin-ajax.php?action=wordlift_freebase_image&url=http%3A//rdf.freebase.com/ns/m.0kybl3w')
        .respond 200, ''
      $httpBackend.expect('HEAD', 'admin-ajax.php?action=wordlift_freebase_image&url=http%3A//rdf.freebase.com/ns/m.0kyblb5')
        .respond 200, ''
      $httpBackend.expect('HEAD', 'admin-ajax.php?action=wordlift_freebase_image&url=http%3A//rdf.freebase.com/ns/m.0kyblkj')
        .respond 200, ''


      # Call the analyze method of the editor.
      EditorService.analyze ed.getContent { format: 'text' }

      # The analysis service shouldn't have been called
      expect(AnalysisService.analyze).toHaveBeenCalledWith(jasmine.any(String))

      $httpBackend.flush()

      expect($rootScope.$broadcast.calls.count()).toEqual 1

