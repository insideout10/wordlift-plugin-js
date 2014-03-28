angular.module('wordlift.tinymce.plugin.services.EditorService', ['wordlift.tinymce.plugin.config', 'AnalysisService'])
.service('EditorService',
    ['AnalysisService', '$rootScope', '$log', (AnalysisService, $rootScope, $log) ->

      EDITOR_ID = 'content'
      TEXT_ANNOTATION = 'textannotation'
      CONTENT_IFRAME = '#content_ifr'
      RUNNING_CLASS = 'running'
      MCE_WORDLIFT = '.mce_wordlift'
      CONTENT_EDITABLE = 'contenteditable'

      editor = -> tinyMCE.get(EDITOR_ID)

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
          if AnalysisService.isRunning
            # If the service is running abort the current request.
            AnalysisService.abort()
          else
            # Disable the button and set the spinner while analysis is running.
            $(MCE_WORDLIFT).addClass RUNNING_CLASS

            # Make the editor read-obly.
            editor().getBody().setAttribute CONTENT_EDITABLE, false

            # Get entities already discovered.
            html = editor().getContent(format: 'raw')

            pattern = /\sitemid="([^"]+)"/gim
            while match = pattern.exec html
              # Do sth
              console.log match

            # Call the [AnalysisService](AnalysisService.html) to analyze the provided content, asking to merge sameAs related entities.
            AnalysisService.analyze content, true

      # get the window position of an element inside the editor.
      # @param element elem The element.
        getWinPos: (elem) ->
          # get a reference to the editor and its body
          ed = editor()
          el = elem.target

          top = $(CONTENT_IFRAME).offset().top - $('body').scrollTop() +
          el.offsetTop - $(ed.getBody()).scrollTop()

          left = $(CONTENT_IFRAME).offset().left - $('body').scrollLeft() +
          el.offsetLeft - $(ed.getBody()).scrollLeft()

          # Return the coordinates.
          {top: top, left: left}


      # Hook the service to the events. This event is captured when an entity is selected in the disambiguation popover.
      $rootScope.$on 'DisambiguationWidget.entitySelected', (event, obj) ->
        # create a reference to the TinyMCE editor dom.
        dom = editor().dom

        # the element id containing the attributes for the text annotation.
        id = obj.relation.id

        dom.setAttrib(id, 'class', "#{TEXT_ANNOTATION} highlight #{obj.entity.type}");
        dom.setAttrib(id, 'itemscope', 'itemscope');
        dom.setAttrib(id, 'itemtype', obj.entity.type);
        dom.setAttrib(id, 'itemid', obj.entity.id);

      # Receive annotations from the analysis (there is a mirror method in PHP for testing purposes, please try to keep
      # the two aligned - tests/functions.php *wl_embed_analysis* )
      # When an analysis is completed, remove the *running* class from the WordLift toolbar button.
      # (The button is set to running when [an analysis is called](#analyze).
      $rootScope.$on 'analysisReceived', (event, analysis) ->
        service.embedAnalysis analysis if analysis.textAnnotations?

        # Remove the *running* class.
        $(MCE_WORDLIFT).removeClass RUNNING_CLASS

        # Make the editor read/write.
        editor().getBody().setAttribute CONTENT_EDITABLE, true

      # Return the service definition.
      service
    ])
