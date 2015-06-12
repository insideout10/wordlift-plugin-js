# Set the well-known $ reference to jQuery.
$ = jQuery

# Create the main AngularJS module, and set it dependent on controllers and directives.
angular.module('wordlift.editpost.widget', [

	'wordlift.ui.carousel'
  'wordlift.editpost.widget.providers.ConfigurationProvider', 
	'wordlift.editpost.widget.controllers.EditPostWidgetController', 
	'wordlift.editpost.widget.directives.wlClassificationBox', 
	'wordlift.editpost.widget.directives.wlEntityForm', 
	'wordlift.editpost.widget.directives.wlEntityTile',
  'wordlift.editpost.widget.directives.wlEntityInputBox', 
	'wordlift.editpost.widget.services.AnalysisService', 
	'wordlift.editpost.widget.services.EditorService', 
	'wordlift.editpost.widget.services.ImageSuggestorDataRetrieverService' 		
	
	])

.config((configurationProvider)->
  configurationProvider.setConfiguration window.wordlift
)

$(
  container = $("""
  	<div ng-show="analysis" id="wordlift-edit-post-wrapper" ng-controller="EditPostWidgetController">
  		<div ng-click="createTextAnnotationFromCurrentSelection()" id="wl-add-entity-button-wrapper">
        <span class="preview button" ng-class="{ 'selected' : !isSelectionCollapsed }">Add entity</span>
        <div class="clear" />     
      </div>
      
      <div ng-show="annotation">
        <h4 class="wl-annotation-label">
          <i class="wl-annotation-label-icon"></i>
          {{ analysis.annotations[ annotation ].text }} 
          <small>[ {{ analysis.annotations[ annotation ].start }}, {{ analysis.annotations[ annotation ].end }} ]</small>
          <i class="wl-annotation-label-remove-icon" ng-click="selectAnnotation(undefined)"></i>
        </h4>
        <wl-entity-form entity="newEntity" on-submit="addNewEntityToAnalysis()" ng-show="analysis.annotations[annotation].entityMatches.length == 0"></wl-entity-form>
      </div>

      <wl-classification-box ng-repeat="box in configuration.classificationBoxes">
        <div ng-hide="annotation" class="wl-without-annotation">
          <wl-entity-tile is-selected="isEntitySelected(entity, box)" on-entity-select="onSelectedEntityTile(entity, box)" entity="entity" ng-repeat="entity in analysis.entities | filterEntitiesByTypesAndRelevance:box.registeredTypes"></wl-entity>
        </div>  
        <div ng-show="annotation" class="wl-with-annotation">
          <wl-entity-tile is-selected="isLinkedToCurrentAnnotation(entity)" on-entity-select="onSelectedEntityTile(entity, box)" entity="entity" ng-repeat="entity in analysis.annotations[annotation].entities | filterEntitiesByTypes:box.registeredTypes"" ></wl-entity>
        </div>  
      </wl-classification-box>
      <div wl-carousel>
        <div ng-repeat="entity in analysis.entities | isEntitySelected" class="wl-card" wl-carousel-pane>
          <img ng-src="{{entity.images[0]}}" />
        </div>
      </div>
      
      <div class="wl-entity-input-boxes">
        <wl-entity-input-box annotation="annotation" entity="entity" ng-repeat="entity in analysis.entities | isEntitySelected"></wl-entity-input-box>
        <div ng-repeat="(box, entities) in selectedEntities">
          <input type='text' name='wl_boxes[{{box}}][]' value='{{id}}' ng-repeat="(id, entity) in entities">
        </div> 
      </div>   
    </div>
  """)
  .appendTo('#wordlift-edit-post-outer-wrapper')

injector = angular.bootstrap $('#wordlift-edit-post-wrapper'), ['wordlift.editpost.widget']

# Add WordLift as a plugin of the TinyMCE editor.
  tinymce.PluginManager.add 'wordlift', (editor, url) ->
    # Perform analysis once tinymce is loaded
    editor.onLoadContent.add((ed, o) ->
      injector.invoke(['AnalysisService', '$rootScope',
       (AnalysisService, $rootScope) ->
        # execute the following commands in the angular js context.
        $rootScope.$apply(->    
          # Get the html content of the editor.
          html = editor.getContent format: 'raw'

          # Get the text content from the Html.
          text = Traslator.create(html).getText()
          AnalysisService.perform text
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
