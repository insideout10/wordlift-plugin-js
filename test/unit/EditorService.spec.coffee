describe "EditorService tests", ->
  beforeEach module('wordlift.tinymce.plugin.services')

  # Global references
  ed = undefined

  # Tests set-up.
  beforeEach inject(() ->
    ed = tinyMCE.get('content')
  )

  beforeEach inject(() ->
    ed.setContent('')
  )
  
  it "Create a TextAnnotation from the current editor selection", inject((EditorService, $httpBackend, $rootScope) ->
   # Check if editor content is blank
   expect(ed.getContent()).toBe ''
   # Set a fake content
   content = "Just a simple text about <em>New York</em> and <em>Los Angeles</em>"
   
   ed.setContent(content)
   # Set a fake selection (first <em> tag)
   expect(ed.selection.getContent()).toBe '' 
   ed.selection.select(ed.dom.select('em')[0]) 
   expect(ed.selection.getContent()).toBe '<em>New York</em>'  

   # Spy on the root scope.
   spyOn($rootScope, '$broadcast').and.callThrough()

   # Create a TextAnnotation from the current editor selection 
   EditorService.createTextAnnotationFromCurrentSelection()
   # Check if textAnnotationAdded event is properly fired
   expect($rootScope.$broadcast).toHaveBeenCalledWith 'textAnnotationAdded', jasmine.any(Object)
   # Retrieve the textAnnotation
   textAnnotation = $rootScope.$broadcast.calls.mostRecent().args[1]
   # Check if the TextAnnotation is configured properly
   expect(textAnnotation.start).toBe 25
   expect(textAnnotation.end).toBe 33
   expect(textAnnotation.text).toBe 'New York'
   # Check if the editor content is properly updated
   expect(ed.getContent()).toBe "<p>Just a simple text about <span id=\"#{textAnnotation.id}\" class=\"textannotation\"><em>#{textAnnotation.text}</em></span> and <em>Los Angeles</em></p>"
          
  )

  it "Create a TextAnnotation from when the current editor selection is blank", inject((EditorService, $httpBackend, $rootScope) ->
   # Check if editor content is blank
   expect(ed.getContent()).toBe ''
   # Set a fake selection (first <em> tag)
   expect(ed.selection.getContent()).toBe '' 
  
   # Spy on the root scope.
   spyOn($rootScope, '$broadcast').and.callThrough()

   # Create a TextAnnotation from the current editor selection 
   EditorService.createTextAnnotationFromCurrentSelection()
   # Verify that textAnnotationAdded event is NOT fired for a blank selection
   expect($rootScope.$broadcast).not.toHaveBeenCalledWith 'textAnnotationAdded', jasmine.any(Object)
          
  )