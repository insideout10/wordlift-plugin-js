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
  		<div ng-click="createTextAnnotationFromCurrentSelection()">
        <span class="wl-new-entity-button" ng-class="{ 'selected' : !isSelectionCollapsed }">
          <i class="wl-annotation-label-icon"></i> add entity 
        </span>
      </div>
      <div ng-show="annotation">
        <h4 class="wl-annotation-label">
          <i class="wl-annotation-label-icon"></i>
          {{ analysis.annotations[ annotation ].text }} 
          <small>[ {{ analysis.annotations[ annotation ].start }}, {{ analysis.annotations[ annotation ].end }} ]</small>
          <i class="wl-annotation-label-remove-icon" ng-click="selectAnnotation(undefined)"></i>
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

    # Fires when the user changes node location using the mouse or keyboard in the TinyMCE editor.
    editor.onNodeChange.add (editor, e) ->        
      injector.invoke(['$rootScope', ($rootScope) ->
        # execute the following commands in the angular js context.      
        $rootScope.$apply(->
          $rootScope.$broadcast 'isSelectionCollapsed', editor.selection.isCollapsed()
        )
      ])
              
    # this event is raised when a textannotation is selected in the TinyMCE editor.
    editor.onClick.add (editor, e) ->
      injector.invoke(['EditorService','$rootScope', (EditorService, $rootScope) ->
        # execute the following commands in the angular js context.
        $rootScope.$apply(->          
          EditorService.selectAnnotation e.target.id 
        )
      ])
)
