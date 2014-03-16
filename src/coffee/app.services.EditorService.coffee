angular.module('wordlift.tinymce.plugin.services.EditorService', ['wordlift.tinymce.plugin.config', 'AnalysisService'])
.service('EditorService', ['AnalysisService', '$rootScope', '$log', 'Configuration', (AnalysisService, $rootScope, $log, Configuration) ->

    # Define the EditorService.
    service =
    # Embed the provided analysis in the editor.
      embedAnalysis: (analysis) ->
        # Clean up the selection prefix/suffix text.
        cleanUp = (text) ->
          text
          .replace('\\', '\\\\').replace( '\(', '\\(' ).replace( '\)', '\\)').replace('\n', '\\n?')
          .replace('-', '\\-').replace('\x20', '\\s').replace('\xa0', '&nbsp;')


        currentHtmlContent = tinyMCE.get('content').getContent({format : 'raw'})

        # Remove the existing text annotation spans.
        spanre = new RegExp("<span[^>]+class=\"textannotation\"[^>]*>([^<]*)</span>","gi")
        while spanre.test currentHtmlContent
          currentHtmlContent = currentHtmlContent.replace spanre, '$1'

        for id, textAnnotation of analysis.textAnnotations

          #console.log textAnnotation.id
          # get the selection prefix and suffix for the regexp.
          selPrefix = cleanUp(textAnnotation.selectionPrefix.substr(-1))
          selPrefix = '^|\\W' if '' is selPrefix
          selSuffix = cleanUp(textAnnotation.selectionSuffix.substr(0, 1))
          selSuffix = '$|\\W' if '' is selSuffix

          selText   = textAnnotation.selectedText

          # the new regular expression, may not match everything.
          # TODO: enhance the matching.
          r = new RegExp("(#{selPrefix}(?:<[^>]+>){0,})(#{selText})((?:<[^>]+>){0,}#{selSuffix})(?![^<]*\"[^<]*>)")
          r2 = new RegExp("id=\"(urn:enhancement.[a-z,0-9,-]+)\"")

          # If there are disambiguated entities
          # the span is not added while the existing span id is replaced
          if matchResult = currentHtmlContent.match r
            replace = "#{matchResult[1]}<span class=\"textannotation\" id=\"#{id}\" typeof=\"http://fise.iks-project.eu/ontology/TextAnnotation\">#{matchResult[2]}</span>#{matchResult[3]}"
            if r2.test matchResult[1]
              m = matchResult[1].replace r2,"id=\"#{id}\""
              replace = "#{m}#{matchResult[2]}#{matchResult[3]}"

            currentHtmlContent = currentHtmlContent.replace( r, replace )

        isDirty = tinyMCE.get('content').isDirty()
        tinyMCE.get('content').setContent currentHtmlContent
        tinyMCE.get('content').isNotDirty = 1 if not isDirty

        # this event is raised when a textannotation is selected in the TinyMCE editor.
        tinyMCE.get('content').onClick.add (editor, e) ->
          # execute the following commands in the angular js context.
          $rootScope.$apply(
            $log.debug "Going to notify click on annotation with id #{e.target.id}"
            # send a message about the currently clicked annotation.
            $rootScope.$broadcast 'textAnnotationClicked', e.target.id, e
          )

      ping: (message)    -> $log.debug message

    # <a name="analyze"></a>
    # Send the provided content for analysis using the [AnalysisService.analyze](app.services.AnalysisService.html#analyze) method.
      analyze: (content) ->
        return if AnalysisService.isRunning
        # Disable the button and set the spinner while analysis is running.
        $('.mce_wordlift').addClass 'running'
        # Make the editor read-obly.
        tinyMCE.get('content').getBody().setAttribute 'contenteditable', false
        # Call the [AnalysisService](AnalysisService.html) to analyze the provided content, asking to merge sameAs related entities.
        AnalysisService.analyze content, true

    # set some predefined variables.
      getEditor : -> tinyMCE.get('content')
      getBody   : -> @getEditor().getBody()
      getDOM    : -> @getEditor().dom

    # get the window position of an element inside the editor.
    # @param element elem The element.
      getWinPos: (elem) ->
        # get a reference to the editor and its body
        ed   = @getEditor()
        el   = elem.target

        top  = $('#content_ifr').offset().top - $('body').scrollTop() +
        el.offsetTop - $(ed.getBody()).scrollTop()

        left = $('#content_ifr').offset().left - $('body').scrollLeft() +
        el.offsetLeft - $(ed.getBody()).scrollLeft()

        # Return the coordinates.
        {top: top, left: left}


    # Hook the service to the events. This event is captured when an entity is selected in the disambiguation popover.
    $rootScope.$on 'DisambiguationWidget.entitySelected', (event, obj) ->
      cssClasses = "textannotation highlight #{obj.entity.type} disambiguated"

      # create a reference to the TinyMCE editor dom.
      dom  = tinyMCE.get("content").dom
      # the element id containing the attributes for the text annotation.
      id   = obj.relation.id
      elem = dom.get(id)

      dom.setAttrib(id, 'class', cssClasses);
      dom.setAttrib(id, 'itemscope', 'itemscope');
      dom.setAttrib(id, 'itemtype',  obj.entity.type);
      dom.setAttrib(id, 'itemid', obj.entity.id);

    # Receive annotations from the analysis (there is a mirror method in PHP for testing purposes, please try to keep
    # the two aligned - tests/functions.php *wl_embed_analysis* )
    # When an analysis is completed, remove the *running* class from the WordLift toolbar button.
    # (The button is set to running when [an analysis is called](#analyze).
    $rootScope.$on 'analysisReceived', (event, analysis) ->

      service.embedAnalysis analysis

      # Remove the *running* class.
      $('.mce_wordlift').removeClass 'running'
      # Make the editor read/write.
      tinyMCE.get('content').getBody().setAttribute 'contenteditable', true


    # Return the service definition.
    service
  ])
