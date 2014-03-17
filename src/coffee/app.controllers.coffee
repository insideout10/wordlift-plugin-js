angular.module('wordlift.tinymce.plugin.controllers',
  [ 'wordlift.tinymce.plugin.config', 'wordlift.tinymce.plugin.services' ])
.filter('orderObjectBy', ->
    (items, field, reverse) ->
      filtered = []

      angular.forEach items, (item) ->
        filtered.push(item)

      filtered.sort (a, b) ->
        a[field] > b[field]

      filtered.reverse() if reverse

      filtered
  )
.filter('filterObjectBy', ->
    (items, field, value) ->
      filtered = []

      angular.forEach items, (item) ->
        filtered.push(item) if item[field] is value

      filtered
  )
.controller('EntitiesController', ['EditorService', 'EntityService', '$log', '$scope', 'Configuration',
    (EditorService, EntityService, $log, $scope, Configuration) ->

      # holds a reference to the current analysis results.
      $scope.analysis = null

      # holds a reference to the selected text annotation.
      $scope.textAnnotation = null
      # holds a reference to the selected text annotation span.
      $scope.textAnnotationSpan = null

      $scope.sortByConfidence = (entity) ->
        entity[Configuration.entityLabels.confidence]

      $scope.getLabelFor = (label) ->
        Configuration.entityLabels[label]

      setArrowTop = (top) ->
        $('head').append('<style>#wordlift-disambiguation-popover .postbox:before,#wordlift-disambiguation-popover .postbox:after{top:' + top + 'px;}</style>');

      # a reference to the current text annotation span in the editor.
      el = undefined
      scroll = ->
        return if not el?
        # get the position of the clicked element.
        pos = EditorService.getWinPos(el)
        # set the popover arrow to the element position.
        setArrowTop(pos.top - 50)

      # TODO: move these hooks on the popover, in order to hook/unhook the events.
      $(window).scroll(scroll)
      $('#content_ifr').contents().scroll(scroll)

      $scope.onEntitySelected = (textAnnotation, entityAnnotation) ->
        $scope.$emit 'DisambiguationWidget.entitySelected', entityAnnotation

      # Receive the analysis results and store them in the local scope.
      $scope.$on 'analysisReceived', (event, analysis) ->
        $scope.analysis = analysis

      # When a text annotation is clicked, open the disambiguation popover.
      $scope.$on 'textAnnotationClicked', (event, id, sourceElement) ->

        # Get the text annotation with the provided id.
        $scope.textAnnotationSpan = angular.element sourceElement.target

        # Set the current text annotation to the one specified.
        $scope.textAnnotation = $scope.analysis.textAnnotations[id]

        # hide the popover if there are no entities.
        if 0 is $scope.textAnnotation?.entityAnnotations?.length
          $('#wordlift-disambiguation-popover').hide()
          # show the popover.
        else

          # get the position of the clicked element.
          pos = EditorService.getWinPos(sourceElement)
          # set the popover arrow to the element position.
          setArrowTop(pos.top - 50)

          # show the popover.
          $('#wordlift-disambiguation-popover').show()

  ])
.controller('ErrorController', ['$scope', '$log', ($scope, $log) ->

    $scope.$on 'error', (message) -> $log.info "ErrorController [ message :: #{message} ]"
  ])
