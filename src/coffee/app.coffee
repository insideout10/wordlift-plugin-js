# Set the well-known $ reference to jQuery.
$ = jQuery

# Create the main AngularJS module, and set it dependent on controllers and directives.
angular.module('wordlift.tinymce.plugin', ['wordlift.tinymce.plugin.controllers', 'wordlift.tinymce.plugin.directives'])

# Create the HTML fragment for the disambiguation popover that shows when a user clicks on a text annotation.
$(
  container = $('''
    <div id="wl-app" class="wl-app">
      <div id="wl-error-controller" class="wl-error-controller" ng-controller="ErrorController">
        <p ng-bind="message"></p>
      </div>
      <div id="wordlift-disambiguation-popover" class="metabox-holder" ng-controller="EntitiesController">
        <div class="postbox">
          <div class="handlediv" title="Click to toggle"><br></div>
          <h3 class="hndle"><span>Semantic Web</span></h3>
          <div class="inside">
            <form role="form">
              <div class="form-group">
                <div class="ui-widget">
                  <input type="text" class="form-control" id="search" placeholder="search or create">
                </div>
              </div>

              <wl-entities on-select="onEntitySelected(textAnnotation, entityAnnotation)" text-annotation="textAnnotation"></wl-entities>

            </form>

            <wl-entity-input-boxes text-annotations="analysis.textAnnotations"></wl-entity-input-boxes>
          </div>
        </div>
      </div>
    </div>
    ''')
  .appendTo('form[name=post]')

  $('#wordlift-disambiguation-popover')
  .css(
      display: 'none'
      height: $('body').height() - $('#wpadminbar').height() + 32
      top: $('#wpadminbar').height() - 1
      right: 0
    )
  .draggable()

  $('#search').autocomplete
    source: ajaxurl + '?action=wordlift_search',
    minLength: 2,
    select: (event, ui) ->
      console.log event
      console.log ui
  .data("ui-autocomplete")._renderItem = (ul, item) ->
    console.log ul
    $("<li>")
    .append("""
        <li>
          <div class="entity #{item.types}">
            <!-- div class="thumbnail" style="background-image: url('')"></div -->
            <div class="thumbnail empty"></div>
            <div class="confidence"></div>
            <div class="label">#{item.label}</div>
            <div class="type"></div>
            <div class="source"></div>
          </div>
        </li>
    """)
    .appendTo(ul)

  # When the user clicks on the handle, hide the popover.
  $('#wordlift-disambiguation-popover .handlediv').click (e) ->
    $('#wordlift-disambiguation-popover').hide()

  # Declare the whole document as bootstrap scope.
  injector = angular.bootstrap $('#wl-app'), ['wordlift.tinymce.plugin']

  # Add WordLift as a plugin of the TinyMCE editor.
  tinymce.PluginManager.add 'wordlift', (editor, url) ->

    # Add a WordLift button the TinyMCE editor.
    editor.addButton 'wordlift',
      text: 'WordLift'
      icon: false
    # When the editor is clicked, the [EditorService.analyze](app.services.EditorService.html#analyze) method is invoked.
      onclick: ->
        injector.invoke(['EditorService', '$rootScope', (EditorService, $rootScope) ->
          $rootScope.$apply( ->
            html = tinyMCE.activeEditor.getContent({format: 'raw'})
            console.log html
            text = tinyMCE.activeEditor.getContent({format: 'text'})
            console.log text
            text = Traslator.create(html).getText()
            console.log text
            EditorService.analyze text
          )
        ])

)


