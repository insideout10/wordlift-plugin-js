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

    # Spy on the editor embedAnalysis method of the EditorService
    spyOn(EditorService, 'embedAnalysis').and.callThrough()

    # Spy on the root scope.
    spyOn($rootScope, '$broadcast').and.callThrough()

    # By default the analysis is running is false
    expect(AnalysisService.isRunning).toEqual false

    # Load the sample response.
    $.ajax('base/app/assets/english.json',
      async: false

    ).done (data) ->

      $httpBackend.expectPOST('/base/app/assets/english.json?action=wordlift_analyze')
        .respond 200, data
#      $httpBackend.expect('HEAD', 'http://upload.wikimedia.org/wikipedia/commons/a/a6/Flag_of_Rome.svg')
#        .respond 200, ''
#      $httpBackend.expect('HEAD', 'http://upload.wikimedia.org/wikipedia/commons/a/a3/Rome_Georgia_from_Myrtle_Hill_Cemetery.jpg')
#        .respond 200, ''
#      $httpBackend.expect('HEAD', 'http://upload.wikimedia.org/wikipedia/commons/6/6a/OneidaCoCourthouse-Beale.jpg')
#        .respond 200, ''
#      $httpBackend.expect('HEAD', 'http://upload.wikimedia.org/wikipedia/commons/a/a4/Sw-horz-w3c.png')
#        .respond 200, ''
#      $httpBackend.expect('HEAD', 'http://upload.wikimedia.org/wikipedia/commons/2/20/WordPress_logo.svg')
#        .respond 200, ''
#      $httpBackend.expect('HEAD', 'https://usercontent.googleapis.com/freebase/v1/image/m/05thd8b?maxwidth=4096&maxheight=4096')
#        .respond 200, ''
#      $httpBackend.expect('HEAD', 'https://usercontent.googleapis.com/freebase/v1/image/m/04js6kc?maxwidth=4096&maxheight=4096')
#        .respond 200, ''
#      $httpBackend.expect('HEAD', 'https://usercontent.googleapis.com/freebase/v1/image/m/04js6kq?maxwidth=4096&maxheight=4096')
#        .respond 200, ''
#      $httpBackend.expect('HEAD', 'https://usercontent.googleapis.com/freebase/v1/image/m/04mn0b4?maxwidth=4096&maxheight=4096')
#        .respond 200, ''
#      $httpBackend.expect('HEAD', 'https://usercontent.googleapis.com/freebase/v1/image/m/04mn0bt?maxwidth=4096&maxheight=4096')
#        .respond 200, ''
#      $httpBackend.expect('HEAD', 'https://usercontent.googleapis.com/freebase/v1/image/m/0djtw4k?maxwidth=4096&maxheight=4096')
#        .respond 200, ''
#      $httpBackend.expect('HEAD', 'https://usercontent.googleapis.com/freebase/v1/image/m/0p7qbkp?maxwidth=4096&maxheight=4096')
#        .respond 200, ''
#      $httpBackend.expect('HEAD', 'https://usercontent.googleapis.com/freebase/v1/image/m/0kybkyc?maxwidth=4096&maxheight=4096')
#        .respond 200, ''
#      $httpBackend.expect('HEAD', 'https://usercontent.googleapis.com/freebase/v1/image/m/0kybl3w?maxwidth=4096&maxheight=4096')
#        .respond 200, ''
#      $httpBackend.expect('HEAD', 'https://usercontent.googleapis.com/freebase/v1/image/m/0kyblb5?maxwidth=4096&maxheight=4096')
#        .respond 200, ''
#      $httpBackend.expect('HEAD', 'https://usercontent.googleapis.com/freebase/v1/image/m/0kyblkj?maxwidth=4096&maxheight=4096')
#        .respond 200, ''

      # Call the analyze method of the editor.
      EditorService.analyze ed.getContent { format: 'text' }

      # The analysis service shouldn't have been called with the merge parameter set to true.
      expect(AnalysisService.analyze).toHaveBeenCalledWith(jasmine.any(String), true)

      $httpBackend.flush()

      expect($rootScope.$broadcast.calls.count()).toEqual 1

      # The analysis service shouldn't have been called
      expect(EditorService.embedAnalysis).toHaveBeenCalledWith(jasmine.any(Object))


    it "sends the analysis results", inject (AnalysisService, EditorService, $httpBackend, $rootScope) ->

      # Get a reference to the argument passed with the event.
      args     = $rootScope.$broadcast.calls.argsFor 0

      # Get a reference to the analysis structure.
      analysis = args[1]

      # Check that the analysis results conform.
      expect(analysis).toEqual jasmine.any(Object)
      expect(analysis.language).not.toBe undefined
      expect(analysis.entities).not.toBe undefined
      expect(analysis.entityAnnotations).not.toBe undefined
      expect(analysis.textAnnotations).not.toBe undefined
      expect(analysis.languages).not.toBe undefined
      expect(analysis.language).toEqual 'en'
      expect(Object.keys(analysis.entities).length).toEqual 20
      expect(Object.keys(analysis.entityAnnotations).length).toEqual 21
      expect(Object.keys(analysis.textAnnotations).length).toEqual 10
      expect(Object.keys(analysis.languages).length).toEqual 1

    # Check that the text annotations have been embedded in the content.
    it "embeds the analysis results in the editor contents", inject (EditorService, $rootScope) ->

      # Get the editor raw content
      content = ed.getContent { format : 'raw' }

      expect(content.length).toBeGreaterThan 0

      # Get a reference to the argument passed with the event.
      args     = $rootScope.$broadcast.calls.argsFor 0
      # Get a reference to the analysis structure.
      analysis = args[1]
      # Get the text annotations.
      textAnnotations = analysis.textAnnotations

      # Look for SPANs in the content.
      regex = new RegExp(/<span id="([^"]+)" class="textannotation">([^<]+)<\/span>/g)
      while match = regex.exec content
        # Check that every span matches a text annotation.
        id   = match[1]
        text = match[2]
        expect(textAnnotations[id]).not.toBe null
        expect(textAnnotations[id].selectedText).toEqual text


