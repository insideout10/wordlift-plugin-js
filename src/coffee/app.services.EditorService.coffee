angular.module('wordlift.tinymce.plugin.services.EditorService', ['wordlift.tinymce.plugin.config', 'AnalysisService', 'LoggerService'])
.service('EditorService',
    ['AnalysisService', 'EntityAnnotationService', 'LoggerService', 'TextAnnotationService', '$rootScope', '$log', (AnalysisService, EntityAnnotationService, logger, TextAnnotationService, $rootScope, $log) ->

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
#          console.log "findEntities [ html index :: #{match.index} ][ text index :: #{traslator.html2text match.index} ]"
          {
            start: traslator.html2text match.index
            end: traslator.html2text (match.index + match[0].length)
            uri: match[2]
            label: match[3]
          }
        )
      # Service method used to calculate the start offset for the current selection
      # in createTextAnnotationFromCurrentSelection
      walkback = (node, stopAt) ->

        if node.childNodes and node.childNodes.length # go to last child
          node = node.childNodes[node.childNodes.length - 1]  while node and node.childNodes.length > 0
        else if node.previousSibling # else go to previous node
          node = node.previousSibling
        else if node.parentNode # else go to previous branch
          node = node.parentNode while node and not node.previousSibling and node.parentNode
          return if node is stopAt
          node = node.previousSibling
        else # nowhere to go
          return
        if node
          return node if node.nodeType is TEXT_HTML_NODE_TYPE
          return if node is stopAt
          return walkback(node, stopAt)
        return

      # Define the EditorService.
      service =
        # Create a textAnnotation starting from the current selection
        createTextAnnotationFromCurrentSelection: ()->
          # A reference to the editor.
          ed = editor()
          # Retrieve the current selection
          selection = ed.getWin().getSelection()
          # Retrieve the selected text
          text = selection.toString()
          # Retrieve the current selection text node 
          node = selection.anchorNode
          # Calculate the initial offset relative to 'node'
          start = if selection.anchorNode.nodeType is TEXT_HTML_NODE_TYPE then selection.anchorOffset else 0
          # Calculate the start position
          start = start + node.data.length while node = walkback(node, ed.getBody()) 
          # Calculate the end position
          end = start + text.length

          # Create the text annotation
          textAnnotation = TextAnnotationService.create { 
            start: start
            end: end
            text: text
          }
          if start is end
            $log.warn "Invalid selection! The text annotation cannot be created"
            $log.info textAnnotation
            return 
          
          ed.selection.setContent "<span id=\"#{textAnnotation.id}\" class=\"#{TEXT_ANNOTATION}\">#{ed.selection.getContent()}</span>"

          # Send a message about the new textAnnotation.
          $rootScope.$broadcast 'textAnnotationAdded', textAnnotation

        # Embed the provided analysis in the editor.
        embedAnalysis: (analysis) =>

          # A reference to the editor.
          ed = editor()

          # Get the TinyMCE editor html content.
          html = ed.getContent format: 'raw'

          # Find existing entities.
          entities = findEntities html

          # Preselect entities found in html.
          AnalysisService.preselect analysis, entities

          # Remove existing text annotations (the while-match is necessary to remove nested spans).
          while html.match(/<(\w+)[^>]*\sclass="textannotation[^"]*"[^>]*>([^<]+)<\/\1>/gim, '$2')
            html = html.replace(/<(\w+)[^>]*\sclass="textannotation[^"]*"[^>]*>([^<]+)<\/\1>/gim, '$2')

          # Prepare a traslator instance that will traslate Html and Text positions.
          traslator = Traslator.create html

          # Add text annotations to the html (skip those text annotations that don't have entity annotations).
          for textAnnotationId, textAnnotation of analysis.textAnnotations when 0 < Object.keys(textAnnotation.entityAnnotations).length

            # Start the element.
            element = "<span id=\"#{textAnnotationId}\" class=\"#{TEXT_ANNOTATION}"

            # Insert the Html fragments before and after the selected text.
            entityAnnotations = EntityAnnotationService.find textAnnotation.entityAnnotations, selected: true
            if 0 < entityAnnotations.length and entityAnnotations[0].entity?
              # We deal only with the first entityAnnotation.
#              console.log entityAnnotations[0] if not entityAnnotations[0].entity
              entity = entityAnnotations[0].entity
              element += " highlight #{entity.css}\" itemid=\"#{entity.id}"

            # Close the element.
            element += '">'

            # Finally insert the HTML code.
#            console.log textAnnotation
            traslator.insertHtml element, text: textAnnotation.start
            traslator.insertHtml '</span>', text: textAnnotation.end


#          $log.info "embedAnalysis\n[ pre html :: #{html} ]\n[ post html :: #{traslator.getHtml()} ]\n[ text :: #{traslator.getText()} ]"

          # Update the editor Html code.
          isDirty = ed.isDirty()
          ed.setContent traslator.getHtml(), format: 'raw'
          ed.isNotDirty = not isDirty

      # <a name="analyze"></a>
      # Send the provided content for analysis using the [AnalysisService.analyze](app.services.AnalysisService.html#analyze) method.
        analyze: (content) ->
          # $log.info "EditorService.analyze [ content :: #{content} ]"
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
          cls +=  " highlight #{entity.css}"
          itemscope = 'itemscope'
          itemid = entity.id

          # Add the selected entity to the Analysis Service stored entities.
          AnalysisService.addEntity entity

        else
            itemscope = null
            itemid = null

        # Apply changes to the dom.
        dom.setAttrib id, 'class', cls
        dom.setAttrib id, 'itemscope', itemscope
        dom.setAttrib id, 'itemid', itemid

      # Receive annotations from the analysis (there is a mirror method in PHP for testing purposes, please try to keep
      # the two aligned - tests/functions.php *wl_embed_analysis* )
      # When an analysis is completed, remove the *running* class from the WordLift toolbar button.
      # (The button is set to running when [an analysis is called](#analyze).
      $rootScope.$on ANALYSIS_EVENT, (event, analysis) ->

        logger.debug "EditorService : Analysis Event", analysis: analysis

        service.embedAnalysis analysis if analysis? and analysis.textAnnotations?

        # Remove the *running* class.
        $(MCE_WORDLIFT).removeClass RUNNING_CLASS

        # Make the editor read/write.
        editor().getBody().setAttribute CONTENT_EDITABLE, true

      # Return the service definition.
      service
    ])
