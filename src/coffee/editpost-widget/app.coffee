# Set the well-known $ reference to jQuery.
$ = jQuery

# Create the main AngularJS module, and set it dependent on controllers and directives.
angular.module('wordlift.editpost.widget', [

	'wordlift.editpost.widget.providers.ConfigurationProvider', 
	'wordlift.editpost.widget.controllers.EditPostWidgetController', 
	'wordlift.editpost.widget.directives.wlClassificationBox', 
	'wordlift.editpost.widget.directives.wlEntityForm', 
	'wordlift.editpost.widget.directives.wlEntityTile', 
	'wordlift.editpost.widget.services.AnalysisService', 
	'wordlift.editpost.widget.services.EditorService', 
	'wordlift.editpost.widget.services.ImageSuggestorDataRetrieverService' 		
	
	])

.config((configurationProvider)->
  configurationProvider.setBoxes window.wordlift.classificationBoxes
)

$(
  container = $("""
  	<div id="wordlift-edit-post-wrapper" ng-controller="EditPostWidgetController">
  		<div ng-show="annotation">
        <h4 class="wl-annotation-label">
          <i class="wl-annotation-label-icon"></i>
          {{ analysis.annotations[ annotation ].text }} 
          <small>[ {{ analysis.annotations[ annotation ].start }}, {{ analysis.annotations[ annotation ].end }} ]</small>
          <i class="wl-annotation-label-remove-icon" ng-click="annotation = undefined"></i>
        </h4>
        <wl-entity-form entity="newEntity" on-submit="addNewEntityToAnalysis()"ng-show="analysis.annotations[annotation].entityMatches.length == 0"></wl-entity-form>
      </div>
      <wl-classification-box ng-repeat="box in configuration.boxes">
        <wl-entity-tile entity="entity" ng-repeat="entity in analysis.entities | entityTypeIn:box.registeredTypes"></wl-entity>
      </wl-classification-box>
    </div>
  """)
  .appendTo('#dx')

injector = angular.bootstrap $('#wordlift-edit-post-wrapper'), ['wordlift.editpost.widget']

# Add WordLift as a plugin of the TinyMCE editor.
  tinymce.PluginManager.add 'wordlift', (editor, url) ->
    # Perform analysis once tinymce is loaded
    editor.onLoadContent.add((ed, o) ->
      injector.invoke(['AnalysisService', '$rootScope',
       (AnalysisService, $rootScope) ->
        # execute the following commands in the angular js context.
        $rootScope.$apply(->    
          AnalysisService.perform()
        )
      ])
    )
    # Add a WordLift button the TinyMCE editor.
    # TODO Disable the new button as default
    editor.addButton 'wordlift',
      classes: 'widget btn wordlift_add_entity'
      text: ' ' # the space is necessary to avoid right spacing on TinyMCE 4
      tooltip: 'Insert entity'
      onclick: ->
        injector.invoke(['EditorService', '$rootScope', (EditorService, $rootScope) ->
          # execute the following commands in the angular js context.
          $rootScope.$apply(->
            EditorService.createTextAnnotationFromCurrentSelection()
          )
        ])

    # TODO: move this outside of this method.
    # this event is raised when a textannotation is selected in the TinyMCE editor.
    editor.onClick.add (editor, e) ->
      injector.invoke(['$rootScope', ($rootScope) ->
        # execute the following commands in the angular js context.
        $rootScope.$apply(->
          # TODO move EditorService
          for annotation in editor.dom.select "span.textannotation"
            if annotation.id is e.target.id
              if editor.dom.hasClass annotation.id, "selected"
                editor.dom.removeClass annotation.id, "selected"
                # send a message to clear current text annotation scope
                $rootScope.$broadcast 'textAnnotationClicked', undefined
              else
                editor.dom.addClass annotation.id, "selected"
                # send a message about the currently clicked annotation.
                $rootScope.$broadcast 'textAnnotationClicked', e.target.id
            else 
             editor.dom.removeClass annotation.id, "selected"          
        )
      ])
)
