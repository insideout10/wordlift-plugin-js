angular.module('wordlift.tinymce.plugin.services.EditorService', ['wordlift.tinymce.plugin.config', 'AnalysisService'])
.service('EditorService',
    ['AnalysisService', '$rootScope', '$log', (AnalysisService, $rootScope, $log) ->

      # Define the EditorService.
      service =
      # Embed the provided analysis in the editor.
        embedAnalysis: (analysis) ->

          # Get the TinyMCE editor html content.
          html = tinyMCE.get('content').getContent(format: 'raw')

          # Find existing entities.
          entities = @findEntities html

          # Preselect entities found in html.
          AnalysisService.preselect analysis, entities

          # Remove existing text annotations.
          html = html.replace(/<(\w+)[^>]*\sclass="textannotation[^"]*"[^>]*>([^<]+)<\/\1>/gim, '$2')

          # Prepare a traslator instance that will traslate Html and Text positions.
          traslator = Traslator.create html

          # Add text annotations to the html (skip those text annotations that don't have entity annotations).
          for textAnnotationId, textAnnotation of analysis.textAnnotations when 0 < Object.keys(textAnnotation.entityAnnotations).length

            # Insert the Html fragments before and after the selected text.
            entityAnnotation = AnalysisService.findEntityAnnotation textAnnotation.entityAnnotations, {selected: true}
            if entityAnnotation?
              entity = entityAnnotation.entity
              element = "<span class=\"textannotation highlight #{entity.type}\" id=\"#{textAnnotationId}\" itemid=\"#{entity.id}\">"
            else
              element = "<span class=\"textannotation\" id=\"#{textAnnotationId}\">"

            # Finally insert the HTML code.
            traslator.insertHtml element, {text: textAnnotation.start}
            traslator.insertHtml '</span>', {text: textAnnotation.end}


          # Update the editor Html code.
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
