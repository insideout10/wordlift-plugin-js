$ = jQuery

# Add a timeline plugin object to jQuery
$.fn.extend

  timeline: (options) ->
    # Default settings
    settings = {}

    # Merge default settings with options.
    settings = $.extend settings, options
    
    # Create a reference to dom wrapper element
    container = $(@)

    # Initialization method
    init = ->
      # Get data via AJAX
      $.post settings.ajax_url, { action: settings.action, post_id: settings.postId }, (data) ->
        if data.timeline?
          createStoryJS
            type: 'timeline'
            width: '100%'
            height: '600'
            source: data
            embed_id: settings.elemId  # ID of the DIV you want to load the timeline into
            start_at_slide: data.startAtSlide 
        else
          container.hide()
          console.log 'Timeline not built.'


    init()

jQuery ($) ->
  $('.wl-timeline').each ->
    # Get local params.
    params = $(this).data()
    elemId = $(this).attr('id')
    params.elemId = elemId

    # Merge local and global params.
    $.extend params, wl_timeline_params

    $(this).timeline params