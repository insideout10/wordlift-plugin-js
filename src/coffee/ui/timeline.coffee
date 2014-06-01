jQuery ($) ->
  $('.wl-timeline').each ->

    # Get local params.
    params = $(this).data()
    elemId = $(this).attr('id')

    # Merge local and global params.
    $.extend params, wl_timeline_params

    # Get data via AJAX
    $.post params.ajax_url, { action: params.action, post_id: params.postId }, (data) ->

      if data.timeline?
        createStoryJS
          type: 'timeline'
          width: '100%'
          height: '600'
          source: data
          embed_id: elemId  # ID of the DIV you want to load the timeline into
          start_at_slide: data.startAtSlide

      else
        $( "##{elemId}" ).html('No data for the timeline.')
          .height '30px'
          .css 'background-color', 'red'
