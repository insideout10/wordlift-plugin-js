angular.module('wordlift.tinymce.plugin.services.EditorService', ['wordlift.tinymce.plugin.config', 'AnalysisService'])
.service('EditorService',
    ['AnalysisService', '$rootScope', '$log', (AnalysisService, $rootScope, $log) ->

      # Define the EditorService.
      service =
      # Embed the provided analysis in the editor.
        embedAnalysis: (analysis) ->

          findTextAnnotation = (textAnnotations, start, end) ->
            return textAnnotation for id, textAnnotation of analysis.textAnnotations when textAnnotation.start is start and textAnnotation.end is end
            null

          findEntityAnnotation = (entityAnnotations, uri) ->
            return entityAnnotation for id, entityAnnotation of entityAnnotations when uri is entityAnnotation.entity.id or uri in entityAnnotation.entity.sameAs
            null


          # Get the TinyMCE editor html content.
          html = tinyMCE.get('content').getContent({format: 'raw'})

          # Find existing entities.
          entities = @findEntities html

          # Remove existing text annotations.
          html = html.replace(/<(\w+)[^>]*\sclass="textannotation[^"]*"[^>]*>([^<]+)<\/\1>/gim, '$2')

          # Prepare a traslator instance that will traslate Html and Text positions.
          traslator = Traslator.create html

          # Find the existing entities in the html
          for match in entities

            textAnnotation = findTextAnnotation analysis.textAnnotations, match.text.start, match.text.end
            if textAnnotation
              entityAnnotation = findEntityAnnotation textAnnotation.entityAnnotations, match.uri
              entityAnnotation.selected = true if entityAnnotation?
              console.log "match [ id :: #{textAnnotation.id} ][ start :: #{textAnnotation.start} ][ end :: #{textAnnotation.end} ][ label :: #{match.label} ]"
            else
              console.log "no match [ start :: #{match.text.start} ][ end :: #{match.text.end} ][ label :: #{match.label} ]"

          for id, textAnnotation of analysis.textAnnotations
            start = textAnnotation.start
            end = textAnnotation.end
            text = textAnnotation.selectedText
            console.log "textAnnotation [ start :: #{start} ][ end :: #{end} ][ text :: #{text} ]"

          # TODO: this should be done before running the analysis. Remove the existing text annotation spans.
          #          spanre = new RegExp("<span[^>]+class=\"textannotation\"[^>]*>([^<]*)</span>", "gi")
          #          while spanre.test content
          #            content = content.replace spanre, '$1'

          for textAnnotationId, textAnnotation of analysis.textAnnotations

            # Don't add the text annotation if there are no entity annotations.
            continue if 0 is Object.keys(textAnnotation.entityAnnotations).length

            #            console.log "[ start :: #{textAnnotation.start} ][ end :: #{textAnnotation.end} ][ text :: #{textAnnotation.selectedText} ]"

            # Insert the Html fragments before and after the selected text.
            itemid = ''
            itemid = " itemid=\"#{entityAnnotation.entity.id}\"" for id, entityAnnotation of textAnnotation.entityAnnotations when entityAnnotation.selected
            traslator.insertHtml "<span class=\"textannotation\" id=\"#{textAnnotationId}\"#{itemid}>", {text: textAnnotation.start}
            traslator.insertHtml '</span>', {text: textAnnotation.end}

          #console.log textAnnotation.id
          # get the selection prefix and suffix for the regexp.
          #            selPrefix = cleanUp(textAnnotation.selectionPrefix.substr(-1))
          #            selPrefix = '^|\\W' if '' is selPrefix
          #            selSuffix = cleanUp(textAnnotation.selectionSuffix.substr(0, 1))
          #            selSuffix = '$|\\W' if '' is selSuffix
          #
          #            selText = textAnnotation.selectedText.replace('(', '\\(').replace(')', '\\)')
          #
          #            # the new regular expression, may not match everything.
          #            # TODO: enhance the matching.
          #            r = new RegExp("(#{selPrefix}(?:<[^>]+>){0,})(#{selText})((?:<[^>]+>){0,}#{selSuffix})(?![^<]*\"[^<]*>)")
          #            r2 = new RegExp("id=\"(urn:enhancement.[a-z,0-9,-]+)\"")
          #
          # If there are disambiguated entities
          # the span is not added while the existing span id is replaced
          #            if matchResult = content.match r
          #              # Skip typeof attribute
          #              replace = "#{matchResult[1]}<span class=\"textannotation\" id=\"#{id}\" >#{matchResult[2]}</span>#{matchResult[3]}"
          #              if r2.test matchResult[1]
          #                m = matchResult[1].replace r2, "id=\"#{id}\""
          #                replace = "#{m}#{matchResult[2]}#{matchResult[3]}"
          #
          #              content = content.replace(r, replace)

          # Loops over disambiguated textAnnotations
          # and notifies selected EntityAnnotations to EntitiesController
          #          disambiguatedTextAnnotations = tinyMCE.get('content').dom.select('span.disambiguated')
          #          for textAnnotation in disambiguatedTextAnnotations
          #            $rootScope.$broadcast 'disambiguatedTextAnnotationDetected', textAnnotation.id, textAnnotation.getAttribute('itemid')

          #          console.log "===== getHtml ====="
          #          console.log t.getHtml()
          #          console.log "===== /getHtml ====="

          isDirty = tinyMCE.get('content').isDirty()
          tinyMCE.get('content').setContent traslator.getHtml()
          tinyMCE.get('content').isNotDirty = 1 if not isDirty

        findEntities: (html) ->

          # Get a traslator instance.
          traslator = Traslator.create(html)

          # Set the pattern to look for *itemid* attributes.
          pattern = /<(\w+)[^>]*\sitemid="([^"]+)"[^>]*>([^<]+)<\/\1>/gim

          # Get the matches and return them.
          (while match = pattern.exec html
            # Do sth
            start = match.index
            end = start + match[0].length
            uri = match[2]
            label = match[3]

            {
            html:
              start: start
              end: end
            text:
              start: traslator.html2text start
              end: traslator.html2text end
            uri: uri
            label: label
            }
          )


      # <a name="analyze"></a>
      # Send the provided content for analysis using the [AnalysisService.analyze](app.services.AnalysisService.html#analyze) method.
        analyze: (content) ->
          if AnalysisService.isRunning
            # If the service is running abort the current request.
            AnalysisService.abort()
          else
            # Disable the button and set the spinner while analysis is running.
            $('.mce_wordlift').addClass 'running'

            # Make the editor read-obly.
            tinyMCE.get('content').getBody().setAttribute 'contenteditable', false

            # Get entities already discovered.
            html = tinyMCE.get('content').getContent({format: 'raw'})

            pattern = /\sitemid="([^"]+)"/gim
            while match = pattern.exec html
              # Do sth
              console.log match

            # Call the [AnalysisService](AnalysisService.html) to analyze the provided content, asking to merge sameAs related entities.
            AnalysisService.analyze content, true

      # set some predefined variables.
        getEditor: ->
          tinyMCE.get('content')
        getBody: ->
          @getEditor().getBody()
        getDOM: ->
          @getEditor().dom

      # get the window position of an element inside the editor.
      # @param element elem The element.
        getWinPos: (elem) ->
          # get a reference to the editor and its body
          ed = @getEditor()
          el = elem.target

          top = $('#content_ifr').offset().top - $('body').scrollTop() +
          el.offsetTop - $(ed.getBody()).scrollTop()

          left = $('#content_ifr').offset().left - $('body').scrollLeft() +
          el.offsetLeft - $(ed.getBody()).scrollLeft()

          # Return the coordinates.
          {top: top, left: left}


      # Hook the service to the events. This event is captured when an entity is selected in the disambiguation popover.
      $rootScope.$on 'DisambiguationWidget.entitySelected', (event, obj) ->
        cssClasses = "textannotation highlight #{obj.entity.type} disambiguated"

        # create a reference to the TinyMCE editor dom.
        dom = tinyMCE.get("content").dom
        # the element id containing the attributes for the text annotation.
        id = obj.relation.id
        elem = dom.get(id)

        dom.setAttrib(id, 'class', cssClasses);
        dom.setAttrib(id, 'itemscope', 'itemscope');
        dom.setAttrib(id, 'itemtype', obj.entity.type);
        dom.setAttrib(id, 'itemid', obj.entity.id);

      # Receive annotations from the analysis (there is a mirror method in PHP for testing purposes, please try to keep
      # the two aligned - tests/functions.php *wl_embed_analysis* )
      # When an analysis is completed, remove the *running* class from the WordLift toolbar button.
      # (The button is set to running when [an analysis is called](#analyze).
      $rootScope.$on 'analysisReceived', (event, analysis) ->
        service.embedAnalysis analysis if analysis?

        # Remove the *running* class.
        $('.mce_wordlift').removeClass 'running'
        # Make the editor read/write.
        tinyMCE.get('content').getBody().setAttribute 'contenteditable', true

      # Return the service definition.
      service
    ])
