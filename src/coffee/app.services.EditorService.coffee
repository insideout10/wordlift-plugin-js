angular.module('wordlift.tinymce.plugin.services.EditorService', ['wordlift.tinymce.plugin.config', 'AnalysisService'])
.service('EditorService',
    ['AnalysisService', '$rootScope', (AnalysisService, $rootScope) ->

      # Define some constants for commonly used strings.
      EDITOR_ID = 'content'
      TEXT_ANNOTATION = 'textannotation'
      CONTENT_IFRAME = '#content_ifr'
      RUNNING_CLASS = 'running'
      MCE_WORDLIFT = '.mce_wordlift'
      CONTENT_EDITABLE = 'contenteditable'

      editor = ->
        tinyMCE.get(EDITOR_ID)

      # Find existing entities selected in the html content (by looking for *itemid* attributes).
      findEntities = (html) ->

        # Prepare a traslator instance that will traslate Html and Text positions.
        traslator = Traslator.create html

        # Set the pattern to look for *itemid* attributes.
        pattern = /<(\w+)[^>]*\sitemid="([^"]+)"[^>]*>([^<]+)<\/\1>/gim

        # Get the matches and return them.
        (while match = pattern.exec html
          {
            start: traslator.html2text match.index
            end: traslator.html2text (match.index + match[0].length)
            uri: match[2]
            label: match[3]
          }
        )

      # Define the EditorService.
      service =
      # Embed the provided analysis in the editor.
        embedAnalysis: (analysis) ->

          # A reference to the editor.
          ed = editor()

          # Get the TinyMCE editor html content.
          html = ed.getContent(format: 'raw')

          # Find existing entities.
          entities = findEntities html

          # Preselect entities found in html.
          AnalysisService.preselect analysis, entities

          # Remove existing text annotations.
          html = html.replace(/<(\w+)[^>]*\sclass="textannotation[^"]*"[^>]*>([^<]+)<\/\1>/gim, '$2')

          # Prepare a traslator instance that will traslate Html and Text positions.
          traslator = Traslator.create html

          # Add text annotations to the html (skip those text annotations that don't have entity annotations).
          for textAnnotationId, textAnnotation of analysis.textAnnotations when 0 < Object.keys(textAnnotation.entityAnnotations).length

            # Start the element.
            element = "<span id=\"#{textAnnotationId}\" class=\"#{TEXT_ANNOTATION}"

            # Insert the Html fragments before and after the selected text.
            entityAnnotation = AnalysisService.findEntityAnnotation textAnnotation.entityAnnotations, selected: true
            if entityAnnotation?
              entity = entityAnnotation.entity
              element += " highlight #{entity.type}\" itemid=\"#{entity.id}"

            # Close the element.
            element += '">'

            # Finally insert the HTML code.
            traslator.insertHtml element, {text: textAnnotation.start}
            traslator.insertHtml '</span>', {text: textAnnotation.end}


          # Update the editor Html code.
          isDirty = ed.isDirty()
          ed.setContent traslator.getHtml()
          ed.isNotDirty = not isDirty

      # <a name="analyze"></a>
      # Send the provided content for analysis using the [AnalysisService.analyze](app.services.AnalysisService.html#analyze) method.
        analyze: (content) ->
          # If the service is running abort the current request.
          return AnalysisService.abort() if AnalysisService.isRunning

          # Disable the button and set the spinner while analysis is running.
          $(MCE_WORDLIFT).addClass RUNNING_CLASS

          # Make the editor read-obly.
          editor().getBody().setAttribute CONTENT_EDITABLE, false

          # Call the [AnalysisService](AnalysisService.html) to analyze the provided content, asking to merge sameAs related entities.
          AnalysisService.analyze content, true

      # get the window position of an element inside the editor.
      # @param element elem The element.
        getWinPos: (elem) ->
          # get a reference to the editor and its body
          ed = editor()
          el = elem.target

          # Return the coordinates.
          {
            top: $(CONTENT_IFRAME).offset().top - $('body').scrollTop() + el.offsetTop - $(ed.getBody()).scrollTop()
            left: $(CONTENT_IFRAME).offset().left - $('body').scrollLeft() + el.offsetLeft - $(ed.getBody()).scrollLeft()
          }


      # Hook the service to the events. This event is captured when an entity is selected in the disambiguation popover.
      $rootScope.$on 'selectEntity', (event, args) ->

        # create a reference to the TinyMCE editor dom.
        dom = editor().dom

        # the element id containing the attributes for the text annotation.
        id = args.ta.id

        # Preset the stylesheet class.
        cls = TEXT_ANNOTATION

        # If an entity annotation is selected then prepare the values, otherwise set them null (i.e. remove).
        if args.ea?
          # Set a reference to the entity.
          entity = args.ea.entity
          cls +=  " highlight #{entity.type}"
          itemscope = 'itemscope'
          itemtype = entity.type
          itemid = entity.id
        else
          itemscope = null
          itemtype = null
          itemid = null

        # Apply changes to the dom.
        dom.setAttrib id, 'class', cls
        dom.setAttrib id, 'itemscope', itemscope
        dom.setAttrib id, 'itemtype', itemtype
        dom.setAttrib id, 'itemid', itemid

      # Receive annotations from the analysis (there is a mirror method in PHP for testing purposes, please try to keep
      # the two aligned - tests/functions.php *wl_embed_analysis* )
      # When an analysis is completed, remove the *running* class from the WordLift toolbar button.
      # (The button is set to running when [an analysis is called](#analyze).
      $rootScope.$on 'analysisReceived', (event, analysis) ->
        service.embedAnalysis analysis if analysis? and analysis.textAnnotations?

        # Remove the *running* class.
        $(MCE_WORDLIFT).removeClass RUNNING_CLASS

        # Make the editor read/write.
        editor().getBody().setAttribute CONTENT_EDITABLE, true

      # Return the service definition.
      service
    ])
